// src/app/api/activities/generate-math-question/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { auth } from '@/lib/auth';
import { callOllama } from '@/lib/ai-word-game';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, Authorization',
};

export async function OPTIONS() {
  return NextResponse.json({}, { headers: corsHeaders });
}

function safeEvaluate(equation: string): string {
  try {
    // Keep only numbers and basic operators +, -, *, /, (, )
    const cleaned = equation.replace(/[^0-9+\-*/().\s]/g, '');
    if (!cleaned) return '';
    // Using Function is safe here since we strip everything except math symbols and digits
    const result = new Function(`return ${cleaned}`)();
    return String(result);
  } catch (e) {
    console.error('Failed to safeEvaluate equation:', equation, e);
    return '';
  }
}

function extractJson(text: string): Record<string, any> | null {
  try {
    return JSON.parse(text);
  } catch {
    const match = text.match(/\{[\s\S]*\}/);
    if (!match) return null;
    try {
      return JSON.parse(match[0]);
    } catch {
      return null;
    }
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const { activityTitle, activityDescription, equation } = body;

    console.log('Incoming math question request:', { activityTitle, activityDescription, equation });

    if (!activityTitle || !activityDescription || !equation) {
      return NextResponse.json(
        { error: 'Missing required fields: activityTitle, activityDescription, or equation' },
        { status: 400, headers: corsHeaders }
      );
    }

    // Parse equation, e.g. "4/2" -> num1 = 4, operator = "/", num2 = 2
    // Supports basic equations like A + B, A - B, A * B, A / B
    let parsedEquationText = `สมการคณิตศาสตร์: ${equation}`;
    const match = equation.replace(/\s+/g, '').match(/^(\d+)([\+\-\*\/])(\d+)$/);
    if (match) {
      const num1 = match[1];
      const op = match[2];
      const num2 = match[3];
      
      let opName = '';
      let opDesc = '';
      if (op === '+') {
        opName = 'การบวก (Addition)';
        opDesc = 'นำจำนวนมารวมกัน, ได้รับเพิ่มเข้ามา';
      } else if (op === '-') {
        opName = 'การลบ (Subtraction)';
        opDesc = 'การหักออก, การแบ่งให้คนอื่น, การกินหมดไป หรือการหาความต่าง';
      } else if (op === '*') {
        opName = 'การคูณ (Multiplication)';
        opDesc = 'การแบ่งเป็นกลุ่มๆ กลุ่มละเท่าๆ กัน หรือราคาต่อหน่วยคูณด้วยจำนวนชิ้น (เช่น "มีกล่องผลไม้ 2 กล่อง แต่ละกล่องมีส้มอยู่ 4 ลูก" หรือ "ส้มราคาลูกละ 4 บาท ซื้อ 2 ลูก") ห้ามแต่งเป็นบวกธรรมดาเด็ดขาด!';
      } else if (op === '/') {
        opName = 'การหาร (Division)';
        opDesc = 'การแบ่งปันหรือแบ่งสรรค์ผลไม้/สิ่งของ ให้คนอื่นในจำนวนเท่าๆ กัน (เช่น "มีส้มอยู่ 4 ลูก แบ่งให้เพื่อน 2 คนเท่าๆ กัน จะได้คนละกี่ลูก") ห้ามแต่งเป็นโจทย์การคูณหรือการบวกเด็ดขาด!';
      }
      
      parsedEquationText = `สมการคณิตศาสตร์ที่ป้อนเข้ามา: ${equation}
- ตัวเลขที่หนึ่ง: ${num1}
- ตัวเลขที่สอง: ${num2}
- เครื่องหมายคำนวณ: ${opName}
- แนวทางการแต่งโจทย์ของเครื่องหมายนี้: ${opDesc}`;
    }

    const systemPrompt = `คุณเป็น AI ผู้ช่วยครูคณิตศาสตร์สำหรับเด็กเล็ก (อายุ 4-9 ปี)
หน้าที่ของคุณคือเขียน "โจทย์ปัญหาคณิตศาสตร์แบบมีเนื้อเรื่อง" และ "คำใบ้ (Hint)" จากข้อมูลที่กำหนดให้

ข้อมูลที่คุณต้องใช้:
- ชื่อกิจกรรม: "${activityTitle}"
- รายละเอียดกิจกรรม: "${activityDescription}"
- ${parsedEquationText}

กฎเหล็กและข้อกำหนดที่สำคัญมาก (CRITICAL RULES):
1. [การนำตัวเลขและตัวดำเนินการไปใช้ในโจทย์อย่างถูกต้อง]:
   - คุณต้องนำ "ตัวเลขที่หนึ่ง" และ "ตัวเลขที่สอง" ไปเขียนลงในโจทย์คำถามด้วย โดยห้ามทิ้งหรือเปลี่ยนตัวเลขเด็ดขาด!
   - แต่งโจทย์ปัญหาให้ตรงตาม "เครื่องหมายคำนวณ" และ "แนวทางการแต่งโจทย์ของเครื่องหมายนี้" ข้างต้นอย่างเคร่งครัด!
     * ตัวอย่าง: หากเครื่องหมายคือการคูณ (*) เช่น "2 * 4" โจทย์ต้องเขียนให้มีลักษณะเป็นกลุ่มหรือหน่วยคูณ (เช่น ผลไม้ 2 กล่อง กล่องละ 4 ลูก)
     * ตัวอย่าง: หากเครื่องหมายคือการหาร (/) เช่น "4 / 2" โจทย์ต้องเขียนให้มีลักษณะแบ่งปันเท่าๆ กัน (เช่น มีส้ม 4 ลูก แบ่งให้เด็ก 2 คนเท่าๆ กัน) ห้ามให้สลับเครื่องหมายเด็ดขาด!
2. [ความสอดคล้องของตัวละคร]:
   - ใช้ชื่อตัวละครในเรื่องให้สอดคล้องกันตลอดทั้งข้อ ห้ามปะปนชื่อตัวละครหลายตัวจนเด็กสับสน (เช่น เลือกใช้ "น้องหมาป่า" หรือ "พี่หมี" เพียงตัวเดียวตลอดโจทย์ข้อนั้น)
3. [คำใบ้ (Hint) ที่ช่วยสอนเด็กจริงๆ]:
   - คำใบ้ต้องช่วยแนะแนวคิดการคิดเลขแบบเข้าใจง่าย โดยอธิบายความสัมพันธ์ของตัวเลขในโจทย์ เช่น:
     * ตัวอย่างคำใบ้ที่ดีสำหรับการคูณ: "ลองนำจำนวนกล่องผลไม้ทั้งหมด มาคูณกับจำนวนผลไม้ที่มีในแต่ละกล่องดูสิครับ"
     * ข้อห้ามเด็ดขาด: ห้ามบอกตัวเลขคำตอบสุดท้ายตรงๆ ในคำใบ้เด็ดขาด (เช่น ห้ามตอบว่า "จะได้ 8 ลูก" หรือ "ผลลัพธ์คือ 8")
4. [ความเข้ากันได้และภาษา]: แต่งเนื้อเรื่องให้สนุกสนาน สอดคล้องกับชื่อและรายละเอียดกิจกรรมที่กำหนดให้ ใช้ภาษาไทยที่ง่ายและเป็นมิตรกับเด็กปฐมวัยถึงประถมต้น (ป.1 - ป.3) อ่านแล้วเห็นภาพชัดเจน

กรุณาตอบกลับเฉพาะ JSON รูปแบบนี้เท่านั้น ห้ามมีคำอธิบายอื่นใดนอกเหนือจาก JSON:
{
  "question": "เนื้อเรื่องโจทย์ปัญหาภาษาไทยที่สนุกและมีตัวเลขจากสมการครบถ้วนตามกฎข้อที่ 1",
  "hint": "คำใบ้ภาษาไทยแนะวิธีคิดและอธิบายตัวเลขตามกฎข้อที่ 3 (ห้ามเฉลยผลลัพธ์สุดท้าย)"
}`;

    console.log('Sending prompt to Ollama with model Qwen2.5:3b...');
    const aiResponse = await callOllama(systemPrompt, true, 0.3);
    console.log('Raw Ollama Response:', aiResponse);
    
    // Parse the AI Response carefully
    const parsed = extractJson(aiResponse);
    if (!parsed) {
      console.error('Failed to extract valid JSON from response:', aiResponse);
      throw new Error('AI response did not contain valid JSON structure');
    }

    console.log('Parsed Ollama Response:', parsed);

    const calculatedAnswer = safeEvaluate(equation);

    return NextResponse.json(
      {
        success: true,
        question: parsed.question || '',
        solution: parsed.hint || parsed.solution || '',
        answer: calculatedAnswer,
      },
      { headers: corsHeaders }
    );
  } catch (error: any) {
    console.error('POST /api/activities/generate-math-question error:', error);
    return NextResponse.json(
      { error: 'Internal Server Error', details: error.message },
      { status: 500, headers: corsHeaders }
    );
  }
}
