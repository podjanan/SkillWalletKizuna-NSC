import base64
import io
import os
from typing import Any

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from PIL import Image
from ultralytics import YOLO


MODEL_NAME = os.getenv("YOLO_MODEL", "yolo11n.pt")
CONFIDENCE = float(os.getenv("YOLO_CONFIDENCE", "0.25"))
MAX_OBJECTS = int(os.getenv("YOLO_MAX_OBJECTS", "10"))

ROOM_OBJECT_ALIASES = {
    "couch": "sofa",
    "dining table": "table",
    "potted plant": "plant",
    "tv": "television",
    "cell phone": "phone",
}

app = FastAPI(title="Skill Wallet YOLO Detector")
model: YOLO | None = None


class DetectRequest(BaseModel):
    image: str | None = None
    imageBase64: str | None = None


def get_model() -> YOLO:
    global model
    if model is None:
        model = YOLO(MODEL_NAME)
    return model


def decode_image(value: str) -> Image.Image:
    if "," in value and value.strip().lower().startswith("data:image"):
        value = value.split(",", 1)[1]

    try:
        raw = base64.b64decode(value, validate=False)
        image = Image.open(io.BytesIO(raw))
        return image.convert("RGB")
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f"Invalid base64 image: {exc}") from exc


def normalize_label(label: str) -> str:
    label = label.strip().lower()
    return ROOM_OBJECT_ALIASES.get(label, label)


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok", "model": MODEL_NAME}


@app.post("/detect")
def detect(payload: DetectRequest) -> dict[str, Any]:
    image_value = payload.image or payload.imageBase64
    if not image_value:
        raise HTTPException(status_code=400, detail="image or imageBase64 is required")

    image = decode_image(image_value)
    detector = get_model()
    results = detector.predict(image, conf=CONFIDENCE, verbose=False)

    detections: list[dict[str, Any]] = []
    for result in results:
        names = result.names
        for box in result.boxes:
            class_id = int(box.cls[0])
            confidence = float(box.conf[0])
            label = normalize_label(str(names[class_id]))
            xyxy = [float(value) for value in box.xyxy[0].tolist()]
            detections.append({
                "label": label,
                "confidence": round(confidence, 4),
                "box": xyxy,
            })

    detections.sort(key=lambda item: item["confidence"], reverse=True)

    objects: list[str] = []
    for item in detections:
        label = item["label"]
        if label not in objects:
            objects.append(label)
        if len(objects) >= MAX_OBJECTS:
            break

    return {
        "objects": objects,
        "detections": detections[:MAX_OBJECTS],
        "model": MODEL_NAME,
    }
