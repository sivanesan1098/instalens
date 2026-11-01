"""
InstaLens — Instagram Video Summarizer & Link Extractor (FastAPI Backend)
Extracts video metadata & caption via yt-dlp, transcribes audio with faster-whisper,
scans video frames for on-screen URLs via OpenCV + pytesseract OCR, and separates
Video Links (on-screen + spoken) from Caption Links (post description + bio).
"""
import os
import re
import tempfile
import asyncio
import json
from typing import List, Optional, Dict, Any
from dataclasses import dataclass, asdict
from datetime import datetime

from fastapi import FastAPI, HTTPException, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

try:
    import cv2
    HAS_CV2 = True
except ImportError:
    HAS_CV2 = False

try:
    import yt_dlp
    HAS_YTDLP = True
except ImportError:
    HAS_YTDLP = False

try:
    import pytesseract
    HAS_OCR = True
except ImportError:
    HAS_OCR = False

try:
    from faster_whisper import WhisperModel
    HAS_WHISPER = True
except ImportError:
    HAS_WHISPER = False

# yt-dlp marks InstagramUserIE as _WORKING = False because it requires
# browser impersonation that isn't available in all environments. We
# override it so the profile endpoint can attempt extraction even when
# the extractor is flagged as non-working.
if HAS_YTDLP:
    try:
        from yt_dlp.extractor.instagram import InstagramUserIE, InstagramTagIE
        InstagramUserIE._WORKING = True
        InstagramTagIE._WORKING = True
    except ImportError:
        pass


@dataclass
class ProgressEvent:
    """Progress event for real-time updates."""
    stage: str
    step: int
    total_steps: int
    message: str
    timestamp: str
    data: Optional[Dict[str, Any]] = None

    def to_json(self) -> str:
        return json.dumps(asdict(self))


class ConnectionManager:
    """Manages WebSocket connections for progress updates."""
    def __init__(self):
        self.active_connections: Dict[str, WebSocket] = {}

    async def connect(self, client_id: str, websocket: WebSocket):
        await websocket.accept()
        self.active_connections[client_id] = websocket

    def disconnect(self, client_id: str):
        self.active_connections.pop(client_id, None)

    async def send_progress(self, client_id: str, event: ProgressEvent):
        if client_id in self.active_connections:
            try:
                await self.active_connections[client_id].send_text(event.to_json())
            except Exception:
                self.disconnect(client_id)

    async def broadcast(self, event: ProgressEvent):
        for client_id, ws in list(self.active_connections.items()):
            try:
                await ws.send_text(event.to_json())
            except Exception:
                self.disconnect(client_id)


manager = ConnectionManager()


_whisper_model = None


def _get_whisper_model():
    """Lazy singleton — loading the ~150MB base model on every request is wasteful."""
    global _whisper_model
    if _whisper_model is None:
        _whisper_model = WhisperModel("base", device="cpu", compute_type="int8")
    return _whisper_model

app = FastAPI(title="InstaLens Video Summarizer & Link Extractor API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Serve the single-page frontend at the root so the app is deployable as a
# standalone web app (e.g. on Render / Fly / a container) without a separate
# reverse proxy. Static files are served from the project directory.
STATIC_DIR = os.path.dirname(os.path.abspath(__file__))
app.mount("/static", StaticFiles(directory=STATIC_DIR), name="static")


@app.get("/")
async def root():
    return FileResponse(os.path.join(STATIC_DIR, "index.html"))


@app.get("/health")
async def health():
    """Readiness check. Reports which pipeline components are importable so a
    deploy platform (or the frontend) can tell a missing dep from a down server."""
    return {
        "status": "ok",
        "components": {
            "yt_dlp": HAS_YTDLP,
            "opencv": HAS_CV2,
            "tesseract": HAS_OCR,
            "whisper": HAS_WHISPER,
        },
    }


@app.websocket("/ws/progress/{client_id}")
async def websocket_progress(websocket: WebSocket, client_id: str):
    """WebSocket endpoint for real-time progress updates during extraction."""
    await manager.connect(client_id, websocket)
    try:
        while True:
            # Keep connection alive, wait for client messages (ping/pong)
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(client_id)
    except Exception:
        manager.disconnect(client_id)

URL_REGEX = re.compile(
    r'(?<!@)(?:https?://|www\.)[^\s<>"{}|\\^`\[\]]+|'
    r'(?<!@)\b(?:[a-zA-Z0-9-]+\.)+(?:com|io|ai|dev|org|net|co|app|me|ly|gg|sh|xyz|ee|tv|so|link|notion|substack|gumroad|patreon|etsy|shopify|spotify|soundcloud|bandcamp|vimeo|dailymotion|loom|streamable|clips|cdn|store)(?:/[^\s<>"{}|\\^`\[\]]*)?\b',
    re.IGNORECASE
)

# At least 1 frame every 0.5s for reliable on-screen text detection; a 10-min reel
# at 0.5fps is 300 frames, so 60 frames gives ~2 minutes of coverage.
MAX_OCR_FRAMES = 60

class ExtractRequest(BaseModel):
    url: str
    caption_override: Optional[str] = None
    sample_fps: float = 0.5
    cookies_from_browser: Optional[str] = None  # "chrome" | "firefox" | "safari" | "edge" | "brave" | "opera"

class ExtractedLink(BaseModel):
    url: str
    normalized_url: str
    source: str  # "video_ocr" | "caption" | "transcript"
    timestamp: Optional[str] = None
    context: Optional[str] = None

class ExtractResponse(BaseModel):
    reel_url: str
    shortcode: str
    author: str
    title: str
    duration_seconds: float
    caption: str
    transcript: str
    ocr_snippets: List[dict]
    summary_tldr: str
    key_points: List[str]
    video_links: List[ExtractedLink]
    caption_links: List[ExtractedLink]

class PostItem(BaseModel):
    """A single post within a profile/stack extraction."""
    shortcode: str
    url: str
    author: str
    title: str
    caption: str
    is_video: bool
    duration_seconds: float
    thumbnail: str
    caption_links: List[ExtractedLink]

class ExtractPostResponse(BaseModel):
    """Response for a single image/carousel post (no video)."""
    post_url: str
    shortcode: str
    author: str
    title: str
    caption: str
    thumbnail: str
    is_video: bool
    duration_seconds: float
    summary_tldr: str
    key_points: List[str]
    caption_links: List[ExtractedLink]
    image_count: int

class ExtractProfileResponse(BaseModel):
    """Response for a profile/stack of posts."""
    profile_url: str
    profile_name: str
    profile_bio: str
    post_count: int
    posts: List[PostItem]
    summary_tldr: str
    all_caption_links: List[ExtractedLink]

def normalize_for_dedup(url: str) -> str:
    """Canonical form for deduplication: lowercase, strip trailing slash/punct,
    and drop a leading `www.` so https://x.com and https://www.x.com/ match.
    Caller is responsible for prepending a scheme (see extract_urls_from_text)."""
    u = url.lower().rstrip("/.,;:!?)")
    scheme = ""
    if u.startswith("https://"):
        scheme = "https://"
        u = u[8:]
    elif u.startswith("http://"):
        scheme = "http://"
        u = u[7:]
    if u.startswith("www."):
        u = u[4:]
    return scheme + u


def extract_urls_from_text(text: str, source: str, timestamp: Optional[str] = None) -> List[ExtractedLink]:
    if not text:
        return []
    found = []
    seen = set()
    for match in URL_REGEX.finditer(text):
        raw = match.group(0).rstrip('.,;:!?)')
        norm = raw if raw.lower().startswith(('http://', 'https://')) else f"https://{raw}"
        key = normalize_for_dedup(norm)
        if key not in seen:
            seen.add(key)
            found.append(ExtractedLink(
                url=raw,
                normalized_url=norm,
                source=source,
                timestamp=timestamp,
                context=text[:140].strip()
            ))
    return found

def format_ts(seconds: float) -> str:
    m = int(seconds // 60)
    s = int(seconds % 60)
    return f"{m}:{s:02d}"


def _fetch_info(url: str, cookies_from_browser: Optional[str] = None, skip_download: bool = True) -> dict:
    """Fetch Instagram metadata via yt-dlp without downloading video."""
    ydl_opts = {
        "quiet": True,
        "no_warnings": True,
        "skip_download": skip_download,
        "extract_flat": skip_download,
    }
    if cookies_from_browser:
        ydl_opts["cookies_from_browser"] = cookies_from_browser
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        return ydl.extract_info(url, download=False)


def _build_post_item(info: dict) -> PostItem:
    """Build a PostItem from yt-dlp info dict."""
    shortcode = info.get("id") or info.get("display_id") or "unknown"
    author = info.get("channel") or info.get("uploader") or "@instagram_creator"
    title = info.get("title") or f"Post by {author}"
    caption = info.get("description") or ""
    is_video = bool(info.get("formats"))
    duration = float(info.get("video_duration") or info.get("duration") or 0.0)
    thumbnail = info.get("thumbnail") or ""
    caption_links = extract_urls_from_text(caption, source="caption")
    return PostItem(
        shortcode=shortcode,
        url=info.get("webpage_url") or f"https://instagram.com/p/{shortcode}/",
        author=author,
        title=title,
        caption=caption,
        is_video=is_video,
        duration_seconds=duration,
        thumbnail=thumbnail,
        caption_links=caption_links,
    )


async def _extract_with_progress(req: ExtractRequest, shortcode: str, client_id: str) -> ExtractResponse:
    """Extract with progress updates sent via WebSocket."""
    total_steps = 8
    current_step = 0
    
    def send_progress(stage: str, step: int, message: str, data: dict = None):
        event = ProgressEvent(
            stage=stage,
            step=step,
            total_steps=total_steps,
            message=message,
            timestamp=datetime.now().isoformat(),
            data=data
        )
        asyncio.create_task(manager.send_progress(client_id, event))
    
    send_progress("init", 0, "Starting extraction...", {"shortcode": shortcode})
    
    with tempfile.TemporaryDirectory() as tmpdir:
        video_path = os.path.join(tmpdir, "video.mp4")
        ydl_opts = {
            "outtmpl": video_path,
            "format": "best[ext=mp4]/best",
            "quiet": True,
            "no_warnings": True,
        }
        if req.cookies_from_browser:
            ydl_opts["cookies_from_browser"] = req.cookies_from_browser
        
        # Step 1: Download video
        current_step += 1
        send_progress("download", current_step, "Downloading video from Instagram...", {"url": req.url})
        try:
            with yt_dlp.YoutubeDL(ydl_opts) as ydl:
                info = ydl.extract_info(req.url, download=True)
        except Exception as e:
            detail = str(e)
            if "login" in detail.lower() or "locked" in detail.lower() or "empty media response" in detail.lower():
                raise HTTPException(status_code=400, detail=(
                    "Instagram requires authentication for this post. "
                    "Pass 'cookies_from_browser': 'chrome' (or 'firefox') in your request body."
                ))
            elif "no video" in detail.lower():
                raise HTTPException(status_code=400, detail=(
                    "This post does not contain a video. It may be a photo carousel."
                ))
            else:
                raise HTTPException(status_code=400, detail=f"Failed to fetch Instagram video: {e}")
        
        send_progress("metadata", current_step, "Video downloaded, extracting metadata...", {"file_size": os.path.getsize(video_path) if os.path.exists(video_path) else 0})

        caption = req.caption_override or info.get("description") or ""
        author = info.get("channel") or info.get("uploader") or "@instagram_creator"
        title = info.get("title") or f"Instagram Reel ({shortcode})"
        duration = float(info.get("video_duration") or info.get("duration") or 0.0)

        # Step 2: Extract caption links
        current_step += 1
        send_progress("caption_links", current_step, "Extracting links from caption...", {})
        caption_links = extract_urls_from_text(caption, source="caption")
        
        # Step 3: OCR frames
        current_step += 1
        ocr_snippets = []
        video_links_by_key = {}
        
        if os.path.exists(video_path) and HAS_OCR:
            send_progress("ocr", current_step, "Scanning video frames for on-screen text...", {})
            cap = cv2.VideoCapture(video_path)
            fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
            step = max(1, int(fps / max(req.sample_fps, 0.5)))
            frame_idx = 0
            scanned = 0
            total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
            estimated_frames = min(MAX_OCR_FRAMES, total_frames // step)
            
            while cap.isOpened() and scanned < MAX_OCR_FRAMES:
                ret, frame = cap.read()
                if not ret:
                    break
                if frame_idx % step == 0:
                    scanned += 1
                    sec = frame_idx / fps
                    ts_str = format_ts(sec)
                    gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
                    # Preprocess for better OCR: denoise + adaptive threshold
                    gray = cv2.GaussianBlur(gray, (3, 3), 0)
                    gray = cv2.adaptiveThreshold(
                        gray, 255, cv2.ADAPTIVE_THRESH_GAUSSIAN_C,
                        cv2.THRESH_BINARY, 11, 2
                    )
                    text = pytesseract.image_to_string(gray).strip()
                    if text:
                        ocr_snippets.append({"timestamp": ts_str, "text": text})
                        for lk in extract_urls_from_text(text, source="video_ocr", timestamp=ts_str):
                            key = normalize_for_dedup(lk.normalized_url)
                            if key not in video_links_by_key:
                                video_links_by_key[key] = lk
                    
                    # Send progress every few frames
                    if scanned % 3 == 0 or scanned == estimated_frames:
                        send_progress("ocr", current_step, 
                            f"OCR frame {scanned}/{estimated_frames} at {ts_str}...",
                            {"frames_scanned": scanned, "total_estimated": estimated_frames, "current_timestamp": ts_str})
                frame_idx += 1
            cap.release()
        
        # Step 4: Transcribe audio
        current_step += 1
        transcript_parts = []
        whisper_ok = False
        whisper_error = None
        
        if os.path.exists(video_path) and HAS_WHISPER:
            send_progress("transcribe", current_step, "Loading Whisper model...", {})
            try:
                model = _get_whisper_model()
                send_progress("transcribe", current_step, "Transcribing audio...", {})
                segments, info = model.transcribe(video_path)
                whisper_ok = bool(info)
                for seg in segments:
                    ts_str = format_ts(seg.start)
                    transcript_parts.append(f"[{ts_str}] {seg.text.strip()}")
                    for lk in extract_urls_from_text(seg.text, source="transcript", timestamp=ts_str):
                        key = normalize_for_dedup(lk.normalized_url)
                        if key not in video_links_by_key:
                            video_links_by_key[key] = lk
            except Exception as e:
                whisper_error = f"{type(e).__name__}: {e}"
                whisper_ok = False
        
        video_links = list(video_links_by_key.values())
        transcript = "\n".join(transcript_parts) if transcript_parts else (
            f"(No spoken audio detected)" if whisper_ok else (
                f"(Transcription failed: {whisper_error})" if whisper_error else
                "(Transcription unavailable: faster-whisper not installed)"
            )
        )
        
        # Step 5: Generate summary
        current_step += 1
        send_progress("summary", current_step, "Generating summary...", {})
        
        combined_text = f"Caption: {caption}\nTranscript: {transcript}\nOn-Screen OCR: " + " | ".join(
            f"[{s['timestamp']}] {s['text']}" for s in ocr_snippets
        )
        lines = [ln.strip() for ln in (caption.splitlines() + transcript_parts) if ln.strip()]
        summary_tldr = (
            f"Video by {author} covering {title}. "
            f"Detected {len(video_links)} link(s) inside the video and {len(caption_links)} link(s) in the caption."
        )
        key_points = lines[:5] if lines else ["Extracted metadata and scanned frames for links."]
        
        # Step 6: Finalize
        current_step += 1
        send_progress("complete", current_step, "Extraction complete!", {
            "video_links": len(video_links),
            "caption_links": len(caption_links),
            "ocr_frames": len(ocr_snippets),
            "transcript_length": len(transcript),
        })
        
        return ExtractResponse(
            reel_url=req.url,
            shortcode=shortcode,
            author=author,
            title=title,
            duration_seconds=duration,
            caption=caption,
            transcript=transcript,
            ocr_snippets=ocr_snippets,
            summary_tldr=summary_tldr,
            key_points=key_points,
            video_links=video_links,
            caption_links=caption_links,
        )


@app.post("/api/extract", response_model=ExtractResponse)
async def process_instagram_video(req: ExtractRequest):
    shortcode_match = re.search(r'instagram\.com/(?:reel|reels|p|tv)/([^/?#]+)', req.url, re.IGNORECASE)
    shortcode = shortcode_match.group(1) if shortcode_match else "unknown"

    try:
        # For backward compatibility, run without progress if no client_id
        return await _extract_with_progress(req, shortcode, client_id="default")
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        raise HTTPException(
            status_code=500,
            detail=f"Extraction failed: {type(e).__name__}: {e}\n{traceback.format_exc()[-400:]}",
        )


@app.post("/api/extract/post", response_model=ExtractPostResponse)
def process_instagram_post(req: ExtractRequest):
    """Extract metadata & links from a single Instagram post (image, carousel, or video).

    Unlike /api/extract, this endpoint does NOT download the video or run OCR/whisper.
    It returns the caption, thumbnail, and caption links — useful for image posts and
    carousels where there is no video to transcribe.
    """
    shortcode_match = re.search(r'instagram\.com/(?:reel|reels|p|tv)/([^/?#]+)', req.url, re.IGNORECASE)
    shortcode = shortcode_match.group(1) if shortcode_match else "unknown"

    try:
        info = _fetch_info(req.url, cookies_from_browser=req.cookies_from_browser)
    except Exception as e:
        detail = str(e)
        if "login" in detail.lower() or "locked" in detail.lower() or "empty media response" in detail.lower():
            raise HTTPException(status_code=400, detail=(
                "Instagram requires authentication for this post. "
                "Pass 'cookies_from_browser': 'chrome' (or 'firefox') in your request body."
            ))
        raise HTTPException(status_code=400, detail=f"Failed to fetch Instagram post: {e}")

    caption = req.caption_override or info.get("description") or ""
    author = info.get("channel") or info.get("uploader") or "@instagram_creator"
    title = info.get("title") or f"Post by {author}"
    is_video = bool(info.get("formats"))
    duration = float(info.get("video_duration") or info.get("duration") or 0.0)
    thumbnail = info.get("thumbnail") or ""
    caption_links = extract_urls_from_text(caption, source="caption")

    # Count carousel images
    image_count = 1
    if info.get("_type") == "playlist" and info.get("entries"):
        image_count = len(info["entries"])

    lines = [ln.strip() for ln in caption.splitlines() if ln.strip()]
    summary_tldr = (
        f"Post by {author} ({'video' if is_video else 'image carousel' if image_count > 1 else 'image'}). "
        f"Detected {len(caption_links)} link(s) in the caption."
    )
    key_points = lines[:5] if lines else ["Extracted post metadata and caption links."]

    return ExtractPostResponse(
        post_url=req.url,
        shortcode=shortcode,
        author=author,
        title=title,
        caption=caption,
        thumbnail=thumbnail,
        is_video=is_video,
        duration_seconds=duration,
        summary_tldr=summary_tldr,
        key_points=key_points,
        caption_links=caption_links,
        image_count=image_count,
    )


@app.post("/api/extract/profile", response_model=ExtractProfileResponse)
def process_instagram_profile(req: ExtractRequest):
    """Extract a stack of posts from an Instagram profile, hashtag, or collection URL.

    Returns the profile bio, a list of posts (each with caption, thumbnail, and links),
    and a combined set of all caption links found across the stack.

    Supported URL types:
    - Profile: https://www.instagram.com/<username>/
    - Hashtag: https://www.instagram.com/explore/tags/<hashtag>/
    - Collection: https://www.instagram.com/<username>/collection/

    NOTE: yt-dlp's InstagramUserIE extractor requires browser impersonation
    that may not be available in all environments. Pass cookies_from_browser
    (e.g. 'chrome') for best results. If extraction fails, the endpoint returns
    a clear error message.
    """
    try:
        info = _fetch_info(req.url, cookies_from_browser=req.cookies_from_browser)
    except Exception as e:
        detail = str(e)
        if "Unable to extract data" in detail:
            raise HTTPException(status_code=400, detail=(
                "Profile extraction requires browser impersonation which is not available. "
                "Try passing 'cookies_from_browser': 'chrome' (or 'firefox') in your request body. "
                "Alternatively, extract individual posts using the Single Post mode."
            ))
        if "login" in detail.lower() or "locked" in detail.lower() or "empty media response" in detail.lower():
            raise HTTPException(status_code=400, detail=(
                "Instagram requires authentication for this profile. "
                "Pass 'cookies_from_browser': 'chrome' (or 'firefox') in your request body."
            ))
        raise HTTPException(status_code=400, detail=f"Failed to fetch Instagram profile: {e}")

    # Extract profile metadata
    profile_name = info.get("channel") or info.get("uploader") or info.get("id") or "unknown"
    profile_bio = info.get("description") or ""

    # Extract posts from playlist entries
    posts = []
    all_caption_links = []
    seen_keys = set()

    entries = info.get("entries") or []
    for entry in entries:
        post_item = _build_post_item(entry)
        posts.append(post_item)
        for link in post_item.caption_links:
            key = normalize_for_dedup(link.normalized_url)
            if key not in seen_keys:
                seen_keys.add(key)
                all_caption_links.append(link)

    # If no playlist entries, treat as a single post
    if not posts:
        post_item = _build_post_item(info)
        posts.append(post_item)
        for link in post_item.caption_links:
            key = normalize_for_dedup(link.normalized_url)
            if key not in seen_keys:
                seen_keys.add(key)
                all_caption_links.append(link)

    summary_tldr = (
        f"Profile @{profile_name}: {len(posts)} post(s) extracted. "
        f"Found {len(all_caption_links)} unique link(s) across all captions."
    )

    return ExtractProfileResponse(
        profile_url=req.url,
        profile_name=profile_name,
        profile_bio=profile_bio,
        post_count=len(posts),
        posts=posts,
        summary_tldr=summary_tldr,
        all_caption_links=all_caption_links,
    )


if __name__ == "__main__":
    # Self-check for the URL normalization/dedup logic — fails loudly if the
    # regex or canonicalization regresses (e.g. www.x.com vs x.com/ diverge).
    cases = [
        ("https://github.com/a/b", "https://github.com/a/b"),
        ("https://github.com/a/b/", "https://github.com/a/b"),
        ("https://www.example.com", "https://example.com"),
        ("https://x.com/path.", "https://x.com/path"),
    ]
    for raw, want in cases:
        got = normalize_for_dedup(raw)
        assert got == want, f"{raw!r}: expected {want!r}, got {got!r}"
    assert normalize_for_dedup("https://github.com/a/b") == normalize_for_dedup("https://www.github.com/a/b/")
    assert normalize_for_dedup("https://x.com") == normalize_for_dedup("https://www.x.com")
    # The regex must not match bare email-ish prose.
    assert not URL_REGEX.search("reach me at hello@example.com today")
    print("backend self-check OK")
