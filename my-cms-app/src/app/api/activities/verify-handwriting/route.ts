import { NextRequest, NextResponse } from 'next/server';
import sharp from 'sharp';
import { auth } from '@/lib/auth';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-API-Key, x-requested-with',
  'Access-Control-Max-Age': '86400',
};

type Question = {
  id?: string | number;
  question?: string;
  answer?: string | number;
};

type OcrNumber = {
  text: string;
  confidence?: number;
};

function normalizeAnswer(value: unknown) {
  return String(value ?? '')
    .trim()
    .replace(/[\s,]/g, '')
    .replace(/[−–—]/g, '-');
}

async function recognizeNumbersLocally(base64Image: string): Promise<OcrNumber[]> {
  const configuredUrl = process.env.HANDWRITING_OCR_URL?.trim();
  const detectorUrl = process.env.OBJECT_DETECTION_URL?.trim();
  const url = configuredUrl || (detectorUrl
    ? `${detectorUrl.replace(/\/detect\/?$/, '')}/recognize-numbers`
    : 'http://localhost:8002/recognize-numbers');

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ image: base64Image }),
    signal: AbortSignal.timeout(30000),
  });
  if (!response.ok) {
    throw new Error(`Local number OCR returned HTTP ${response.status}: ${await response.text()}`);
  }
  const payload = await response.json() as { numbers?: OcrNumber[] };
  return Array.isArray(payload.numbers) ? payload.numbers : [];
}

export async function OPTIONS() {
  return NextResponse.json({}, { headers: corsHeaders });
}

export async function POST(request: NextRequest) {
  try {
    const session = await auth.api.getSession({ headers: request.headers });
    if (!session?.user) {
      return NextResponse.json(
        { error: 'Unauthorized user session' },
        { status: 401, headers: corsHeaders },
      );
    }

    const body = await request.json() as { base64Image?: string; questions?: Question[] };
    if (!body.base64Image) {
      return NextResponse.json(
        { error: 'Missing required field: base64Image' },
        { status: 400, headers: corsHeaders },
      );
    }
    if (!Array.isArray(body.questions) || body.questions.length === 0) {
      return NextResponse.json(
        { error: 'Missing or empty required field: questions' },
        { status: 400, headers: corsHeaders },
      );
    }

    const cleanBase64 = body.base64Image.replace(/^data:image\/\w+;base64,/, '');
    const optimizedImage = await sharp(Buffer.from(cleanBase64, 'base64'))
      .rotate()
      .flatten({ background: '#ffffff' })
      .trim({ background: '#ffffff', threshold: 12 })
      .extend({ top: 24, bottom: 24, left: 24, right: 24, background: '#ffffff' })
      .resize({ width: 1600, height: 1600, fit: 'inside', withoutEnlargement: true })
      .jpeg({ quality: 92 })
      .toBuffer();

    const detected = await recognizeNumbersLocally(optimizedImage.toString('base64'));
    const available = detected.map((item) => ({
      original: item.text,
      normalized: normalizeAnswer(item.text),
      confidence: Number(item.confidence ?? 0),
    }));

    // Match by value only. Position and OCR output order are intentionally
    // ignored because children may write answers anywhere on the page.
    const results = body.questions.map((question, index) => {
      const expected = normalizeAnswer(question.answer);
      const matchIndex = available.findIndex((item) => {
        if (item.normalized === expected) return true;
        // EasyOCR can mistake a large gap between handwritten digits for a
        // dash (for example "3 6" -> "3-6"). For positive integer answers,
        // compare the digit sequence as a safe secondary match.
        if (!/^\d+$/.test(expected)) return false;
        const detectedDigits = item.normalized.replace(/\D/g, '');
        if (detectedDigits === expected) return true;
        return item.confidence < 0.75 &&
          detectedDigits.length === expected.length + 1 &&
          (detectedDigits.startsWith(expected) || detectedDigits.endsWith(expected));
      });
      const match = matchIndex >= 0 ? available.splice(matchIndex, 1)[0] : null;
      return {
        questionIndex: index + 1,
        detectedText: match ? expected : '',
        detectedAnswer: match ? expected : '',
        confidence: match?.confidence ?? 0,
        isCorrect: Boolean(match),
      };
    });

    return NextResponse.json({
      success: true,
      engine: 'easyocr-local',
      detectedNumbers: detected,
      unmatchedNumbers: available.map((item) => item.original),
      results,
    }, { headers: corsHeaders });
  } catch (error: unknown) {
    console.error('POST /api/activities/verify-handwriting error:', error);
    return NextResponse.json(
      {
        error: 'Local handwriting OCR failed',
        details: error instanceof Error ? error.message : String(error),
      },
      { status: 503, headers: corsHeaders },
    );
  }
}
