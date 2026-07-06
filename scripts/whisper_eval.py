from fastapi import FastAPI, UploadFile, File, Form
from typing import Optional
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

def count_syllables(word):
    word = word.lower()
    word = re.sub(r'[^a-z]', '', word)
    if not word:
        return 0
    if len(word) <= 3:
        return 1
    if word.endswith('e'):
        word = word[:-1]
    matches = re.findall(r'[aeiouy]+', word)
    return len(matches) if matches else 1

def get_first_n_syllables(text, n):
    words = text.split()
    result_words = []
    current_syllables = 0
    for w in words:
        if current_syllables >= n:
            break
        result_words.append(w)
        current_syllables += count_syllables(w)
    return " ".join(result_words)

def levenshtein_similarity(a, b):
    if len(a) < len(b):
        return levenshtein_similarity(b, a)
    if len(b) == 0:
        return 0 if len(a) > 0 else 100
    
    previous_row = range(len(b) + 1)
    for i, c1 in enumerate(a):
        current_row = [i + 1]
        for j, c2 in enumerate(b):
            insertions = previous_row[j + 1] + 1
            deletions = current_row[j] + 1
            substitutions = previous_row[j] + (c1 != c2)
            current_row.append(min(insertions, deletions, substitutions))
        previous_row = current_row
        
    distance = previous_row[-1]
    max_len = max(len(a), len(b))
    if max_len == 0:
        return 100
    return int((1 - distance / max_len) * 100)

@app.post("/evaluate")
async def evaluate(
    file: UploadFile = File(...),
    text: str = Form(...),
    language: Optional[str] = Form(None)
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
        transcribe_options = {"fp16": False}
        if language:
            transcribe_options["language"] = language
        if text:
            transcribe_options["initial_prompt"] = text
        result = model.transcribe(normalized_path, **transcribe_options)

        recognized_text_raw = result["text"]

        # Clean recognized text to English only if expected language is English
        if language == "en":
            recognized_text_raw = re.sub(r'[^a-zA-Z\s\'.,?-]', '', recognized_text_raw).strip()

        # Accuracy calculation
        cleaned_expected = clean_text(text)
        cleaned_recognized = clean_text(recognized_text_raw)

        if not cleaned_expected:
            accuracy = 100
        elif not cleaned_recognized:
            accuracy = 0
        else:
            is_single_word = " " not in cleaned_expected
            if is_single_word:
                expected_syllables = count_syllables(cleaned_expected)
                sliced_recognized = clean_text(get_first_n_syllables(recognized_text_raw, expected_syllables))
                if " " not in sliced_recognized and len(sliced_recognized) > 0:
                    accuracy = levenshtein_similarity(sliced_recognized, cleaned_expected)
                else:
                    accuracy = 100 if sliced_recognized == cleaned_expected else 0
            else:
                expected_words = cleaned_expected.split()
                recognized_words = cleaned_recognized.split()

                expected_counts = {}
                for w in expected_words:
                    expected_counts[w] = expected_counts.get(w, 0) + 1

                match_count = 0
                for w in recognized_words:
                    if w in expected_counts and expected_counts[w] > 0:
                        match_count += 1
                        expected_counts[w] -= 1

                accuracy = min(int(match_count / len(expected_words) * 100), 100)

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
