import { NextRequest, NextResponse } from 'next/server';
import { uploadToMinio } from '@/lib/minio';
import { scanRoomImage } from '@/lib/ai-word-game';

function getErrorMessage(error: unknown) {
  return error instanceof Error ? error.message : 'Unexpected error';
}

function getExtension(contentType: string) {
  if (contentType === 'image/png') return 'png';
  if (contentType === 'image/webp') return 'webp';
  return 'jpg';
}

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData();
    const file = formData.get('image') as File | null;

    if (!file) {
      return NextResponse.json({ success: false, error: 'image field is required' }, { status: 400 });
    }

    const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/webp'];
    if (!allowedTypes.includes(file.type)) {
      return NextResponse.json(
        { success: false, error: 'Unsupported file type. Use JPEG, PNG or WebP.' },
        { status: 400 },
      );
    }

    const maxSize = 5 * 1024 * 1024;
    if (file.size > maxSize) {
      return NextResponse.json({ success: false, error: 'File too large (max 5 MB)' }, { status: 400 });
    }

    const bytes = new Uint8Array(await file.arrayBuffer());
    const base64Image = `data:${file.type};base64,${Buffer.from(bytes).toString('base64')}`;
    const scan = await scanRoomImage(base64Image);
    const key = `space-adventure/areas/${crypto.randomUUID()}.${getExtension(file.type)}`;
    const imageUrl = await uploadToMinio(key, bytes, file.type);

    return NextResponse.json({
      success: true,
      imageUrl,
      objects: scan.objects,
      detectionSource: scan.source,
      detectionFallback: scan.fallback,
      detectionReason: scan.fallback ? scan.reason : undefined,
    });
  } catch (e: unknown) {
    console.error('Space Adventure area image upload error:', e);
    return NextResponse.json({ success: false, error: getErrorMessage(e) }, { status: 500 });
  }
}
