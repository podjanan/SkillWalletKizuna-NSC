import { NextRequest, NextResponse } from 'next/server';
import { auth } from '@/lib/auth';
import { callOllama } from '@/lib/ai-word-game';
import {
  fallbackQuestion,
  operatorDescription,
  parseEquation,
  questionMatchesEquation,
  randomStoryItem,
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

    const storyItem = randomStoryItem(equation.operator);
    const fallback = fallbackQuestion(equation, storyItem);
    const prompt = `คุณเป็นครูสอนภาษาไทยและคณิตศาสตร์เด็กเล็ก (อนุบาล - ประถมต้น)
จงแต่งโจทย์ปัญหาคณิตศาสตร์ภาษาไทยที่ **สั้น กระชับ เป็นธรรมชาติ ไวยากรณ์และลักษณะนามถูกต้อง 100%** ให้ตรงกับสมการ ${equation.left} ${equation.operator} ${equation.right}

บริบทกิจกรรม: ${activityTitle}
ความหมาย: ${operatorDescription(equation.operator)}
${storyItem ? `ชนิดสิ่งของที่ระบบสุ่มไว้: **${storyItem.name}** ต้องใช้คำนี้เท่านั้น ห้ามเปลี่ยนเป็นสิ่งของชนิดอื่น` : ''}

ข้อกำหนดทางภาษาและลักษณะนาม (สำคัญมาก):
- ต้องใช้ **ลักษณะนาม (Classifier Noun)** ให้ถูกต้องตามชนิดของสิ่งของหรือคำนามนั้นๆ อย่างเคร่งครัด เช่น:
  * ไข่ -> **ฟอง** (เช่น "มีไข่ ${equation.left} ฟอง แม่ให้อีก ${equation.right} ฟอง รวมมีไข่ทั้งหมดกี่ฟอง?")
  * ผลไม้ / ส้ม / แอปเปิ้ล -> **ลูก** หรือ **ผล**
  * ขนม / เค้ก -> **ชิ้น**
  * สัตว์ (แกะ, นก, ปลา, แมว) -> **ตัว**
  * หนังสือ / สมุด -> **เล่ม**
  * ดินสอ -> **แท่ง**
  * จาน / กล่อง / ตะกร้า -> **ใบ**
- **ห้าม** ใช้ลักษณะนามผิด เช่น ห้ามใช้ "ไข่...อัน" (ต้องเป็น "ไข่...ฟอง"), ห้ามใช้ "สัตว์...อัน" (ต้องเป็น "สัตว์...ตัว")
- ใช้คำกริยาธรรมชาติที่มีกริยาชัดเจน เช่น "แม่ให้อีก", "ซื้อมาเพิ่มอีก", "เดินมาเพิ่มอีก", "กินไป", "ใช้ไป" (ห้ามใช้คำห้วนๆ เช่น "ได้อีก")
- ต้องใช้ตัวเลข ${equation.left} และ ${equation.right} อย่างละ 1 ครั้ง
- คำใบ้ต้องสั้นกระชับเข้าใจง่าย
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

      const usesSelectedItem = !storyItem || generatedQuestion.includes(storyItem.name);
      const classifierCount = storyItem
        ? generatedQuestion.split(storyItem.classifier).length - 1
        : 0;
      const usesCorrectClassifier = !storyItem || classifierCount >= 2;
      if (generatedQuestion && usesSelectedItem && usesCorrectClassifier && questionMatchesEquation(generatedQuestion, equation)) {
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
