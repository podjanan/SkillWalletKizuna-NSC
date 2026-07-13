import { NextRequest, NextResponse } from 'next/server';
import { auth } from '@/lib/auth';
import { uploadToMinio } from '@/lib/minio';
import { createMathSimulationImage } from '@/lib/math-simulation-image';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-API-Key, x-requested-with',
  'Access-Control-Max-Age': '86400',
};

type MathQuestion = {
  id?: string;
  question?: string;
  equation?: string;
  answer?: string;
  solution?: string;
  hint?: string;
  score?: number;
};

export async function OPTIONS() {
  return NextResponse.json({}, { headers: corsHeaders });
}

export async function POST(request: NextRequest) {
  try {
    const session = await auth.api.getSession({ headers: request.headers });
    if (!session?.user) {
      return NextResponse.json({ error: 'Unauthorized user session' }, { status: 401, headers: corsHeaders });
    }

    const body = await request.json() as { questions?: MathQuestion[] };
    if (!Array.isArray(body.questions) || body.questions.length === 0) {
      return NextResponse.json({ error: 'questions must be a non-empty array' }, { status: 400, headers: corsHeaders });
    }

    const segments = [];
    for (const [index, question] of body.questions.entries()) {
      const questionText = String(question.question ?? question.equation ?? '').trim();
      if (!questionText) {
        return NextResponse.json({ error: `Question ${index + 1} has no text` }, { status: 400, headers: corsHeaders });
      }

      const generated = await createMathSimulationImage(questionText, question.equation);
      const key = `math-simulation/${crypto.randomUUID()}.png`;
      const imageUrl = await uploadToMinio(key, new Uint8Array(generated.buffer), 'image/png');

      segments.push({
        ...question,
        id: question.id ?? String(index + 1),
        solution: question.solution ?? question.hint ?? '',
        imageUrl,
        imageProvider: generated.provider,
        visualPrompt: generated.visualPrompt,
        visualData: generated.visualData,
      });
    }

    return NextResponse.json({ success: true, segments }, { headers: corsHeaders });
  } catch (error) {
    console.error('POST /api/activities/generate-math-images error:', error);
    return NextResponse.json(
      { error: 'Unable to generate math simulation images', details: error instanceof Error ? error.message : String(error) },
      { status: 500, headers: corsHeaders },
    );
  }
}
