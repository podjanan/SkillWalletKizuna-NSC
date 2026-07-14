import base64
import io
import os
import threading
from contextlib import asynccontextmanager
from typing import Any

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from PIL import Image
from ultralytics import YOLO
import easyocr
import numpy as np


MODEL_NAME = os.getenv("YOLO_MODEL", "yolov8s-worldv2.pt")
CONFIDENCE = float(os.getenv("YOLO_CONFIDENCE", "0.18"))
IMAGE_SIZE = int(os.getenv("YOLO_IMAGE_SIZE", "640"))
IOU_THRESHOLD = float(os.getenv("YOLO_IOU_THRESHOLD", "0.45"))
MAX_OBJECTS = int(os.getenv("YOLO_MAX_OBJECTS", "20"))
MAX_DETECTIONS = int(os.getenv("YOLO_MAX_DETECTIONS", "100"))

DEFAULT_ROOM_OBJECT_CLASSES = (
    "bed,pillow,blanket,plant,flowerpot,clock,lamp,picture frame,painting,"
    "curtain,wardrobe,cabinet,nightstand,table,desk,chair,sofa,television,"
    "window,door,mirror,rug,book,bottle,cup,backpack,handbag,vase,toy,fan,shelf,"
    "person,cat,dog,bird,horse,sheep,cow,elephant,bear,zebra,giraffe"
)
ROOM_OBJECT_CLASSES = [
    label.strip()
    for label in os.getenv("YOLO_CLASSES", DEFAULT_ROOM_OBJECT_CLASSES).split(",")
    if label.strip()
]

ROOM_OBJECT_ALIASES = {
    "couch": "sofa",
    "dining table": "table",
    "potted plant": "plant",
    "tv": "television",
    "cell phone": "phone",
    "flowerpot": "plant",
    "picture frame": "picture",
}

model: YOLO | None = None
model_lock = threading.Lock()
active_classes: tuple[str, ...] = ()
ocr_reader: Any = None
ocr_lock = threading.Lock()


class DetectRequest(BaseModel):
    image: str | None = None
    imageBase64: str | None = None
    classes: list[str] | None = None


def get_ocr_reader():
    global ocr_reader
    if ocr_reader is None:
        ocr_reader = easyocr.Reader(["en"], gpu=False, verbose=False)
    return ocr_reader


def get_model() -> YOLO:
    global model, active_classes
    if model is None:
        model = YOLO(MODEL_NAME)
        # YOLO-World can search for room-specific objects that are not part of
        # the 80 COCO classes used by a regular pretrained YOLO model.
        if "world" in MODEL_NAME.lower() and ROOM_OBJECT_CLASSES:
            model.set_classes(ROOM_OBJECT_CLASSES)
            active_classes = tuple(ROOM_OBJECT_CLASSES)
    return model


@asynccontextmanager
async def lifespan(_: FastAPI):
    # Load weights and text embeddings before the service reports ready. This
    # moves the expensive cold start out of the first administrator upload.
    get_model()
    get_ocr_reader()
    yield


app = FastAPI(title="Skill Wallet YOLO Detector", lifespan=lifespan)


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


@app.post("/recognize-numbers")
def recognize_numbers(payload: DetectRequest) -> dict[str, Any]:
    image_value = payload.image or payload.imageBase64
    if not image_value:
        raise HTTPException(status_code=400, detail="image or imageBase64 is required")

    image = decode_image(image_value)
    reader = get_ocr_reader()
    with ocr_lock:
        raw_results = reader.readtext(
            np.asarray(image),
            allowlist="0123456789.-/",
            detail=1,
            paragraph=False,
            canvas_size=1600,
            mag_ratio=1.0,
        )

    numbers = []
    for box, text, confidence in raw_results:
        normalized = "".join(char for char in str(text) if char in "0123456789.-/")
        if normalized:
            numbers.append({
                "text": normalized,
                "confidence": round(float(confidence), 4),
                "box": [[int(value) for value in point] for point in box],
            })
    return {"numbers": numbers, "engine": "easyocr-local"}


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
    requested_classes = tuple(dict.fromkeys(
        label.strip().lower() for label in (payload.classes or ROOM_OBJECT_CLASSES)
        if label.strip()
    ))

    # YOLO-World stores its active text vocabulary on the model. Serialize the
    # vocabulary switch and prediction so concurrent requests cannot mix packs.
    global active_classes
    with model_lock:
        if "world" in MODEL_NAME.lower() and requested_classes and requested_classes != active_classes:
            detector.set_classes(list(requested_classes))
            active_classes = requested_classes
        results = detector.predict(
            image,
            conf=CONFIDENCE,
            iou=IOU_THRESHOLD,
            imgsz=IMAGE_SIZE,
            max_det=MAX_DETECTIONS,
            verbose=False,
        )

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
