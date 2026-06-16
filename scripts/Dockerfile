FROM python:3.11-slim

# Install FFmpeg for audio normalization
RUN apt-get update && \
    apt-get install -y --no-install-recommends ffmpeg && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python dependencies (CPU-only torch to reduce image size)
COPY requirements.txt .
RUN pip install --no-cache-dir setuptools wheel && \
    pip install --no-cache-dir \
    torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu && \
    pip install --no-cache-dir --no-build-isolation -r requirements.txt

COPY whisper_eval.py .

EXPOSE 8000

# Health check — FastAPI docs endpoint
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/docs')" || exit 1

CMD ["uvicorn", "whisper_eval:app", "--host", "0.0.0.0", "--port", "8000"]
