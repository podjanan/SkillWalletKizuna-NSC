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
  questionIndex?: number;
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
    .replace(/[−–—]/g, '-')
    .replace(/[๐-๙]/g, (d) => String('๐123456789'.indexOf(d)));
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

async function recognizeWithGeminiVision(base64Image: string, questions: Question[], mimeType = 'image/jpeg') {
  const apiKey = process.env.GEMINI_API_KEY?.trim();
  if (!apiKey) return null;

  const models = [
    process.env.GEMINI_MODEL?.trim(),
    'gemini-2.5-flash',
    'gemini-1.5-flash',
    'gemini-2.0-flash',
  ].filter(Boolean) as string[];

  const uniqueModels = Array.from(new Set(models));

  const prompt = `You are an expert elementary school math handwriting OCR evaluator.
Children write their math answers by hand. The handwriting may be messy, slanted, uneven, written in pencil/crayon, or use Thai digits (๐-๙).

Target Questions to Evaluate:
${JSON.stringify(questions, null, 2)}

Instructions:
1. Inspect the image carefully to extract the student's handwritten answer for each target question.
2. Convert Thai digits (๐-๙) to standard Arabic digits (0-9).
3. Ignore scratch marks or erased doodles. Find the actual numerical answer written by the child.
4. Compare the detected answer with the expected answer numerically.
5. Return JSON ONLY with the following exact structure:
{
  "results": [
    {
      "questionIndex": 1,
      "detectedText": "8",
      "detectedAnswer": "8",
      "confidence": 0.98,
      "isCorrect": true
    }
  ]
}`;

  for (const model of uniqueModels) {
    try {
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          contents: [
            {
              parts: [
                {
                  inlineData: {
                    mimeType,
                    data: base64Image,
                  },
                },
                { text: prompt },
              ],
            },
          ],
          generationConfig: {
            temperature: 0.1,
            responseMimeType: 'application/json',
          },
        }),
        signal: AbortSignal.timeout(20000),
      });

      if (!response.ok) {
        console.warn(`Gemini Vision OCR attempt HTTP ${response.status} for model ${model}`);
        continue;
      }

      const data = await response.json();
      const rawText = data?.candidates?.[0]?.content?.parts?.[0]?.text;
      if (!rawText) continue;

      const cleaned = rawText.replace(/```json\s*/gi, '').replace(/```\s*/g, '').trim();
      const parsed = JSON.parse(cleaned) as { results?: Array<{ questionIndex?: number; detectedText?: string; detectedAnswer?: string; confidence?: number; isCorrect?: boolean }> };
      if (Array.isArray(parsed.results) && parsed.results.length > 0) {
        const formattedResults = questions.map((q, idx) => {
          const targetIdx = q.questionIndex ?? (idx + 1);
          const found = parsed.results?.find((r) => r.questionIndex === targetIdx || r.questionIndex === idx + 1);
          const expected = normalizeAnswer(q.answer);
          const detectedText = normalizeAnswer(found?.detectedText ?? found?.detectedAnswer ?? '');
          const isCorrect = found?.isCorrect ?? (detectedText === expected && expected !== '');
          return {
            questionIndex: targetIdx,
            detectedText: detectedText || (found?.detectedText ?? ''),
            detectedAnswer: detectedText || (found?.detectedAnswer ?? ''),
            confidence: Number(found?.confidence ?? (isCorrect ? 0.95 : 0.4)),
            isCorrect,
          };
        });

        return {
          engine: `gemini-vision (${model})`,
          results: formattedResults,
        };
      }
    } catch (err) {
      console.warn(`Gemini Vision OCR error for ${model}:`, err);
    }
  }
  return null;
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

    const body = await request.json() as { base64Image?: string; questions?: Question[]; mimeType?: string };
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
    const mimeType = body.mimeType || 'image/jpeg';

    // 1. Primary Engine: Gemini Vision AI (high accuracy for messy handwriting)
    const geminiResult = await recognizeWithGeminiVision(cleanBase64, body.questions, mimeType);
    if (geminiResult) {
      return NextResponse.json({
        success: true,
        engine: geminiResult.engine,
        results: geminiResult.results,
      }, { headers: corsHeaders });
    }

    // 2. Secondary Engine: Enhanced Local EasyOCR with Sharp image preprocessing
    const imageBuffer = Buffer.from(cleanBase64, 'base64');
    const optimizedImage = await sharp(imageBuffer)
      .rotate()
      .flatten({ background: '#ffffff' })
      .grayscale()
      .linear(1.2, -10) // Contrast boost
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

    const results = body.questions.map((question, index) => {
      const qIndex = question.questionIndex ?? (index + 1);
      const expected = normalizeAnswer(question.answer);
      const matchIndex = available.findIndex((item) => {
        if (item.normalized === expected) return true;
        if (!/^\d+$/.test(expected)) return false;
        const detectedDigits = item.normalized.replace(/\D/g, '');
        if (detectedDigits === expected) return true;
        return item.confidence < 0.75 &&
          detectedDigits.length === expected.length + 1 &&
          (detectedDigits.startsWith(expected) || detectedDigits.endsWith(expected));
      });
      const match = matchIndex >= 0 ? available.splice(matchIndex, 1)[0] : null;
      return {
        questionIndex: qIndex,
        detectedText: match ? (match.normalized || match.original) : '',
        detectedAnswer: match ? (match.normalized || match.original) : '',
        confidence: match?.confidence ?? 0,
        isCorrect: Boolean(match),
      };
    });

    return NextResponse.json({
      success: true,
      engine: 'easyocr-local-enhanced',
      detectedNumbers: detected,
      unmatchedNumbers: available.map((item) => item.original),
      results,
    }, { headers: corsHeaders });
  } catch (error: unknown) {
    console.error('POST /api/activities/verify-handwriting error:', error);
    return NextResponse.json(
      {
        error: 'Handwriting OCR evaluation failed',
        details: error instanceof Error ? error.message : String(error),
      },
      { status: 503, headers: corsHeaders },
    );
  }
}

