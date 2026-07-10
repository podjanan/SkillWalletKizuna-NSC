// src/app/api/activities/generate-math-images/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { auth } from '@/lib/auth';
import { uploadToMinio } from '@/lib/minio';
import cuid from 'cuid';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization, X-API-Key, x-requested-with',
  'Access-Control-Max-Age': '86400',
};

export async function OPTIONS() {
  return NextResponse.json({}, { headers: corsHeaders });
}

async function callGeminiREST(prompt: string): Promise<string> {
  const apiKey = process.env.GEMINI_API_KEY;
  const modelName = process.env.GEMINI_MODEL || 'gemini-2.5-flash';
  
  if (!apiKey) {
    throw new Error('GEMINI_API_KEY is not configured in environment variables.');
  }

  const url = `https://generativelanguage.googleapis.com/v1beta/models/${modelName}:generateContent?key=${apiKey}`;

  const requestBody = {
    contents: [
      {
        parts: [{ text: prompt }]
      }
    ]
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

async function getDuckDuckGoImages(query: string) {
  try {
    const searchPageResponse = await fetch(
      `https://duckduckgo.com/?q=${encodeURIComponent(query)}`,
      {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        },
      }
    );
    const searchPageHtml = await searchPageResponse.text();
    const vqdMatch = searchPageHtml.match(/vqd=([^&'"]+)/);
    if (!vqdMatch) return null;

    const vqd = vqdMatch[1];
    const apiResponse = await fetch(
      `https://duckduckgo.com/i.js?l=us-en&o=json&q=${encodeURIComponent(query)}&vqd=${vqd}&f=,,,`
    );
    const json = await apiResponse.json();
    return json.results && json.results.length > 0 ? json.results : null;
  } catch (e) {
    console.error('DuckDuckGo image search failed:', e);
    return null;
  }
}

async function downloadAndUploadImage(imgUrl: string): Promise<string | null> {
  try {
    const response = await fetch(imgUrl);
    if (!response.ok) return null;
    const arrayBuffer = await response.arrayBuffer();
    const buffer = Buffer.from(arrayBuffer);
    
    const filename = `math-illustration-${cuid()}.jpg`;
    // Signature: uploadToMinio(key: string, body: Uint8Array, contentType: string)
    const uploadResultUrl = await uploadToMinio(filename, new Uint8Array(buffer), 'image/jpeg');
    return uploadResultUrl;
  } catch (e) {
    console.error(`Failed to download and upload image ${imgUrl}:`, e);
    return null;
  }
}

async function searchAndUploadFallbackImage(query: string): Promise<string | null> {
  try {
    const results = await getDuckDuckGoImages(query);
    if (results && results.length > 0) {
      for (const img of results.slice(0, 3)) {
        try {
          const url = await downloadAndUploadImage(img.image);
          if (url) return url;
        } catch (err) {
          console.error(`Failed to download DDG image ${img.image}:`, err);
        }
      }
    }
  } catch (e) {
    console.error('DuckDuckGo image download failed:', e);
  }
  return null;
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
    const { questions } = body;

    if (!questions || !Array.isArray(questions)) {
      return NextResponse.json(
        { error: 'Missing or invalid required field: questions must be an array' },
        { status: 400, headers: corsHeaders }
      );
    }

    const updatedSegments = [];
    const contexts = ['bakery', 'farm', 'convenience store', 'toy store', 'ocean', 'zoo'];

    for (let i = 0; i < questions.length; i++) {
      const q = questions[i];
      const randomContext = contexts[i % contexts.length];

      // Step 1: Prompt Gemini to compose a visual cartoon scene description representing the math problem
      const prompt = `You are a children's book illustrator designer.
Look at this math problem: "${q.question}" (Expected Answer: "${q.answer}").
Write a detailed description for a children's cartoon illustration that represents this math equation in a "${randomContext}" context.

The scene must have:
- Cozy pastel colors, clean bold dark outlines, and flat coloring.
- A prominent left group and right group of friendly items representing the terms of the math equation (e.g. if the equation is "12 + 8 = ?", show 12 items on the left and 8 items on the right).
- A prominent wooden signboard or blackboard clearly displaying the equation: "${q.question} = ?" or the numbers involved.
- Friendly, smiling characters interacting with the scene.

Return ONLY the descriptive prompt in English (around 35-50 words). Do NOT write any other text.`;

      let visualPrompt = '';
      try {
        visualPrompt = await callGeminiREST(prompt);
        visualPrompt = visualPrompt.trim();
      } catch (err) {
        console.error('Failed to get visual prompt from Gemini:', err);
        visualPrompt = `cozy children storybook cartoon scene of a math equation ${q.question} in a ${randomContext} theme`;
      }

      // Step 2: Try OpenAI DALL-E 3 if configured
      let imageUrl = '';
      const hasOpenAI = !!process.env.OPENAI_API_KEY;

      if (hasOpenAI) {
        try {
          const apiPrompt = `${visualPrompt}, cute 2D cartoon, children storybook illustration style, cozy pastel colors, bold clean outlines, flat coloring, high quality, vector graphic.`;
          const response = await fetch('https://api.openai.com/v1/images/generations', {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              'Authorization': `Bearer ${process.env.OPENAI_API_KEY}`,
            },
            body: JSON.stringify({
              model: 'dall-e-3',
              prompt: apiPrompt,
              n: 1,
              size: '1024x1024',
              response_format: 'url',
            }),
          });
          const resJson = await response.json();
          if (resJson.data && resJson.data[0]) {
            const rawUrl = resJson.data[0].url;
            const minioUrl = await downloadAndUploadImage(rawUrl);
            if (minioUrl) imageUrl = minioUrl;
          }
        } catch (openaiErr) {
          console.error('OpenAI image generation failed, falling back to DuckDuckGo:', openaiErr);
        }
      }

      // Step 3: Zero-cost Fallback using DuckDuckGo cartoon image search
      if (!imageUrl) {
        try {
          const searchQueries = [
            `${randomContext} cartoon illustration children storybook`,
            `cute cartoon vector ${randomContext}`,
            `math classroom cartoon children vector`
          ];
          const query = searchQueries[i % searchQueries.length];
          const minioUrl = await searchAndUploadFallbackImage(query);
          if (minioUrl) {
            imageUrl = minioUrl;
          } else {
            // Failsafe placeholder if all else fails
            imageUrl = 'https://placehold.co/600x400/fffdf6/2e7d32?text=Math+Simulation';
          }
        } catch (searchErr) {
          console.error('DuckDuckGo fallback search failed:', searchErr);
          imageUrl = 'https://placehold.co/600x400/fffdf6/2e7d32?text=Math+Simulation';
        }
      }

      updatedSegments.push({
        id: q.id,
        question: q.question,
        answer: q.answer,
        solution: q.solution || q.hint || '',
        score: Number(q.score) || 10,
        imageUrl,
        visualPrompt,
      });
    }

    return NextResponse.json(
      {
        success: true,
        segments: updatedSegments,
      },
      { headers: corsHeaders }
    );

  } catch (error: any) {
    console.error('POST /api/activities/generate-math-images error:', error);
    return NextResponse.json(
      { error: 'Internal Server Error', details: error.message },
      { status: 500, headers: corsHeaders }
    );
  }
}
