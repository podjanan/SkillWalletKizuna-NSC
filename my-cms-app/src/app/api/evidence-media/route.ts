import { NextRequest, NextResponse } from 'next/server';
import { randomUUID } from 'crypto';
import { getAuthenticatedParent } from '@/lib/get-parent';
import { uploadToMinio } from '@/lib/minio';

const MAX_FILE_SIZE = 100 * 1024 * 1024;
const ALLOWED_TYPES = new Set([
  'image/jpeg', 'image/png', 'image/webp', 'image/heic', 'image/heif',
  'video/mp4', 'video/quicktime', 'video/webm', 'video/x-m4v',
]);

export async function POST(request: NextRequest) {
  try {
    const auth = await getAuthenticatedParent(request);
    if (auth.error) return auth.error;

    const form = await request.formData();
    const file = form.get('file');
    if (!(file instanceof File)) {
      return NextResponse.json({ error: 'Missing media file' }, { status: 400 });
    }
    if (!ALLOWED_TYPES.has(file.type)) {
      return NextResponse.json({ error: 'Unsupported image or video format' }, { status: 415 });
    }
    if (file.size <= 0 || file.size > MAX_FILE_SIZE) {
      return NextResponse.json({ error: 'File must be between 1 byte and 100 MB' }, { status: 413 });
    }

    const extension = file.name.split('.').pop()?.replace(/[^a-zA-Z0-9]/g, '').toLowerCase() ||
      (file.type.startsWith('video/') ? 'mp4' : 'jpg');
    const key = `evidence/${auth.parent.parent_id}/${randomUUID()}.${extension}`;
    const url = await uploadToMinio(key, new Uint8Array(await file.arrayBuffer()), file.type);
    return NextResponse.json({ url, contentType: file.type });
  } catch (error) {
    console.error('Evidence media upload error:', error);
    return NextResponse.json({ error: 'Unable to upload evidence media' }, { status: 500 });
  }
}
