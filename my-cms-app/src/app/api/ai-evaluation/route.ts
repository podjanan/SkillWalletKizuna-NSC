// src/app/api/ai-evaluation/route.ts

import { NextRequest, NextResponse } from 'next/server';

// ⚠️ CORS Headers: ตรวจสอบ Origin ของ Flutter App
const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, GET, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization, x-requested-with',
    'Access-Control-Max-Age': '86400',
};

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 🔒 Server-side semaphore for local Whisper (GPU = 1 slot)
// Groq mode is unaffected — cloud handles its own concurrency.
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
let _localBusy = false;
const _localWaiters: Array<() => void> = [];

function acquireLocalSlot(): Promise<void> {
    if (!_localBusy) {
        _localBusy = true;
        return Promise.resolve();
    }
    return new Promise((resolve) => _localWaiters.push(resolve));
}

function releaseLocalSlot(): void {
    const next = _localWaiters.shift();
    if (next) {
        next(); // hand slot to next waiter (stays busy)
    } else {
        _localBusy = false;
    }
}

// 🔧 Helper: ทำความสะอาดข้อความสำหรับเปรียบเทียบ
function cleanText(text: string): string {
    return text.toLowerCase().replace(/[^\w\s]/g, '').trim();
}

function levenshteinDistance(a: string, b: string): number {
    const matrix = [];
    for (let i = 0; i <= b.length; i++) matrix[i] = [i];
    for (let j = 0; j <= a.length; j++) matrix[0][j] = j;
    for (let i = 1; i <= b.length; i++) {
        for (let j = 1; j <= a.length; j++) {
            if (b.charAt(i - 1) === a.charAt(j - 1)) {
                matrix[i][j] = matrix[i - 1][j - 1];
            } else {
                matrix[i][j] = Math.min(
                    matrix[i - 1][j - 1] + 1, // substitution
                    Math.min(
                        matrix[i][j - 1] + 1, // insertion
                        matrix[i - 1][j] + 1  // deletion
                    )
                );
            }
        }
    }
    return matrix[b.length][a.length];
}

function getLevenshteinSimilarity(a: string, b: string): number {
    const distance = levenshteinDistance(a, b);
    const maxLength = Math.max(a.length, b.length);
    if (maxLength === 0) return 100;
    return Math.floor((1 - distance / maxLength) * 100);
}

function countSyllables(word: string): number {
    word = word.toLowerCase().replace(/[^a-z]/g, "");
    if (word.length === 0) return 0;
    if (word.length <= 3) return 1;
    if (word.endsWith('e')) word = word.slice(0, -1);
    const matches = word.match(/[aeiouy]+/g);
    return matches ? matches.length : 1;
}

function getFirstNSyllables(text: string, n: number): string {
    const words = text.split(/\s+/).filter(Boolean);
    const resultWords: string[] = [];
    let currentSyllableCount = 0;
    for (const word of words) {
        if (currentSyllableCount >= n) break;
        resultWords.push(word);
        currentSyllableCount += countSyllables(word);
    }
    return resultWords.join(" ");
}

// 🔧 Helper: คำนวณคะแนนความแม่นยำ
function calculateAccuracy(recognized: string, expected: string): number {
    const cleanExpected = cleanText(expected);
    const cleanRecognized = cleanText(recognized);

    if (cleanExpected.length === 0) return 100;
    if (cleanRecognized.length === 0) return 0;

    // Check if it's a single word (no spaces)
    const isSingleWord = !cleanExpected.includes(" ");
    if (isSingleWord) {
        // Slice the recognized text to match the syllable count of the expected word
        const expectedSyllables = countSyllables(cleanExpected);
        const slicedRecognized = cleanText(getFirstNSyllables(recognized, expectedSyllables));
        
        // If the sliced recognized word has no spaces, do Levenshtein character comparison
        if (!slicedRecognized.includes(" ") && slicedRecognized.length > 0) {
            return getLevenshteinSimilarity(slicedRecognized, cleanExpected);
        }
        
        // Fallback to word-level comparison
        return slicedRecognized === cleanExpected ? 100 : 0;
    }

    // Standard word-level accuracy for multi-word phrases/sentences
    const recognizedWords = cleanRecognized.split(/\s+/).filter(Boolean);
    const expectedWords = cleanExpected.split(/\s+/).filter(Boolean);

    const expectedCounts: Record<string, number> = {};
    for (const w of expectedWords) {
        expectedCounts[w] = (expectedCounts[w] || 0) + 1;
    }

    let matchCount = 0;
    for (const w of recognizedWords) {
        if (expectedCounts[w] && expectedCounts[w] > 0) {
            matchCount++;
            expectedCounts[w]--;
        }
    }

    return Math.min(Math.floor((matchCount / expectedWords.length) * 100), 100);
}

function detectWhisperLanguage(text: string): string | null {
    if (/[\u0E00-\u0E7F]/.test(text)) return "th";
    if (/[a-zA-Z]/.test(text)) return "en";
    return null;
}

/**
 * @swagger
 * /api/ai-evaluation:
 *   get:
 *     tags:
 *       - AI Evaluation
 *     summary: ตรวจสอบสถานะ AI Evaluation Endpoint
 *     description: |
 *       ใช้สำหรับตรวจสอบว่า API พร้อมใช้งานหรือไม่
 *       - แสดงเวอร์ชัน API
 *       - แสดงคำแนะนำการใช้งาน
 *     responses:
 *       200:
 *         description: API พร้อมใช้งาน
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 status:
 *                   type: string
 *                   description: สถานะของ API
 *                   example: "AI Evaluation Endpoint Ready"
 *                 version:
 *                   type: string
 *                   description: เวอร์ชันของ API
 *                   example: "1.0"
 *                 instructions:
 *                   type: string
 *                   description: คำแนะนำการใช้งาน
 *                   example: "Use POST method with audio file (multipart/form-data) and text field to trigger AI evaluation."
 *             example:
 *               status: "AI Evaluation Endpoint Ready"
 *               version: "1.0"
 *               instructions: "Use POST method with audio file (multipart/form-data) and text field to trigger AI evaluation."
 */
export async function GET(request: NextRequest) {
    return NextResponse.json(
        { 
            status: 'AI Evaluation Endpoint Ready',
            version: '1.0',
            instructions: 'Use POST method with audio file (multipart/form-data) and text field to trigger AI evaluation.',
        }, 
        { status: 200, headers: corsHeaders }
    );
}

/**
 * @swagger
 * /api/ai-evaluation:
 *   post:
 *     tags:
 *       - AI Evaluation
 *     summary: ประเมินไฟล์เสียงด้วย AI (Whisper)
 *     description: |
 *       รับไฟล์เสียงและข้อความต้นฉบับ จากนั้นประมวลผลด้วย Python Whisper Script
 *       - รองรับไฟล์เสียงหลายรูปแบบ (m4a, mp3, wav, etc.)
 *       - ใช้ OpenAI Whisper สำหรับแปลงเสียงเป็นข้อความ
 *       - เปรียบเทียบข้อความที่แปลงได้กับข้อความต้นฉบับ
 *       - คำนวณคะแนนความแม่นยำ
 *       
 *       **หมายเหตุ**: API นี้ต้องการ Python และ Whisper ติดตั้งในเซิร์ฟเวอร์
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             required:
 *               - file
 *               - text
 *             properties:
 *               file:
 *                 type: string
 *                 format: binary
 *                 description: |
 *                   ไฟล์เสียงที่ต้องการประเมิน
 *                   - รองรับ: m4a, mp3, wav, ogg, flac
 *                   - ขนาดไฟล์แนะนำ: ไม่เกิน 10MB
 *               text:
 *                 type: string
 *                 description: ข้อความต้นฉบับที่ถูกต้อง (สำหรับเปรียบเทียบ)
 *                 example: "สวัสดีครับ วันนี้อากาศดีมาก"
 *           encoding:
 *             file:
 *               contentType: audio/m4a, audio/mpeg, audio/wav, audio/ogg, audio/flac
 *     responses:
 *       200:
 *         description: ประเมินสำเร็จ
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 transcribed_text:
 *                   type: string
 *                   description: ข้อความที่แปลงได้จาก Whisper
 *                   example: "สวัสดีครับ วันนี้อากาศดีมาก"
 *                 original_text:
 *                   type: string
 *                   description: ข้อความต้นฉบับ
 *                   example: "สวัสดีครับ วันนี้อากาศดีมาก"
 *                 similarity_score:
 *                   type: number
 *                   format: float
 *                   description: คะแนนความแม่นยำ (0-100)
 *                   example: 95.5
 *                 is_correct:
 *                   type: boolean
 *                   description: ถูกต้องหรือไม่ (ตาม threshold)
 *                   example: true
 *                 word_error_rate:
 *                   type: number
 *                   format: float
 *                   description: อัตราข้อผิดพลาดของคำ (WER)
 *                   example: 0.05
 *                 processing_time:
 *                   type: number
 *                   format: float
 *                   description: เวลาที่ใช้ในการประมวลผล (วินาที)
 *                   example: 2.45
 *             examples:
 *               perfectMatch:
 *                 summary: ตัวอย่างการออกเสียงที่ถูกต้อง 100%
 *                 value:
 *                   transcribed_text: "สวัสดีครับ วันนี้อากาศดีมาก"
 *                   original_text: "สวัสดีครับ วันนี้อากาศดีมาก"
 *                   similarity_score: 100
 *                   is_correct: true
 *                   word_error_rate: 0
 *                   processing_time: 2.3
 *               goodMatch:
 *                 summary: ตัวอย่างการออกเสียงที่ดี (มีข้อผิดพลาดเล็กน้อย)
 *                 value:
 *                   transcribed_text: "สวัสดีครับ วันนี้อากาศดี"
 *                   original_text: "สวัสดีครับ วันนี้อากาศดีมาก"
 *                   similarity_score: 87.5
 *                   is_correct: true
 *                   word_error_rate: 0.125
 *                   processing_time: 2.1
 *               poorMatch:
 *                 summary: ตัวอย่างการออกเสียงที่ไม่ถูกต้อง
 *                 value:
 *                   transcribed_text: "สวัสดี วันนี้อากาศร้อน"
 *                   original_text: "สวัสดีครับ วันนี้อากาศดีมาก"
 *                   similarity_score: 45.2
 *                   is_correct: false
 *                   word_error_rate: 0.548
 *                   processing_time: 1.9
 *       400:
 *         description: Bad Request - ข้อมูลไม่ครบหรือไม่ถูกต้อง
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *             examples:
 *               missingFile:
 *                 summary: ไม่มีไฟล์เสียง
 *                 value:
 *                   error: "Missing audio file or original text."
 *               invalidFormat:
 *                 summary: รูปแบบไฟล์ไม่ถูกต้อง
 *                 value:
 *                   error: "Unsupported audio format. Please use m4a, mp3, wav, ogg, or flac."
 *       500:
 *         description: Internal Server Error - ข้อผิดพลาดในการประมวลผล
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *                 raw:
 *                   type: string
 *                   description: ข้อมูล output ดิบจาก Python (ถ้ามี)
 *             examples:
 *               pythonError:
 *                 summary: Python script error
 *                 value:
 *                   error: "Python exited with code 1"
 *               jsonParseError:
 *                 summary: ไม่สามารถ parse JSON ได้
 *                 value:
 *                   error: "Invalid JSON from whisper_eval.py"
 *                   raw: "Traceback (most recent call last)..."
 *               fileError:
 *                 summary: ข้อผิดพลาดในการจัดการไฟล์
 *                 value:
 *                   error: "Internal Server Error during AI process."
 */
export async function POST(request: NextRequest) {
    const errorCorsHeaders = {
        'Access-Control-Allow-Origin': corsHeaders['Access-Control-Allow-Origin'],
    };

    try {
        const formData = await request.formData();
        const file = formData.get("file") as File;
        const originalText = formData.get("text")?.toString() || "";

        if (!file || !originalText) {
            return NextResponse.json({ error: "Missing audio file or original text." }, { status: 400, headers: errorCorsHeaders });
        }

        // 🔀 เลือก mode: "local" = FastAPI Whisper บนเครื่อง, "groq" = Groq Cloud API
        const whisperMode = process.env.WHISPER_MODE || "groq";
        const whisperLanguage = detectWhisperLanguage(originalText);

        let recognizedText: string;
        let score: number;

        if (whisperMode === "local") {
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // 🏠 LOCAL MODE: ส่งไปยัง FastAPI (whisper_eval.py)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            const whisperUrl = process.env.WHISPER_LOCAL_URL || "http://localhost:8000";

            const localForm = new FormData();
            localForm.append("file", file, file.name || "audio.m4a");
            localForm.append("text", originalText);
            if (whisperLanguage) localForm.append("language", whisperLanguage);

            await acquireLocalSlot();
            let localResult: any;
            try {
                const localResponse = await fetch(`${whisperUrl}/evaluate`, {
                    method: "POST",
                    body: localForm,
                });

                if (!localResponse.ok) {
                    const errBody = await localResponse.text();
                    console.error("Local Whisper Error:", localResponse.status, errBody);
                    return NextResponse.json(
                        { error: `Local Whisper error (${localResponse.status}): ${errBody.substring(0, 200)}` },
                        { status: 500, headers: errorCorsHeaders }
                    );
                }

                localResult = await localResponse.json();
            } finally {
                releaseLocalSlot();
            }

            if (localResult.error) {
                return NextResponse.json(
                    { error: `Whisper processing error: ${localResult.error}` },
                    { status: 500, headers: errorCorsHeaders }
                );
            }

            recognizedText = localResult.text || "";
            score = localResult.score ?? 0;

        } else {
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            // ☁️ GROQ MODE: ส่งไปยัง Groq Whisper API (cloud)
            // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
            const groqApiKey = process.env.GROQ_API_KEY;
            if (!groqApiKey) {
                return NextResponse.json({ error: "GROQ_API_KEY not configured." }, { status: 500, headers: errorCorsHeaders });
            }

            const groqForm = new FormData();
            groqForm.append("file", file, file.name || "audio.m4a");
            groqForm.append("model", "whisper-large-v3");
            if (whisperLanguage) groqForm.append("language", whisperLanguage);
            groqForm.append("response_format", "json");
            if (originalText) {
                groqForm.append("prompt", originalText);
            }

            const groqResponse = await fetch("https://api.groq.com/openai/v1/audio/transcriptions", {
                method: "POST",
                headers: {
                    "Authorization": `Bearer ${groqApiKey}`,
                },
                body: groqForm,
            });

            if (!groqResponse.ok) {
                const errBody = await groqResponse.text();
                console.error("Groq API Error:", groqResponse.status, errBody);
                return NextResponse.json(
                    { error: `Groq API error (${groqResponse.status}): ${errBody.substring(0, 200)}` },
                    { status: 500, headers: errorCorsHeaders }
                );
            }

            const groqResult = await groqResponse.json();
            recognizedText = groqResult.text || "";
            score = calculateAccuracy(recognizedText, originalText);
        }

        // Force output to English characters only if expected language is English
        if (whisperLanguage === "en") {
            recognizedText = recognizedText.replace(/[^a-zA-Z\s'.,?-]/g, "").trim();
        }

        return NextResponse.json(
            { text: recognizedText, score },
            { headers: corsHeaders }
        );

    } catch (error: any) {
        console.error('AI Evaluation Process Error:', error);
        return NextResponse.json(
            { error: error.message || "Internal Server Error during AI process." },
            { status: 500, headers: errorCorsHeaders }
        );
    }
}

/**
 * @swagger
 * /api/ai-evaluation:
 *   options:
 *     tags:
 *       - AI Evaluation
 *     summary: CORS Preflight Request
 *     description: จัดการ CORS preflight request สำหรับ cross-origin requests
 *     responses:
 *       200:
 *         description: CORS headers returned
 *         headers:
 *           Access-Control-Allow-Origin:
 *             schema:
 *               type: string
 *               example: "*"
 *           Access-Control-Allow-Methods:
 *             schema:
 *               type: string
 *               example: "POST, GET, OPTIONS"
 *           Access-Control-Allow-Headers:
 *             schema:
 *               type: string
 *               example: "Content-Type, Authorization, x-requested-with"
 *           Access-Control-Max-Age:
 *             schema:
 *               type: string
 *               example: "86400"
 */
export async function OPTIONS(request: NextRequest) {
    return NextResponse.json({}, { headers: corsHeaders });
}
