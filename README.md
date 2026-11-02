# InstaLens — Instagram Video Summarizer & Link Extractor

A lightweight web application and FastAPI backend that takes an Instagram Reel/Video link, extracts the video stream, caption, audio transcript, and on-screen frame text (OCR), and **separately displays**:
1. **Links Shown in the Video** (detected via OpenCV + Tesseract frame OCR and spoken transcript) with timestamps.
2. **Links in the Caption** (extracted from the creator's post description and bio callouts).

The frontend and backend are served from a single process — the app is deployable as a standalone web app (container, Render, Fly, etc.).

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        Browser                               │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              Frontend (index.html)                   │    │
│  │  • 3 Extraction Modes: Reel / Post / Profile         │    │
│  │  • Real-time WebSocket progress tracking             │    │
│  │  • Tailwind CSS UI                                   │    │
│  └─────────────────────────────────────────────────────┘    │
└───────────────────────────┬─────────────────────────────────┘
                            │ HTTP / WebSocket
┌───────────────────────────▼─────────────────────────────────┐
│                  FastAPI Backend (backend.py)                │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              Connection Manager                      │    │
│  │  • WebSocket progress events                         │    │
│  │  • Client-specific progress tracking                 │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │              API Endpoints                           │    │
│  │  • POST /api/extract     - Reel/Video extraction     │    │
│  │  • POST /api/extract/post   - Single post            │    │
│  │  • POST /api/extract/profile - Profile/Stack         │    │
│  │  • GET  /ws/progress/{id}    - WebSocket progress    │    │
│  └─────────────────────────────────────────────────────┘    │
└───────────────────────────┬─────────────────────────────────┘
                            │
┌───────────────────────────▼─────────────────────────────────┐
│                    Pipeline Stages                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│  │  yt-dlp  │→ │   OCR    │→ │  Whisper │→ │  Summary │   │
│  │ Download │  │  Frames  │  │Transcribe│  │ Generate │   │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Tools & Components

### Backend Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `fastapi` | >=0.110.0 | Web framework |
| `uvicorn` | >=0.29.0 | ASGI server |
| `yt-dlp` | >=2024.4.9 | Instagram video downloading & metadata extraction |
| `opencv-python-headless` | >=4.9.0.80 | Video frame sampling for OCR |
| `pytesseract` | >=0.3.10 | Python wrapper for Tesseract OCR engine |
| `faster-whisper` | >=1.0.1 | Local speech transcription (CTranslate2) |
| `av` | >=18.0.0,<19 | FFmpeg bindings for audio processing |
| `pydantic` | >=2.7.0 | Data validation |
| `curl-cffi` | >=0.7.0 | Browser impersonation for Instagram API |

### External Services

| Service | Purpose |
|---------|---------|
| **Tesseract OCR** (system) | On-screen text recognition from video frames |
| **FFmpeg** (system) | Audio/video demuxing and processing |
| **Twitter/X (fallback)** | None - pure offline processing |

### Frontend Stack

| Technology | Purpose |
|------------|---------|
| Vanilla JavaScript | Core application logic |
| Tailwind CSS 3.4.17 | Styling via CDN |
| WebSockets | Real-time progress updates |
| Google Fonts (Inter) | Typography |

## Installation

### Prerequisites

Ensure you have the following system dependencies installed:

**macOS:**
```bash
brew install tesseract tesseract-lang ffmpeg
```

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y tesseract-ocr tesseract-ocr-all ffmpeg
```

**Docker (alternative):**
```bash
docker build -t instalens .
```

### Virtual Environment Setup

```bash
# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
```

## Running the App

### Development Mode

```bash
# From the project directory
source venv/bin/activate
uvicorn backend:app --host 0.0.0.0 --port 8000 --reload

# Open in browser
open http://localhost:8000
```

### Docker Deployment

```bash
# Build the container
docker build -t instalens .

# Run locally
docker run -p 8000:8000 instalens

# Run with environment variables
docker run -p 8000:8000 \
  -e HOST=0.0.0.0 \
  -e PORT=8000 \
  instalens
```

### LAN Access

To access from other devices on the same network:

1. Find your machine's IP:
   ```bash
   # macOS
   ipconfig getifaddr en0
   
   # Linux
   hostname -I
   ```

2. Access from another device:
   ```
   http://192.168.1.XXX:8000
   ```

3. Ensure firewall allows incoming connections on port 8000

## API Documentation

### Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/` | Serves the frontend UI |
| `GET` | `/health` | Health check (components status) |
| `GET` | `/docs` | Swagger UI (interactive API docs) |
| `POST` | `/api/extract` | Extract reel/video with full pipeline |
| `POST` | `/api/extract/post` | Extract single post (image/carousel) |
| `POST` | `/api/extract/profile` | Extract profile or hashtag stack |
| `WS` | `/ws/progress/{client_id}` | WebSocket for real-time progress |

### Request/Response Examples

**Extract Reel/Video:**
```bash
curl -X POST http://localhost:8000/api/extract \
  -H "Content-Type: application/json" \
  -d '{
    "url": "https://www.instagram.com/reel/ABC123/",
    "cookies_from_browser": "chrome"
  }'
```

**Response:**
```json
{
  "reel_url": "https://www.instagram.com/reel/ABC123/",
  "shortcode": "ABC123",
  "author": "@username",
  "title": "Video by username",
  "duration_seconds": 45.2,
  "caption": "Caption text here...",
  "transcript": "[0:00] First line...\n[0:05] Second line...",
  "ocr_snippets": [{"timestamp": "0:08", "text": "On-screen text..."}],
  "summary_tldr": "Video by @username covering...",
  "key_points": ["Point 1", "Point 2"],
  "video_links": [{"url": "https://example.com", "source": "video_ocr", "timestamp": "0:08"}],
  "caption_links": [{"url": "https://linktr.ee/user", "source": "caption"}]
}
```

**Extract Single Post:**
```bash
curl -X POST http://localhost:8000/api/extract/post \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.instagram.com/p/ABC123/"}'
```

**Extract Profile/Stack:**
```bash
curl -X POST http://localhost:8000/api/extract/profile \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.instagram.com/username/", "cookies_from_browser": "chrome"}'
```

## Extraction Modes

### Mode 1: Reel / Video (`/api/extract`)
Full pipeline extraction for Instagram reels and videos.

**Process:**
1. Download video via yt-dlp
2. Sample frames for OCR (up to 60 frames at 0.5fps minimum)
3. Transcribe audio with faster-whisper
4. Extract links from:
   - On-screen OCR text (with timestamps)
   - Spoken transcript (with timestamps)
   - Post caption
5. Generate summary and key points

**Output:** Separate panels for "Links in Video" (OCR + transcript) and "Links in Caption"

### Mode 2: Single Post (`/api/extract/post`)
Lightweight extraction for image posts, carousels, or when no video processing is needed.

**Process:**
1. Fetch metadata via yt-dlp (no video download)
2. Extract links from caption
3. Identify post type (image vs carousel vs video)

**Output:** Caption, thumbnail, link list, image count

### Mode 3: Profile / Stack (`/api/extract/profile`)
Extract multiple posts from a profile, hashtag, or collection.

**Process:**
1. Fetch profile metadata
2. Extract recent posts (up to 12 per batch)
3. Aggregate caption links across all posts
4. Remove duplicates

**Output:** Profile info, list of posts with individual links, combined unique links

## Progress Tracking

The app provides real-time progress updates via WebSocket for Reel/Video extraction.

### WebSocket Protocol

**Connection:**
```javascript
const ws = new WebSocket(`ws://${window.location.host}/ws/progress/{client_id}`);
```

**Progress Event Format:**
```json
{
  "stage": "ocr",
  "step": 5,
  "total_steps": 8,
  "message": "OCR frame 5/20 at 0:08...",
  "timestamp": "2026-11-01T12:00:00.000Z",
  "data": {
    "frames_scanned": 5,
    "total_estimated": 20,
    "current_timestamp": "0:08"
  }
}
```

### Progress Stages

| Stage | Step | Description |
|-------|------|-------------|
| `init` | 0/8 | Initializing extraction |
| `download` | 1/8 | Downloading video from Instagram |
| `metadata` | 2/8 | Extracting video metadata |
| `caption_links` | 3/8 | Parsing caption for URLs |
| `ocr` | 4/8 | Scanning frames (shows frame progress) |
| `transcribe` | 5/8 | Loading Whisper model + transcribing |
| `summary` | 6/8 | Generating summary & key points |
| `complete` | 7/8 | Finalizing results |

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `HOST` | `0.0.0.0` | Bind address |
| `PORT` | `8000` | Listen port |

### Application Settings (backend.py)

```python
MAX_OCR_FRAMES = 60        # Maximum frames to scan
sample_fps = 0.5           # Minimum frames per second for OCR
```

## Deployment Options

### Option 1: Render (Recommended - Free Tier)

1. Push code to GitHub
2. Connect repository at [dashboard.render.com](https://dashboard.render.com)
3. Create Web Service with:
   - **Runtime:** Docker
   - **Dockerfile:** `./Dockerfile`
   - **Branch:** `main`
4. Wait 3-5 minutes for build
5. App live at `https://your-app.onrender.com`

**Note:** Free tier spins down after 15 min inactivity. First request after spin-down takes ~30s cold start.

### Option 2: Railway

```bash
railway init
railway up
```

### Option 3: VPS with Docker

```bash
# On your server
docker build -t instalens .
docker run -d \
  --name instalens \
  --restart unless-stopped \
  -p 80:8000 \
  instalens

# Add nginx/Caddy for SSL
caddy reverse_proxy localhost:8000
```

### Option 4: Fly.io

```bash
flyctl launch --dockerfile Dockerfile
flyctl deploy
```

## Requirements & Limitations

### Hardware Requirements

| Component | Minimum | Recommended |
|-----------|---------|-------------|
| RAM | 2GB | 4GB+ |
| CPU | Dual-core | 4+ cores |
| Storage | 500MB | 1GB+ |

### Instagram Limitations

1. **Public posts only** without cookies (rate-limited)
2. **Private accounts** require `cookies_from_browser` parameter
3. **Regional restrictions** may block access from some locations
4. **Profile extraction** requires authentication for most accounts
5. **Video duration** may show `0.0` for some reels (Instagram metadata limitation)

### Workarounds

For private or restricted content:

```bash
# 1. Export cookies from Chrome/Firefox
# Install "Get cookies.txt LOCALLY" extension
# Export to cookies.json

# 2. Mount cookies in container
docker run -v ./cookies.json:/app/cookies.json instalens

# 3. Pass in API request
curl -X POST /api/extract \
  -d '{"url": "...", "cookies_from_browser": "chrome"}'
```

## Troubleshooting

### Common Issues

**"Instagram requires authentication"**
- The post is private or requires login
- Solution: Pass `cookies_from_browser: "chrome"` in request

**"Unable to extract data" for profiles**
- InstagramUserIE requires browser impersonation
- Solution: Use individual post URLs instead, or provide cookies

**"Transcription failed: IndexError"**
- Video has no audio stream
- Solution: Normal - transcript will show "(No spoken audio detected)"

**Slow extraction**
- Network latency or large video files
- Solution: Check progress panel for current stage

### Logs

View backend logs:
```bash
# Local
tail -f /var/log/syslog | grep uvicorn

# Docker
docker logs -f instalens

# Render
render service logs <service-name>
```

## Development

### Project Structure

```
insta_reel_extractor_app/
├── backend.py              # FastAPI backend with all endpoints
├── index.html              # Single-page frontend
├── requirements.txt        # Python dependencies
├── Dockerfile              # Container definition
├── README.md               # This file
└── .venv/                  # Virtual environment
```

### Adding New Features

1. Backend changes: Edit `backend.py`
2. Frontend changes: Edit `index.html`
3. Dependencies: Update `requirements.txt`
4. Commit and push to trigger auto-deploy

### Testing

```bash
# Run self-tests
python backend.py

# Test endpoints
curl http://localhost:8000/health
curl -X POST http://localhost:8000/api/extract/post \
  -H "Content-Type: application/json" \
  -d '{"url": "https://www.instagram.com/p/BQ0eAlwhDrw/"}'
```

## License

MIT License - feel free to use, modify, and distribute.

---

**Built with:** FastAPI, yt-dlp, OpenCV, Tesseract, faster-whisper, Tailwind CSS
