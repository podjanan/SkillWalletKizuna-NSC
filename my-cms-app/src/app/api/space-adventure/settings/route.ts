import { NextRequest, NextResponse } from 'next/server';
import { getSpaceAdventureSettings, updateSpaceAdventureSettings } from '@/lib/ai-word-game';

function getErrorMessage(error: unknown) {
  return error instanceof Error ? error.message : 'Unexpected error';
}

export async function GET() {
  try {
    const settings = await getSpaceAdventureSettings();
    return NextResponse.json({ success: true, data: settings });
  } catch (e: unknown) {
    return NextResponse.json({ success: false, error: getErrorMessage(e) }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const scorePerItem = Number(body.scorePerItem ?? 10);
    const timerLimit = Number(body.timerLimit ?? 60);
    const settings = await updateSpaceAdventureSettings(scorePerItem, timerLimit);
    return NextResponse.json({ success: true, data: settings });
  } catch (e: unknown) {
    return NextResponse.json({ success: false, error: getErrorMessage(e) }, { status: 500 });
  }
}
