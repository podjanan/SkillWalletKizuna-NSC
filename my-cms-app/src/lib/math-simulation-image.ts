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

const WIDTH = 1280;
const HEIGHT = 768;

const ITEM_TYPES = [
  { keys: ['ปลา', 'fish', 'กุ้ง', 'ปู'], type: 'fish', label: 'ปลา' },
  { keys: ['ขนม', 'โดนัท', 'เค้ก', 'donut', 'cake', 'snack', 'candy'], type: 'donut', label: 'ขนม' },
  { keys: ['ไข่', 'egg'], type: 'egg', label: 'ไข่' },
  { keys: ['แมว', 'cat', 'kitten'], type: 'cat', label: 'แมว' },
  { keys: ['หมา', 'สุนัข', 'dog', 'puppy'], type: 'dog', label: 'สุนัข' },
  { keys: ['แกะ', 'ลูกแกะ', 'sheep', 'lamb'], type: 'sheep', label: 'ลูกแกะ' },
  { keys: ['กระต่าย', 'rabbit', 'bunny'], type: 'rabbit', label: 'กระต่าย' },
  { keys: ['นก', 'bird'], type: 'bird', label: 'นก' },
  { keys: ['สตรอเบอร์รี่', 'สตรอเบอรี', 'strawberry'], type: 'strawberry', label: 'สตรอเบอร์รี่' },
  { keys: ['แอปเปิ้ล', 'apple'], type: 'apple', label: 'แอปเปิ้ล' },
  { keys: ['ส้ม', 'orange'], type: 'orange', label: 'ส้ม' },
  { keys: ['กล้วย', 'banana'], type: 'banana', label: 'กล้วย' },
  { keys: ['ลูกบอล', 'บอล', 'ball'], type: 'ball', label: 'ลูกบอล' },
  { keys: ['ดาว', 'star'], type: 'star', label: 'ดาว' },
  { keys: ['ดอกไม้', 'flower'], type: 'flower', label: 'ดอกไม้' },
  { keys: ['หนังสือ', 'สมุด', 'book'], type: 'book', label: 'หนังสือ' },
  { keys: ['ดินสอ', 'pencil'], type: 'pencil', label: 'ดินสอ' },
  { keys: ['คุกกี้', 'cookie'], type: 'cookie', label: 'คุกกี้' },
  { keys: ['ลูกโป่ง', 'balloon'], type: 'balloon', label: 'ลูกโป่ง' },
  { keys: ['รถ', 'รถยนต์', 'car'], type: 'car', label: 'รถยนต์' },
  { keys: ['นม', 'milk', 'กล่อง'], type: 'milk', label: 'นม' },
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

  const left = found[0] ?? { type: 'donut', label: 'ขนม' };
  const right = found[1] ?? found[0] ?? { type: 'donut', label: 'ขนม' };

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
  const cx = s / 2;
  const cy = s / 2;

  if (type === 'fish') {
    // 🐟 Detailed Goldfish / Fish
    return `<g transform="translate(${x} ${y})">
      <!-- Fish Body -->
      <path d="M${cx - s * 0.38} ${cy} Q${cx} ${cy - s * 0.35} ${cx + s * 0.28} ${cy} Q${cx} ${cy + s * 0.35} ${cx - s * 0.38} ${cy}" fill="#FF7043" stroke="#D84315" stroke-width="2.5"/>
      <!-- Fish Tail -->
      <path d="M${cx - s * 0.35} ${cy} L${cx - s * 0.48} ${cy - s * 0.22} L${cx - s * 0.42} ${cy} L${cx - s * 0.48} ${cy + s * 0.22} Z" fill="#FF5722" stroke="#BF360C" stroke-width="2"/>
      <!-- Fish Fin -->
      <path d="M${cx - s * 0.05} ${cy - s * 0.1} Q${cx + s * 0.05} ${cy - s * 0.26} ${cx - s * 0.15} ${cy - s * 0.25}" fill="#FF8A65" stroke="#D84315" stroke-width="2"/>
      <!-- Eye -->
      <circle cx="${cx + s * 0.14}" cy="${cy - s * 0.08}" r="${s * 0.08}" fill="#FFFFFF"/>
      <circle cx="${cx + s * 0.16}" cy="${cy - s * 0.08}" r="${s * 0.04}" fill="#212121"/>
      <!-- Smile & Bubbles -->
      <path d="M${cx + s * 0.22} ${cy + s * 0.06} Q${cx + s * 0.18} ${cy + s * 0.14} ${cx + s * 0.12} ${cy + s * 0.08}" fill="none" stroke="#BF360C" stroke-width="2" stroke-linecap="round"/>
      <circle cx="${cx + s * 0.36}" cy="${cy - s * 0.22}" r="${s * 0.04}" fill="#E0F7FA" opacity="0.8"/>
      <circle cx="${cx + s * 0.42}" cy="${cy - s * 0.34}" r="${s * 0.025}" fill="#E0F7FA" opacity="0.8"/>
    </g>`;
  }

  if (type === 'donut') {
    // 🍩 Realistic Glazed Donut with Sprinkles
    return `<g transform="translate(${x} ${y})">
      <circle cx="${cx}" cy="${cy}" r="${s * 0.42}" fill="#D97706" stroke="#92400E" stroke-width="2.5"/>
      <circle cx="${cx}" cy="${cy}" r="${s * 0.36}" fill="#F472B6"/>
      <circle cx="${cx}" cy="${cy}" r="${s * 0.14}" fill="#FFF8E7" stroke="#D97706" stroke-width="2"/>
      <line x1="${cx - s * 0.2}" y1="${cy - s * 0.15}" x2="${cx - s * 0.1}" y2="${cy - s * 0.22}" stroke="#FEF08A" stroke-width="3" stroke-linecap="round"/>
      <line x1="${cx + s * 0.1}" y1="${cy - s * 0.18}" x2="${cx + s * 0.22}" y2="${cy - s * 0.12}" stroke="#60A5FA" stroke-width="3" stroke-linecap="round"/>
      <line x1="${cx - s * 0.22}" y1="${cy + s * 0.1}" x2="${cx - s * 0.12}" y2="${cy + s * 0.2}" stroke="#4ADE80" stroke-width="3" stroke-linecap="round"/>
      <line x1="${cx + s * 0.12}" y1="${cy + s * 0.15}" x2="${cx + s * 0.22}" y2="${cy + s * 0.08}" stroke="#FACC15" stroke-width="3" stroke-linecap="round"/>
    </g>`;
  }

  if (type === 'cat') {
    // 🐱 Cute Cat Face
    return `<g transform="translate(${x} ${y})">
      <polygon points="${cx - s * 0.26},${cy - s * 0.12} ${cx - s * 0.34},${cy - s * 0.4} ${cx - s * 0.1},${cy - s * 0.26}" fill="#FFB74D" stroke="#E65100" stroke-width="2"/>
      <polygon points="${cx + s * 0.26},${cy - s * 0.12} ${cx + s * 0.34},${cy - s * 0.4} ${cx + s * 0.1},${cy - s * 0.26}" fill="#FFB74D" stroke="#E65100" stroke-width="2"/>
      <ellipse cx="${cx}" cy="${cy}" rx="${s * 0.34}" ry="${s * 0.3}" fill="#FFA726" stroke="#FB8C00" stroke-width="2.5"/>
      <circle cx="${cx - s * 0.12}" cy="${cy - s * 0.05}" r="${s * 0.06}" fill="#37474F"/>
      <circle cx="${cx + s * 0.12}" cy="${cy - s * 0.05}" r="${s * 0.06}" fill="#37474F"/>
      <polygon points="${cx},${cy + s * 0.04} ${cx - s * 0.03},${cy + s * 0.01} ${cx + s * 0.03},${cy + s * 0.01}" fill="#F48FB1"/>
      <line x1="${cx - s * 0.16}" y1="${cy + s * 0.06}" x2="${cx - s * 0.36}" y2="${cy + s * 0.02}" stroke="#78909C" stroke-width="1.5"/>
      <line x1="${cx + s * 0.16}" y1="${cy + s * 0.06}" x2="${cx + s * 0.36}" y2="${cy + s * 0.02}" stroke="#78909C" stroke-width="1.5"/>
    </g>`;
  }

  if (type === 'dog') {
    // 🐶 Cute Puppy Face
    return `<g transform="translate(${x} ${y})">
      <ellipse cx="${cx - s * 0.3}" cy="${cy}" rx="${s * 0.1}" ry="${s * 0.2}" fill="#8D6E63" transform="rotate(-15 ${cx - s * 0.3} ${cy})"/>
      <ellipse cx="${cx + s * 0.3}" cy="${cy}" rx="${s * 0.1}" ry="${s * 0.2}" fill="#8D6E63" transform="rotate(15 ${cx + s * 0.3} ${cy})"/>
      <circle cx="${cx}" cy="${cy}" r="${s * 0.32}" fill="#BCAAA4" stroke="#6D4C41" stroke-width="2.5"/>
      <ellipse cx="${cx}" cy="${cy + s * 0.1}" rx="${s * 0.16}" ry="${s * 0.12}" fill="#FFFFFF"/>
      <ellipse cx="${cx}" cy="${cy + s * 0.04}" rx="${s * 0.06}" ry="${s * 0.04}" fill="#3E2723"/>
      <circle cx="${cx - s * 0.1}" cy="${cy - s * 0.08}" r="${s * 0.05}" fill="#3E2723"/>
      <circle cx="${cx + s * 0.1}" cy="${cy - s * 0.08}" r="${s * 0.05}" fill="#3E2723"/>
    </g>`;
  }

  if (type === 'bird') {
    // 🐦 Songbird
    return `<g transform="translate(${x} ${y})">
      <ellipse cx="${cx}" cy="${cy}" rx="${s * 0.32}" ry="${s * 0.26}" fill="#29B6F6" stroke="#0288D1" stroke-width="2.5"/>
      <ellipse cx="${cx - s * 0.08}" cy="${cy + s * 0.04}" rx="${s * 0.16}" ry="${s * 0.1}" fill="#0288D1" transform="rotate(-20 ${cx - s * 0.08} ${cy + s * 0.04})"/>
      <circle cx="${cx + s * 0.16}" cy="${cy - s * 0.08}" r="${s * 0.06}" fill="#FFFFFF"/>
      <circle cx="${cx + s * 0.18}" cy="${cy - s * 0.08}" r="${s * 0.03}" fill="#212121"/>
      <polygon points="${cx + s * 0.3},${cy} ${cx + s * 0.44},${cy + s * 0.06} ${cx + s * 0.28},${cy + s * 0.12}" fill="#FFB74D"/>
    </g>`;
  }

  if (type === 'car') {
    // 🚗 Cute Red Car
    return `<g transform="translate(${x} ${y})">
      <rect x="${cx - s * 0.38}" y="${cy}" width="${s * 0.76}" height="${s * 0.24}" rx="${s * 0.08}" fill="#EF5350" stroke="#C62828" stroke-width="2.5"/>
      <path d="M${cx - s * 0.25} ${cy} L${cx - s * 0.14} ${cy - s * 0.2} L${cx + s * 0.14} ${cy - s * 0.2} L${cx + s * 0.25} ${cy} Z" fill="#E53935" stroke="#C62828" stroke-width="2"/>
      <polygon points="${cx - s * 0.22},${cy - s * 0.02} ${cx - s * 0.12},${cy - s * 0.16} ${cx - s * 0.02},${cy - s * 0.16} ${cx - s * 0.02},${cy - s * 0.02}" fill="#E0F7FA"/>
      <polygon points="${cx + s * 0.02},${cy - s * 0.02} ${cx + s * 0.02},${cy - s * 0.16} ${cx + s * 0.12},${cy - s * 0.16} ${cx + s * 0.22},${cy - s * 0.02}" fill="#E0F7FA"/>
      <circle cx="${cx - s * 0.22}" cy="${cy + s * 0.24}" r="${s * 0.09}" fill="#37474F"/>
      <circle cx="${cx - s * 0.22}" cy="${cy + s * 0.24}" r="${s * 0.04}" fill="#ECEFF1"/>
      <circle cx="${cx + s * 0.22}" cy="${cy + s * 0.24}" r="${s * 0.09}" fill="#37474F"/>
      <circle cx="${cx + s * 0.22}" cy="${cy + s * 0.24}" r="${s * 0.04}" fill="#ECEFF1"/>
    </g>`;
  }

  if (type === 'milk') {
    // 🥛 Milk Carton Box
    return `<g transform="translate(${x} ${y})">
      <rect x="${cx - s * 0.22}" y="${cy - s * 0.14}" width="${s * 0.44}" height="${s * 0.48}" rx="${s * 0.04}" fill="#E3F2FD" stroke="#1565C0" stroke-width="2"/>
      <polygon points="${cx - s * 0.22},${cy - s * 0.14} ${cx},${cy - s * 0.38} ${cx + s * 0.22},${cy - s * 0.14}" fill="#BBDEFB" stroke="#1565C0" stroke-width="2"/>
      <rect x="${cx - s * 0.14}" y="${cy - s * 0.02}" width="${s * 0.28}" height="${s * 0.22}" fill="#64B5F6"/>
      <text x="${cx}" y="${cy + s * 0.12}" font-size="${s * 0.14}" font-weight="bold" fill="#FFFFFF" text-anchor="middle">MILK</text>
    </g>`;
  }

  if (type === 'egg') {
    // 🥚 Cute Egg
    return `<g transform="translate(${x} ${y})">
      <ellipse cx="${cx}" cy="${s * 0.52}" rx="${s * 0.35}" ry="${s * 0.44}" fill="#FFF8E7" stroke="#E6C875" stroke-width="3"/>
      <ellipse cx="${cx - s * 0.1}" cy="${s * 0.35}" rx="${s * 0.12}" ry="${s * 0.18}" fill="#FFFFFF" opacity="0.8" transform="rotate(-15 ${cx - s * 0.1} ${s * 0.35})"/>
    </g>`;
  }

  if (type === 'sheep') {
    // 🐑 Fluffy Sheep
    return `<g transform="translate(${x} ${y})">
      <circle cx="${cx - s * 0.22}" cy="${cy - s * 0.1}" r="${s * 0.12}" fill="#F3F4F6"/>
      <circle cx="${cx + s * 0.22}" cy="${cy - s * 0.1}" r="${s * 0.12}" fill="#F3F4F6"/>
      <ellipse cx="${cx - s * 0.26}" cy="${cy - s * 0.05}" rx="${s * 0.08}" ry="${s * 0.04}" fill="#FCA5A5"/>
      <ellipse cx="${cx + s * 0.26}" cy="${cy - s * 0.05}" rx="${s * 0.08}" ry="${s * 0.04}" fill="#FCA5A5"/>
      <circle cx="${cx}" cy="${cy}" r="${s * 0.38}" fill="#FFFFFF" stroke="#E5E7EB" stroke-width="3"/>
      <circle cx="${cx - s * 0.12}" cy="${cy - s * 0.08}" r="${s * 0.05}" fill="#1F2937"/>
      <circle cx="${cx + s * 0.12}" cy="${cy - s * 0.08}" r="${s * 0.05}" fill="#1F2937"/>
      <path d="M${cx - s * 0.06} ${cy + s * 0.08} Q${cx} ${cy + s * 0.15} ${cx + s * 0.06} ${cy + s * 0.08}" fill="none" stroke="#F43F5E" stroke-width="2.5" stroke-linecap="round"/>
    </g>`;
  }

  if (type === 'rabbit') {
    // 🐰 Cute Rabbit
    return `<g transform="translate(${x} ${y})">
      <ellipse cx="${cx - s * 0.14}" cy="${cy - s * 0.28}" rx="${s * 0.08}" ry="${s * 0.22}" fill="#FFFFFF" stroke="#F472B6" stroke-width="2.5"/>
      <ellipse cx="${cx - s * 0.14}" cy="${cy - s * 0.26}" rx="${s * 0.04}" ry="${s * 0.16}" fill="#FBCFE8"/>
      <ellipse cx="${cx + s * 0.14}" cy="${cy - s * 0.28}" rx="${s * 0.08}" ry="${s * 0.22}" fill="#FFFFFF" stroke="#F472B6" stroke-width="2.5"/>
      <ellipse cx="${cx + s * 0.14}" cy="${cy - s * 0.26}" rx="${s * 0.04}" ry="${s * 0.16}" fill="#FBCFE8"/>
      <circle cx="${cx}" cy="${cy + s * 0.06}" r="${s * 0.32}" fill="#FFFFFF" stroke="#E5E7EB" stroke-width="2.5"/>
      <circle cx="${cx - s * 0.1}" cy="${cy}" r="${s * 0.04}" fill="#1F2937"/>
      <circle cx="${cx + s * 0.1}" cy="${cy}" r="${s * 0.04}" fill="#1F2937"/>
      <polygon points="${cx},${cy + s * 0.08} ${cx - s * 0.04},${cy + s * 0.04} ${cx + s * 0.04},${cy + s * 0.04}" fill="#F472B6"/>
    </g>`;
  }

  if (type === 'apple') {
    // 🍎 Apple
    return `<g transform="translate(${x} ${y})">
      <circle cx="${cx}" cy="${s * 0.54}" r="${s * 0.36}" fill="#EF4444" stroke="#991B1B" stroke-width="2.5"/>
      <path d="M${cx} ${s * 0.22} Q${cx + s * 0.08} ${s * 0.05} ${cx + s * 0.16} ${s * 0.04}" fill="none" stroke="#78350F" stroke-width="3"/>
      <ellipse cx="${cx + s * 0.18}" cy="${s * 0.16}" rx="${s * 0.14}" ry="${s * 0.07}" fill="#4ADE80" transform="rotate(-20 ${cx + s * 0.18} ${s * 0.16})"/>
      <circle cx="${cx - s * 0.12}" cy="${s * 0.44}" r="${s * 0.06}" fill="#FCA5A5" opacity="0.8"/>
    </g>`;
  }

  if (type === 'orange') {
    // 🍊 Orange
    return `<g transform="translate(${x} ${y})">
      <circle cx="${cx}" cy="${s * 0.54}" r="${s * 0.36}" fill="#FB923C" stroke="#C2410C" stroke-width="2.5"/>
      <ellipse cx="${cx + s * 0.14}" cy="${s * 0.18}" rx="${s * 0.14}" ry="${s * 0.07}" fill="#65A30D" transform="rotate(20 ${cx + s * 0.14} ${s * 0.18})"/>
      <circle cx="${cx - s * 0.1}" cy="${s * 0.44}" r="${s * 0.06}" fill="#FFEDD5" opacity="0.8"/>
    </g>`;
  }

  if (type === 'strawberry') {
    // 🍓 Strawberry
    return `<g transform="translate(${x} ${y})">
      <path d="M${cx - s * 0.32} ${cy - s * 0.1} Q${cx} ${cy + s * 0.48} ${cx + s * 0.32} ${cy - s * 0.1} Q${cx} ${cy - s * 0.38} ${cx - s * 0.32} ${cy - s * 0.1} Z" fill="#F43F5E" stroke="#BE123C" stroke-width="2.5"/>
      <path d="M${cx - s * 0.25} ${cy - s * 0.2} Q${cx} ${cy - s * 0.05} ${cx + s * 0.25} ${cy - s * 0.2}" fill="#4ADE80" stroke="#15803D" stroke-width="2"/>
      <circle cx="${cx - s * 0.1}" cy="${cy + s * 0.1}" r="2" fill="#FEF08A"/>
      <circle cx="${cx + s * 0.1}" cy="${cy + s * 0.1}" r="2" fill="#FEF08A"/>
      <circle cx="${cx}" cy="${cy + s * 0.25}" r="2" fill="#FEF08A"/>
    </g>`;
  }

  if (type === 'pencil') {
    // ✏️ Pencil
    return `<g transform="translate(${x} ${y})">
      <rect x="${cx - s * 0.12}" y="${cy - s * 0.32}" width="${s * 0.24}" height="${s * 0.48}" fill="#FBC02D" stroke="#F57F17" stroke-width="2"/>
      <polygon points="${cx - s * 0.12},${cy + s * 0.16} ${cx + s * 0.12},${cy + s * 0.16} ${cx},${cy + s * 0.4}" fill="#FFE082"/>
      <polygon points="${cx - s * 0.04},${cy + s * 0.28} ${cx + s * 0.04},${cy + s * 0.28} ${cx},${cy + s * 0.4}" fill="#37474F"/>
      <rect x="${cx - s * 0.12}" y="${cy - s * 0.42}" width="${s * 0.24}" height="${s * 0.1}" rx="${s * 0.04}" fill="#F48FB1"/>
    </g>`;
  }

  if (type === 'cookie') {
    // 🍪 Cookie
    return `<g transform="translate(${x} ${y})">
      <circle cx="${cx}" cy="${cy}" r="${s * 0.36}" fill="#D7CCC8" stroke="#8D6E63" stroke-width="2.5"/>
      <circle cx="${cx - s * 0.14}" cy="${cy - s * 0.12}" r="${s * 0.05}" fill="#4E342E"/>
      <circle cx="${cx + s * 0.12}" cy="${cy - s * 0.08}" r="${s * 0.06}" fill="#4E342E"/>
      <circle cx="${cx - s * 0.04}" cy="${cy + s * 0.14}" r="${s * 0.055}" fill="#4E342E"/>
    </g>`;
  }

  if (type === 'balloon') {
    // 🎈 Balloon
    return `<g transform="translate(${x} ${y})">
      <ellipse cx="${cx}" cy="${s * 0.42}" rx="${s * 0.32}" ry="${s * 0.38}" fill="#F43F5E" stroke="#9F1239" stroke-width="2.5"/>
      <polygon points="${cx},${s * 0.78} ${cx - s * 0.06},${s * 0.84} ${cx + s * 0.06},${s * 0.84}" fill="#F43F5E"/>
      <path d="M${cx} ${s * 0.84} Q${cx - s * 0.08} ${s * 0.92} ${cx} ${s * 0.98}" stroke="#9F1239" stroke-width="2" fill="none"/>
    </g>`;
  }

  // Fallback cute colored circle counter
  const colors: Record<string, string> = {
    ball: '#A78BFA', flower: '#F472B6', star: '#FACC15',
  };
  return `<g transform="translate(${x} ${y})">
    <circle cx="${cx}" cy="${cy}" r="${s * 0.36}" fill="${colors[type] ?? '#60A5FA'}" stroke="#1E40AF" stroke-width="2.5"/>
    <circle cx="${cx - s * 0.1}" cy="${cy - s * 0.1}" r="${s * 0.08}" fill="#FFFFFF" opacity="0.7"/>
  </g>`;
}

function objectGrid(type: string, count: number, x: number, y: number, width: number, height: number) {
  if (count <= 0) return '';

  const tenFramesCount = Math.ceil(count / 10);
  let result = '';

  const frameWidth = width;
  const frameHeight = tenFramesCount === 1 ? height : (height - (tenFramesCount - 1) * 16) / tenFramesCount;

  for (let f = 0; f < tenFramesCount; f++) {
    const frameY = y + f * (frameHeight + 16);
    const countInFrame = Math.min(10, count - f * 10);
    const rows = Math.ceil(countInFrame / 5);

    // Draw Ten-Frame container background
    result += `<rect x="${x}" y="${frameY}" width="${frameWidth}" height="${frameHeight}" rx="18" fill="#F8FAFC" stroke="#E2E8F0" stroke-width="3" stroke-dasharray="6 4"/>`;

    const cellW = frameWidth / 5;
    const cellH = frameHeight / Math.max(1, rows);
    const size = Math.max(22, Math.min(58, cellW * 0.78, cellH * 0.82));

    for (let i = 0; i < countInFrame; i++) {
      const r = Math.floor(i / 5);
      const c = i % 5;
      const posX = x + c * cellW + (cellW - size) / 2;
      const posY = frameY + r * cellH + (cellH - size) / 2;
      result += objectShape(type, posX, posY, size);
    }
  }

  return result;
}

function overlaySvg(_question: string, visual: MathVisualData) {
  return Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${WIDTH}" height="${HEIGHT}">
    <defs>
      <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0%" stop-color="#EFF6FF"/>
        <stop offset="50%" stop-color="#F0FDF4"/>
        <stop offset="100%" stop-color="#FAF5FF"/>
      </linearGradient>
    </defs>
    <rect width="${WIDTH}" height="${HEIGHT}" fill="url(#bg)"/>
    <circle cx="150" cy="100" r="80" fill="#FEF08A" opacity="0.3"/>
    <circle cx="1150" cy="650" r="120" fill="#FBCFE8" opacity="0.3"/>
    <style>
      text { font-family: 'Noto Sans Thai', 'Chakra Petch', 'Tahoma', sans-serif; }
    </style>
    
    <!-- Left Card Container -->
    <rect x="50" y="50" width="550" height="668" rx="36" fill="#FFFFFF" fill-opacity="0.88" stroke="#F472B6" stroke-width="6"/>
    <text x="325" y="95" font-size="28" font-weight="700" text-anchor="middle" fill="#DB2777">${visual.leftCount} ${visual.leftLabel}</text>
    ${objectGrid(visual.leftItem, visual.leftCount, 75, 115, 500, 578)}

    <!-- Right Card Container -->
    <rect x="680" y="50" width="550" height="668" rx="36" fill="#FFFFFF" fill-opacity="0.88" stroke="#60A5FA" stroke-width="6"/>
    <text x="955" y="95" font-size="28" font-weight="700" text-anchor="middle" fill="#2563EB">${visual.rightCount} ${visual.rightLabel}</text>
    ${objectGrid(visual.rightItem, visual.rightCount, 705, 115, 500, 578)}

    <!-- Center Math Operator Circle -->
    <circle cx="640" cy="384" r="52" fill="#8B5CF6" stroke="#FFFFFF" stroke-width="6"/>
    <text x="640" y="403" font-size="56" font-weight="800" text-anchor="middle" fill="#FFFFFF">${escapeXml(visual.operator)}</text>
  </svg>`);
}

/**
 * Generate AI Image via Pollinations AI (100% reliable free AI image generator API)
 * Or Gemini API if configured.
 */
async function generateAiStorybookImage(prompt: string): Promise<{ buffer: Buffer; provider: string } | null> {
  // 1. Try Pollinations AI first (Fast, reliable 2D/3D cartoon storybook generator)
  try {
    const seed = Math.floor(Math.random() * 1000000);
    const pollinationsUrl = `https://image.pollinations.ai/prompt/${encodeURIComponent(prompt)}?width=1280&height=768&nologo=true&seed=${seed}`;
    const controller = new AbortController();
    const timeoutId = setTimeout(() => controller.abort(), 18000);

    const res = await fetch(pollinationsUrl, {
      method: 'GET',
      signal: controller.signal,
    });
    clearTimeout(timeoutId);

    if (res.ok) {
      const arrayBuf = await res.arrayBuffer();
      if (arrayBuf.byteLength > 2000) {
        return {
          buffer: Buffer.from(arrayBuf),
          provider: 'pollinations-ai',
        };
      }
    }
  } catch (err) {
    console.warn('Pollinations AI image generation attempt failed:', err);
  }

  // 2. Try Gemini API if key is set
  const apiKey = process.env.GEMINI_API_KEY;
  if (apiKey) {
    try {
      const model = process.env.GEMINI_MODEL || 'gemini-2.0-flash-exp';
      const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 20000);

      const res = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        signal: controller.signal,
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            responseModalities: ['IMAGE', 'TEXT'],
          },
        }),
      });
      clearTimeout(timeoutId);

      if (res.ok) {
        const data = await res.json() as {
          candidates?: Array<{
            content?: {
              parts?: Array<{
                inlineData?: { data?: string };
              }>;
            };
          }>;
        };

        const parts = data.candidates?.[0]?.content?.parts ?? [];
        for (const part of parts) {
          if (part.inlineData?.data) {
            return {
              buffer: Buffer.from(part.inlineData.data, 'base64'),
              provider: `gemini (${model})`,
            };
          }
        }
      }
    } catch (err) {
      console.warn('Gemini API image gen failed:', err);
    }
  }

  return null;
}

export async function createMathSimulationImage(question: string, equation?: string) {
  const visualData = extractMathVisualData(question, equation);

  const itemEnglishNames: Record<string, string> = {
    fish: 'orange goldfish swimming',
    donut: 'glazed pink donuts with sprinkles',
    egg: 'eggs',
    sheep: 'fluffy baby sheep',
    rabbit: 'cute white bunnies',
    cat: 'cute kittens',
    dog: 'cute puppies',
    bird: 'little songbirds',
    strawberry: 'fresh red strawberries',
    apple: 'red apples',
    orange: 'orange fruits',
    banana: 'yellow bananas',
    ball: 'toy balls',
    star: 'golden stars',
    flower: 'colorful flowers',
    book: 'storybook books',
    pencil: 'yellow pencils',
    cookie: 'chocolate chip cookies',
    balloon: 'party balloons',
    car: 'toy cars',
    milk: 'milk cartons',
  };

  const itemName = itemEnglishNames[visualData.leftItem] ?? 'items';

  const prompt = `A vivid cute 2D children storybook vector illustration for a math question: on the left side ${visualData.leftCount} realistic ${itemName}, on the right side ${visualData.rightCount} realistic ${itemName}, separated cleanly, bright pastel colors, high quality, 8k resolution`;

  // 1. Try AI Storybook generation
  const aiResult = await generateAiStorybookImage(prompt);
  if (aiResult) {
    return {
      buffer: aiResult.buffer,
      provider: aiResult.provider,
      visualPrompt: prompt,
      visualData,
    };
  }

  // 2. High-Definition SVG Composite Fallback (Guaranteed to succeed and render realistic items!)
  const svgBuffer = overlaySvg(question, visualData);
  const pngBuffer = await sharp(svgBuffer).png().toBuffer();

  return {
    buffer: pngBuffer,
    provider: 'local-svg-hd',
    visualPrompt: prompt,
    visualData,
  };
}

