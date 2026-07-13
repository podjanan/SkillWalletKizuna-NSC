import sharp from 'sharp';

export type MathVisualData = {
  leftCount: number;
  rightCount: number;
  operator: string;
  leftItem: string;
  rightItem: string;
  leftLabel: string;
  rightLabel: string;
};

type ComfyImage = { buffer: Buffer; prompt: string };

const WIDTH = 1280;
const HEIGHT = 768;

const ITEM_TYPES = [
  { keys: ['แอปเปิ้ล', 'apple'], type: 'apple', label: 'แอปเปิ้ล' },
  { keys: ['ส้ม', 'orange'], type: 'orange', label: 'ส้ม' },
  { keys: ['กล้วย', 'banana'], type: 'banana', label: 'กล้วย' },
  { keys: ['ลูกบอล', 'ball'], type: 'ball', label: 'ลูกบอล' },
  { keys: ['ดาว', 'star'], type: 'star', label: 'ดาว' },
  { keys: ['ดอกไม้', 'flower'], type: 'flower', label: 'ดอกไม้' },
  { keys: ['หนังสือ', 'book'], type: 'book', label: 'หนังสือ' },
  { keys: ['ดินสอ', 'pencil'], type: 'pencil', label: 'ดินสอ' },
  { keys: ['คุกกี้', 'cookie'], type: 'cookie', label: 'คุกกี้' },
  { keys: ['ขนม', 'candy'], type: 'candy', label: 'ขนม' },
  { keys: ['ปลา', 'fish'], type: 'fish', label: 'ปลา' },
];

function escapeXml(value: string) {
  return value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
}

function normalizeOperator(value: string) {
  if (value === '*' || value.toLowerCase() === 'x') return '×';
  if (value === '/') return '÷';
  return value;
}

export function extractMathVisualData(question: string, equation?: string): MathVisualData {
  const source = `${equation ?? ''} ${question}`;
  const match = source.match(/(-?\d+)\s*([+\-*xX×÷/])\s*(-?\d+)/);
  const numbers = Array.from(question.matchAll(/-?\d+/g), (item) => Number(item[0]));
  const leftCount = Math.max(0, Math.min(40, Number(match?.[1] ?? numbers[0] ?? 1)));
  const rightCount = Math.max(0, Math.min(40, Number(match?.[3] ?? numbers[1] ?? 1)));
  const operator = normalizeOperator(match?.[2] ?? '+');

  const lower = question.toLowerCase();
  const found = ITEM_TYPES
    .map((item) => ({
      item,
      index: Math.min(...item.keys.map((key) => {
        const position = lower.indexOf(key);
        return position < 0 ? Number.POSITIVE_INFINITY : position;
      })),
    }))
    .filter(({ index }) => Number.isFinite(index))
    .sort((a, b) => a.index - b.index)
    .map(({ item }) => item);
  const left = found[0] ?? { type: 'counter-a', label: 'กลุ่มที่ 1' };
  const right = found[1] ?? found[0] ?? { type: 'counter-b', label: 'กลุ่มที่ 2' };

  return {
    leftCount,
    rightCount,
    operator,
    leftItem: left.type,
    rightItem: right.type,
    leftLabel: left.label,
    rightLabel: right.label,
  };
}

function objectShape(type: string, x: number, y: number, size: number) {
  const s = size;
  if (type === 'apple') {
    return `<g transform="translate(${x} ${y})"><circle cx="${s / 2}" cy="${s * .56}" r="${s * .35}" fill="#ef4444" stroke="#9f1239" stroke-width="3"/><path d="M${s * .5} ${s * .25}q0-${s * .22} ${s * .12}-${s * .25}" fill="none" stroke="#713f12" stroke-width="4"/><ellipse cx="${s * .69}" cy="${s * .18}" rx="${s * .16}" ry="${s * .08}" fill="#65a30d" transform="rotate(-25 ${s * .69} ${s * .18})"/><circle cx="${s * .38}" cy="${s * .45}" r="${s * .06}" fill="#fecaca"/></g>`;
  }
  if (type === 'orange') {
    return `<g transform="translate(${x} ${y})"><circle cx="${s / 2}" cy="${s * .55}" r="${s * .36}" fill="#fb923c" stroke="#c2410c" stroke-width="3"/><ellipse cx="${s * .62}" cy="${s * .19}" rx="${s * .16}" ry="${s * .08}" fill="#4d7c0f" transform="rotate(20 ${s * .62} ${s * .19})"/><circle cx="${s * .38}" cy="${s * .43}" r="${s * .06}" fill="#fed7aa"/></g>`;
  }
  if (type === 'banana') {
    return `<g transform="translate(${x} ${y})"><path d="M${s * .18} ${s * .2}q${s * .08} ${s * .55} ${s * .67} ${s * .58}q-${s * .18} ${s * .18}-${s * .42} ${s * .13}q-${s * .42}-${s * .08}-${s * .38}-${s * .66}z" fill="#fde047" stroke="#ca8a04" stroke-width="3"/></g>`;
  }
  if (type === 'book') {
    return `<g transform="translate(${x} ${y})"><rect x="${s * .12}" y="${s * .18}" width="${s * .72}" height="${s * .62}" rx="6" fill="#60a5fa" stroke="#1d4ed8" stroke-width="3"/><path d="M${s * .48} ${s * .2}v${s * .58}" stroke="white" stroke-width="3"/></g>`;
  }
  if (type === 'star') {
    return `<g transform="translate(${x} ${y})"><path d="M${s * .5} ${s * .08}l${s * .13} ${s * .28} ${s * .31} ${s * .03}-${s * .23} ${s * .21} ${s * .08} ${s * .31}-${s * .29}-${s * .16}-${s * .28} ${s * .16} ${s * .07}-${s * .31}-${s * .22}-${s * .21} ${s * .3}-.03z" fill="#facc15" stroke="#d97706" stroke-width="3"/></g>`;
  }
  const colors: Record<string, string> = {
    ball: '#a78bfa', flower: '#f472b6', pencil: '#facc15', cookie: '#d97706',
    candy: '#2dd4bf', fish: '#38bdf8', 'counter-a': '#fb7185', 'counter-b': '#60a5fa',
  };
  return `<g transform="translate(${x} ${y})"><circle cx="${s / 2}" cy="${s / 2}" r="${s * .34}" fill="${colors[type] ?? '#a78bfa'}" stroke="#4c1d95" stroke-width="3"/><circle cx="${s * .39}" cy="${s * .4}" r="${s * .07}" fill="white" opacity=".7"/></g>`;
}

function objectGrid(type: string, count: number, x: number, y: number, width: number, height: number) {
  if (count <= 0) return '';
  const columns = count <= 5 ? count : count <= 15 ? 5 : count <= 24 ? 6 : 8;
  const rows = Math.ceil(count / columns);
  const cellW = width / columns;
  const cellH = height / rows;
  const size = Math.max(20, Math.min(62, cellW * .82, cellH * .86));
  let result = '';
  for (let i = 0; i < count; i++) {
    const row = Math.floor(i / columns);
    const col = i % columns;
    const rowCount = Math.min(columns, count - row * columns);
    const rowOffset = (width - rowCount * cellW) / 2;
    result += objectShape(type, x + rowOffset + col * cellW + (cellW - size) / 2, y + row * cellH + (cellH - size) / 2, size);
  }
  return result;
}

function fallbackBackgroundSvg() {
  return Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${WIDTH}" height="${HEIGHT}">
    <defs><linearGradient id="sky" x1="0" y1="0" x2="1" y2="1"><stop stop-color="#d9f99d"/><stop offset=".48" stop-color="#bae6fd"/><stop offset="1" stop-color="#fbcfe8"/></linearGradient></defs>
    <rect width="1280" height="768" fill="url(#sky)"/><circle cx="1080" cy="110" r="72" fill="#fef3c7" opacity=".9"/>
    <path d="M0 420Q160 300 310 420T620 410T930 420T1280 390V768H0Z" fill="#86efac"/>
    <path d="M0 510Q220 400 420 520T820 500T1280 490V768H0Z" fill="#4ade80" opacity=".72"/>
    <g opacity=".9"><rect x="90" y="150" width="350" height="155" rx="28" fill="#fb7185"/><path d="M70 200h390l-35 80H105z" fill="#fef3c7"/><rect x="135" y="282" width="245" height="145" fill="#fed7aa"/><path d="M110 170h310" stroke="#fff" stroke-width="18" stroke-dasharray="44 18"/></g>
    <g transform="translate(1030 210)"><circle cx="80" cy="80" r="72" fill="#dbeafe" stroke="#64748b" stroke-width="6"/><circle cx="25" cy="45" r="34" fill="#fda4af"/><circle cx="135" cy="45" r="34" fill="#fda4af"/><circle cx="60" cy="72" r="7"/><circle cx="104" cy="72" r="7"/><path d="M80 90q-15 55 28 70" fill="none" stroke="#64748b" stroke-width="14" stroke-linecap="round"/><rect x="25" y="142" width="115" height="150" rx="48" fill="#bfdbfe" stroke="#64748b" stroke-width="6"/></g>
    <circle cx="95" cy="85" r="5" fill="#fff"/><circle cx="520" cy="115" r="6" fill="#fff"/><circle cx="840" cy="75" r="5" fill="#fff"/>
  </svg>`);
}

function overlaySvg(question: string, visual: MathVisualData) {
  const safeQuestion = escapeXml(question.length > 82 ? `${question.slice(0, 79)}…` : question);
  const leftLabel = escapeXml(visual.leftLabel);
  const rightLabel = escapeXml(visual.rightLabel);
  return Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${WIDTH}" height="${HEIGHT}">
    <style>text{font-family:'Noto Sans Thai','Tahoma','Arial',sans-serif}</style>
    <rect x="70" y="28" width="1140" height="118" rx="30" fill="#fff" fill-opacity=".94" stroke="#7c3aed" stroke-width="6"/>
    <text x="640" y="74" font-size="29" font-weight="700" text-anchor="middle" fill="#3b0764">${safeQuestion}</text>
    <text x="640" y="124" font-size="42" font-weight="800" text-anchor="middle" fill="#6d28d9">${visual.leftCount} ${escapeXml(visual.operator)} ${visual.rightCount} = ?</text>
    <rect x="55" y="185" width="555" height="525" rx="38" fill="#fff" fill-opacity=".93" stroke="#fb7185" stroke-width="7"/>
    <rect x="670" y="185" width="555" height="525" rx="38" fill="#fff" fill-opacity=".93" stroke="#60a5fa" stroke-width="7"/>
    <text x="332" y="240" font-size="30" font-weight="700" text-anchor="middle" fill="#9f1239">${leftLabel} ${visual.leftCount}</text>
    <text x="947" y="240" font-size="30" font-weight="700" text-anchor="middle" fill="#1e40af">${rightLabel} ${visual.rightCount}</text>
    ${objectGrid(visual.leftItem, visual.leftCount, 90, 265, 485, 390)}
    ${objectGrid(visual.rightItem, visual.rightCount, 705, 265, 485, 390)}
    <circle cx="640" cy="458" r="48" fill="#7c3aed" stroke="#fff" stroke-width="7"/><text x="640" y="475" font-size="50" font-weight="800" text-anchor="middle" fill="#fff">${escapeXml(visual.operator)}</text>
  </svg>`);
}

function comfyWorkflow(prompt: string, seed: number) {
  const checkpoint = process.env.COMFYUI_CHECKPOINT || 'sd_xl_base_1.0.safetensors';
  return {
    '3': { class_type: 'KSampler', inputs: { seed, steps: 24, cfg: 6.5, sampler_name: 'dpmpp_2m', scheduler: 'karras', denoise: 1, model: ['4', 0], positive: ['6', 0], negative: ['7', 0], latent_image: ['5', 0] } },
    '4': { class_type: 'CheckpointLoaderSimple', inputs: { ckpt_name: checkpoint } },
    '5': { class_type: 'EmptyLatentImage', inputs: { width: WIDTH, height: HEIGHT, batch_size: 1 } },
    '6': { class_type: 'CLIPTextEncode', inputs: { text: prompt, clip: ['4', 1] } },
    '7': { class_type: 'CLIPTextEncode', inputs: { text: 'text, letters, numbers, fruit, objects on foreground, watermark, blurry, photorealistic', clip: ['4', 1] } },
    '8': { class_type: 'VAEDecode', inputs: { samples: ['3', 0], vae: ['4', 2] } },
    '9': { class_type: 'SaveImage', inputs: { filename_prefix: 'math-simulation', images: ['8', 0] } },
  };
}

async function fetchWithTimeout(url: string, init: RequestInit, timeoutMs: number) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, { ...init, signal: controller.signal });
  } finally {
    clearTimeout(timeout);
  }
}

async function tryComfyBackground(question: string, seed: number): Promise<ComfyImage | null> {
  const baseUrl = process.env.COMFYUI_URL?.replace(/\/$/, '');
  if (!baseUrl) return null;
  const prompt = `cute 2D children's storybook illustration, magical outdoor market, friendly animal teacher and child, warm pastel colors, bold clean outlines, two empty display areas in the foreground, uncluttered center, no text, no numbers, no fruit, 16:9, inspired by this math story: ${question}`;
  try {
    const health = await fetchWithTimeout(`${baseUrl}/system_stats`, {}, 1800);
    if (!health.ok) return null;
    const queued = await fetchWithTimeout(`${baseUrl}/prompt`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ prompt: comfyWorkflow(prompt, seed) }),
    }, 5000);
    if (!queued.ok) throw new Error(`ComfyUI queue returned ${queued.status}`);
    const { prompt_id: promptId } = await queued.json() as { prompt_id?: string };
    if (!promptId) throw new Error('ComfyUI did not return prompt_id');

    const deadline = Date.now() + Number(process.env.COMFYUI_TIMEOUT_MS || 180000);
    while (Date.now() < deadline) {
      await new Promise((resolve) => setTimeout(resolve, 1000));
      const historyResponse = await fetchWithTimeout(`${baseUrl}/history/${promptId}`, {}, 5000);
      if (!historyResponse.ok) continue;
      const history = await historyResponse.json() as Record<string, { outputs?: Record<string, { images?: Array<{ filename: string; subfolder?: string; type?: string }> }> }>;
      const image = history[promptId]?.outputs?.['9']?.images?.[0];
      if (!image) continue;
      const query = new URLSearchParams({ filename: image.filename, subfolder: image.subfolder ?? '', type: image.type ?? 'output' });
      const imageResponse = await fetchWithTimeout(`${baseUrl}/view?${query}`, {}, 15000);
      if (!imageResponse.ok) throw new Error(`ComfyUI image returned ${imageResponse.status}`);
      return { buffer: Buffer.from(await imageResponse.arrayBuffer()), prompt };
    }
    throw new Error('ComfyUI generation timed out');
  } catch (error) {
    console.warn('ComfyUI unavailable; using deterministic local illustration:', error);
    return null;
  }
}

export async function createMathSimulationImage(question: string, equation?: string) {
  const visualData = extractMathVisualData(question, equation);
  const seed = Math.abs(Array.from(question).reduce((sum, char) => ((sum * 31) + char.charCodeAt(0)) | 0, 17));
  const comfy = await tryComfyBackground(question, seed);
  const overlay = overlaySvg(question, visualData);

  const image = comfy
    ? sharp(comfy.buffer).resize(WIDTH, HEIGHT, { fit: 'cover' }).composite([{ input: overlay }])
    : sharp(fallbackBackgroundSvg()).composite([{ input: overlay }]);

  return {
    buffer: await image.png({ compressionLevel: 8 }).toBuffer(),
    provider: comfy ? 'comfyui' : 'local-svg',
    visualPrompt: comfy?.prompt ?? 'Deterministic local storybook illustration',
    visualData,
  };
}
