FROM python:3.14-slim

# Install system deps (tesseract for OCR, ffmpeg for audio processing)
RUN apt-get update \
    && apt-get install -y --no-install-recommends tesseract-ocr ffmpeg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["sh", "-c", "exec uvicorn backend:app --host \"${HOST:-0.0.0.0}\" --port \"${PORT:-8000}\""]