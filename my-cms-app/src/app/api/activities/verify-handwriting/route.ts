// src/app/api/activities/verify-handwriting/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { auth } from '@/lib/auth';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-API-Key, x-requested-with',
  'Access-Control-Max-Age': '86400',
};

export async function OPTIONS() {
  return NextResponse.json({}, { headers: corsHeaders });
}

async function callGeminiREST(prompt: string, base64Image?: string, schema?: any): Promise<string> {
  const apiKey = process.env.GEMINI_API_KEY;
  const modelName = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
  
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY is not configured in environment variables.');
  }

  const url = `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${apiKey}`;

  const parts: any[] = [{ text: prompt }];
  if (base64Image) {
    parts.push({
      inlineData: {
        mimeType: 'image/jpeg',
        data: base64Image
      }
    });
  }

  const requestBody = {
    contents: [
      {
        parts
      }
    ],
    generationConfig: schema ? {
      responseMimeType: 'application/json',
      responseSchema: schema
    } : undefined
  };

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify(requestBody)
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Gemini API returned error: ${response.status} - ${errorText}`);
  }

  const resultJson = await response.json();
  const text = resultJson.candidates?.[0]?.content?.parts?.[0]?.text;
  if (!text) {
    throw new Error('Gemini API returned an empty response.');
  }
  return text;
}

export async function POST(request: NextRequest) {
  try {
    const session = await auth.api.getSession({ headers: request.headers });
    if (!session?.user) {
      return NextResponse.json(
        { error: 'Unauthorized user session' },
        { status: 401, headers: corsHeaders }
      );
    }

    const body = await request.json();
    const { base64Image, questions } = body;

    if (!base64Image) {
      return NextResponse.json(
        { error: 'Missing required field: base64Image' },
        { status: 400, headers: corsHeaders }
      );
    }

    if (!questions || !Array.isArray(questions) || questions.length === 0) {
      return NextResponse.json(
        { error: 'Missing or empty required field: questions (must be an array)' },
        { status: 400, headers: corsHeaders }
      );
    }

    // Compose prompt instructing Gemini to perform OCR and grade correctness
    const questionsText = questions
      .map((q) => `Question #${q.id}: "${q.question}" (Expected Answer: "${q.answer}")`)
      .join('\n');

    const prompt = `You are a primary school math teacher evaluating a student's handwritten answer sheet.
Compare the handwritten equations in the image to the question list below and determine whether they are correct.

List of expected questions:
${questionsText}

For each question:
1. Locate the written equation corresponding to that question number or math expression in the image.
2. Read the text of the equation written by the child.
3. Extract the final numerical answer from their written equation.
4. Compare their final answer to the Expected Answer. (Ensure minor spelling, spacing, or handwriting deviations are evaluated fairly; e.g. "12 + 8 = 20" matches the expected answer "20").
5. Mark "isCorrect" as true if the answer matches the expected answer, false otherwise.

Provide feedback as a JSON array of results matching the strict schema.`;

    const schema = {
      type: 'OBJECT',
      properties: {
        results: {
          type: 'ARRAY',
          items: {
            type: 'OBJECT',
            properties: {
              questionIndex: { type: 'INTEGER', description: 'The 1-based index corresponding to the question ID.' },
              detectedText: { type: 'STRING', description: 'The complete equation text detected (e.g. "12 + 8 = 20").' },
              detectedAnswer: { type: 'STRING', description: 'The extracted numerical answer text (e.g. "20").' },
              isCorrect: { type: 'BOOLEAN', description: 'True if the answer matches the expected answer.' }
            },
            required: ['questionIndex', 'detectedText', 'detectedAnswer', 'isCorrect']
          }
        }
      },
      required: ['results']
    };

    // Clean image prefix if present
    const cleanBase64 = base64Image.replace(/^data:image\/\w+;base64,/, '');

    const geminiResponseText = await callGeminiREST(prompt, cleanBase64, schema);
    let parsedResult;
    try {
      parsedResult = JSON.parse(geminiResponseText);
    } catch (err) {
      console.error('Failed to parse Gemini OCR response JSON:', geminiResponseText);
      return NextResponse.json(
        { error: 'Failed to parse AI grading results', details: geminiResponseText },
        { status: 500, headers: corsHeaders }
      );
    }

    return NextResponse.json(
      {
        success: true,
        results: parsedResult.results
      },
      { headers: corsHeaders }
    );

  } catch (error: any) {
    console.error('POST /api/activities/verify-handwriting error:', error);
    return NextResponse.json(
      { error: 'Internal Server Error', details: error.message },
      { status: 500, headers: corsHeaders }
    );
  }
}
