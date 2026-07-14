# Math Simulation local image pipeline

Math Simulation can create playable question images without any cloud image API.

## Runtime flow

1. The admin creates a question and equation.
2. `generate-math-images` extracts the two operands, operator, and object names.
3. The app creates a deterministic local storybook background.
4. Sharp overlays the exact number of objects and operator.
5. The finished PNG is uploaded to MinIO and its URL is stored in the activity segment.
6. Flutter displays the image and lets the child type and check an answer directly.

The pipeline is fully local and does not require a separate image-generation service.

## Segment fields

Generated questions keep the existing fields and add:

- `imageUrl`: MinIO PNG URL used by Flutter
- `imageProvider`: `local-svg`
- `visualPrompt`: local background description
- `visualData`: exact counts, operator, object types, and labels

Flutter rewrites localhost MinIO URLs to the configured API host, allowing the same activity data to work on web, Android emulators, and physical devices.
