import { NextRequest, NextResponse } from 'next/server';
import { auth } from '@/lib/auth';
import { callOllama } from '@/lib/ai-word-game';
import {
  fallbackQuestion,
  operatorDescription,
  parseEquation,
  questionMatchesEquation,
} from '@/lib/math-question';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

export async function OPTIONS() {
  return NextResponse.json({}, { headers: corsHeaders });
}

function extractJson(text: string): { question?: unknown; hint?: unknown; solution?: unknown } | null {
  const candidates = [text, text.match(/\{[\s\S]*\}/)?.[0]].filter(Boolean) as string[];
  for (const candidate of candidates) {
    try {
      const parsed = JSON.parse(candidate);
      if (parsed && typeof parsed === 'object') return parsed;
    } catch {
      // Try the next candidate.
    }
  }
  return null;
}

export async function POST(request: NextRequest) {
  try {
    const session = await auth.api.getSession({ headers: request.headers });
    if (!session?.user) {
      return NextResponse.json({ error: 'Unauthorized user session' }, { status: 401, headers: corsHeaders });
    }

    const body = await request.json() as {
      activityTitle?: string;
      activityDescription?: string;
      equation?: string;
    };
    const activityTitle = body.activityTitle?.trim();
    const activityDescription = body.activityDescription?.trim();
    const equationText = body.equation?.trim();
    if (!activityTitle || !activityDescription || !equationText) {
      return NextResponse.json(
        { error: 'Missing required fields: activityTitle, activityDescription, or equation' },
        { status: 400, headers: corsHeaders },
      );
    }

    const equation = parseEquation(equationText);
    if (!equation) {
      return NextResponse.json(
        { error: 'Invalid equation. Use a basic equation such as 18+2, 9-3, 4*5 or 12/3.' },
        { status: 400, headers: corsHeaders },
      );
    }

    const fallback = fallbackQuestion(equation);
    const prompt = `คุณเป็นครูคณิตศาสตร์สำหรับเด็กอายุ 4-9 ปี
แต่งโจทย์ปัญหาภาษาไทยสั้น ๆ ที่ตรงกับสมการ ${equation.left} ${equation.operator} ${equation.right} เท่านั้น

บริบทกิจกรรม: ${activityTitle} — ${activityDescription}
ความหมายที่ต้องใช้: ${operatorDescription(equation.operator)}

กฎสำคัญ:
- ต้องใช้ตัวเลข ${equation.left} และ ${equation.right} อย่างละหนึ่งครั้งในโจทย์
- ห้ามเพิ่มจำนวนคน จำนวนกล่อง หรือจำนวนกลุ่มอื่นที่ไม่มีในสมการ
- หน่วยของจำนวนทั้งสองต้องสัมพันธ์กันอย่างถูกต้อง
- คำใบ้บอกวิธีคิดได้ แต่ห้ามบอกผลลัพธ์ ${equation.answer}
- ตอบเฉพาะ JSON รูปแบบ {"question":"...","hint":"..."}`;

    let question = fallback.question;
    let solution = fallback.hint;
    let generationSource: 'ollama' | 'validated-fallback' = 'validated-fallback';

    try {
      const aiResponse = await callOllama(prompt, true, 0.2);
      const parsed = extractJson(aiResponse);
      const generatedQuestion = typeof parsed?.question === 'string' ? parsed.question.trim() : '';
      const generatedHint = typeof parsed?.hint === 'string'
        ? parsed.hint.trim()
        : typeof parsed?.solution === 'string'
          ? parsed.solution.trim()
          : '';

      if (generatedQuestion && questionMatchesEquation(generatedQuestion, equation)) {
        question = generatedQuestion;
        solution = generatedHint || fallback.hint;
        generationSource = 'ollama';
      } else {
        console.warn('Rejected inconsistent Ollama math story:', generatedQuestion);
      }
    } catch (error) {
      console.warn('Ollama question generation failed; using validated fallback:', error);
    }

    return NextResponse.json({
      success: true,
      question,
      solution,
      answer: String(equation.answer),
      generationSource,
    }, { headers: corsHeaders });
  } catch (error) {
    console.error('POST /api/activities/generate-math-question error:', error);
    return NextResponse.json(
      { error: 'Internal Server Error', details: error instanceof Error ? error.message : String(error) },
      { status: 500, headers: corsHeaders },
    );
  }
}
