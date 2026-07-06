import { NextRequest, NextResponse } from 'next/server';
import { verifyTargetItem } from '@/lib/ai-word-game';

function getErrorMessage(error: unknown) {
  return error instanceof Error ? error.message : 'Unexpected error';
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { image, target } = body;
    if (!image || !target) {
      return NextResponse.json({ success: false, error: 'Image base64 data and target word are required' }, { status: 400 });
    }

    const verification = await verifyTargetItem(image, target);
    return NextResponse.json({ success: true, ...verification });
  } catch (e: unknown) {
    console.error('Verify item API error:', e);
    return NextResponse.json({ success: false, error: getErrorMessage(e) }, { status: 500 });
  }
}
