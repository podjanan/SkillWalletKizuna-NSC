# Math Simulation local image pipeline

Math Simulation can create playable question images without any cloud image API.

## Runtime flow

1. The admin creates a question and equation.
2. `generate-math-images` extracts the two operands, operator, and object names.
3. If ComfyUI is available, it creates the storybook background.
4. Sharp overlays the exact number of objects, Thai question text, and equation.
5. The finished PNG is uploaded to MinIO and its URL is stored in the activity segment.
6. Flutter displays the image and lets the child type and check an answer directly.

When ComfyUI is unavailable, a deterministic local storybook background is used. Object counts remain exact in both modes.

## Optional ComfyUI setup

Run ComfyUI on the host at port `8188` and place an SDXL checkpoint in ComfyUI's checkpoint folder. The configured checkpoint filename must match the file exactly.

For local Next.js development:

```env
COMFYUI_URL=http://localhost:8188
COMFYUI_CHECKPOINT=sd_xl_base_1.0.safetensors
COMFYUI_TIMEOUT_MS=180000
```

Docker Compose automatically uses `http://host.docker.internal:8188` so the app container can reach ComfyUI running on Windows.

## Segment fields

Generated questions keep the existing fields and add:

- `imageUrl`: MinIO PNG URL used by Flutter
- `imageProvider`: `comfyui` or `local-svg`
- `visualPrompt`: background prompt or fallback description
- `visualData`: exact counts, operator, object types, and labels

Flutter rewrites localhost MinIO URLs to the configured API host, allowing the same activity data to work on web, Android emulators, and physical devices.
