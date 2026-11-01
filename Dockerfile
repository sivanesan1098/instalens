FROM python:3.14-slim

# pytesseract needs the tesseract binary in the image as well as the Python wheel.
RUN apt-get update \
    && apt-get install -y --no-install-recommends tesseract-ocr \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

CMD ["sh", "-c", "exec uvicorn backend:app --host \"${HOST:-0.0.0.0}\" --port \"${PORT:-8000}\""]