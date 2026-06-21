import { NextRequest, NextResponse } from 'next/server';
import { saveGameScore, getTopScores } from '@/lib/ai-word-game';

export async function GET() {
  try {
    const scores = await getTopScores(20);
    return NextResponse.json({ success: true, scores });
  } catch (e: any) {
    return NextResponse.json({ success: false, error: e.message }, { status: 500 });
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const playerName = String(body.playerName ?? 'Space Adventurer');
    const score = Number(body.score ?? 0);
    const newScore = await saveGameScore(playerName, score);
    return NextResponse.json({ success: true, score: newScore });
  } catch (e: any) {
    return NextResponse.json({ success: false, error: e.message }, { status: 500 });
  }
}
