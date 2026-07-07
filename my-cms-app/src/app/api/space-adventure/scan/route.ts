import { NextRequest, NextResponse } from 'next/server';
import { scanRoomImage } from '@/lib/ai-word-game';

function getErrorMessage(error: unknown) {
  return error instanceof Error ? error.message : 'Unexpected error';
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const image = body.image;
    if (!image) {
      return NextResponse.json({ success: false, error: 'Image base64 data is required' }, { status: 400 });
    }

    const scan = await scanRoomImage(image);
    if (scan.fallback) {
      return NextResponse.json({
        success: false,
        fallback: true,
        objects: scan.objects,
        error: 'Unable to scan room image.',
        reason: scan.reason,
      });
    }

    return NextResponse.json({ success: true, objects: scan.objects, source: scan.source, fallback: false });
  } catch (e: unknown) {
    console.error('Room scan API error:', e);
    return NextResponse.json({ success: false, error: getErrorMessage(e) }, { status: 500 });
  }
}
