from fastapi import FastAPI, UploadFile, File, Form
import whisper
import tempfile
import subprocess
import os
import re

app = FastAPI()

# 🔥 โหลด model ครั้งเดียว
model = whisper.load_model("base")

def clean_text(text):
    text = text.lower()
    text = re.sub(r'[^\w\s]', '', text)
    return text.strip()

@app.post("/evaluate")
async def evaluate(
    file: UploadFile = File(...),
    text: str = Form(...)
):
    tmp_audio_path = None
    normalized_path = None

    try:
        # Save uploaded file
        with tempfile.NamedTemporaryFile(delete=False, suffix=".wav") as tmp_audio:
            tmp_audio.write(await file.read())
            tmp_audio_path = tmp_audio.name

        # Normalize with ffmpeg - ใช้ mkstemp เพื่อปิด file handle ทันที
        fd, normalized_path = tempfile.mkstemp(suffix=".wav")
        os.close(fd)

        subprocess.run(
            [
                "ffmpeg",
                "-y",
                "-i", tmp_audio_path,
                "-ac", "1",
                "-ar", "16000",
                normalized_path
            ],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=True
        )

        # Transcribe
        result = model.transcribe(
            normalized_path,
            language="en",
            fp16=False
        )

        recognized_text_raw = result["text"]

        # Accuracy calculation
        recognized_text = clean_text(recognized_text_raw)
        cleaned_expected = clean_text(text)

        expected_words = cleaned_expected.split()
        recognized_words = recognized_text.split()

        expected_counts = {}
        for w in expected_words:
            expected_counts[w] = expected_counts.get(w, 0) + 1

        match_count = 0
        for w in recognized_words:
            if w in expected_counts and expected_counts[w] > 0:
                match_count += 1
                expected_counts[w] -= 1

        accuracy = 100 if not expected_words else min(
            int(match_count / len(expected_words) * 100),
            100
        )

        return {
            "text": recognized_text_raw,
            "score": accuracy
        }

    except Exception as e:
        return {"error": str(e)}

    finally:
        for p in (tmp_audio_path, normalized_path):
            if p and os.path.exists(p):
                try:
                    os.unlink(p)
                except OSError:
                    pass
