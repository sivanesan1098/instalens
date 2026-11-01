# InstaLens — Instagram Video Summarizer & Link Extractor

A lightweight web application and FastAPI backend that takes an Instagram Reel/Video link, extracts the video stream, caption, audio transcript, and on-screen frame text (OCR), and **separately displays**:
1. **Links Shown in the Video** (detected via OpenCV + Tesseract frame OCR and spoken transcript) with timestamps.
2. **Links in the Caption** (extracted from the creator's post description and bio callouts).

The frontend and backend are served from a single process — the app is deployable as a standalone web app (container, Render, Fly, etc.).

## Quick Start

### 1. Install dependencies

```bash
pip install -r requirements.txt
# pytesseract also needs the tesseract binary (macOS):
brew install tesseract
```

### 2. Run the app

```bash
uvicorn backend:app --host 0.0.0.0 --port 8000
```

The frontend is served at `http://localhost:8000/` and the API at `http://localhost:8000/api/extract`. Open the root URL in a browser and paste an Instagram Reel link.

### 3. Deploy

The app is a single FastAPI process with no separate hosting requirements. The recommended path is a container:

```bash
docker build -t instalens .
docker run -p 8000:8000 instalens
```

See [Dockerfile](Dockerfile) for the base image and build steps. For a managed platform, point it at Render, Fly, or any PaaS that runs a container and exposes a port.

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `HOST` | `0.0.0.0` | Bind address |
| `PORT` | `8000` | Listen port |

## Notes

- yt-dlp can hit Instagram's login wall for some reels. Pass `cookies_from_browser` (e.g. `"chrome"`) through the API request body to use your browser's session cookies.
- OCR is capped at 30 frames per video (`MAX_OCR_FRAMES`) to keep long reels tractable.