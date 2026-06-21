import { NextRequest, NextResponse } from 'next/server';
import { scanRoomImage } from '@/lib/ai-word-game';

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const image = body.image;
    if (!image) {
      return NextResponse.json({ success: false, error: 'Image base64 data is required' }, { status: 400 });
    }

    const objects = await scanRoomImage(image);
    return NextResponse.json({ success: true, objects });
  } catch (e: any) {
    console.error('Room scan API error:', e);
    return NextResponse.json({ success: false, error: e.message }, { status: 500 });
  }
}
