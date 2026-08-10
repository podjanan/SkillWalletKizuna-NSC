import sharp from 'sharp';
import { readFile } from 'node:fs/promises';
import path from 'node:path';

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
  { keys: ['โดนัท', 'donut'], type: 'donut', label: 'โดนัท' },
  { keys: ['คัพเค้ก', 'เค้ก', 'cupcake', 'cake'], type: 'cupcake', label: 'คัพเค้ก' },
  { keys: ['ลูกอม', 'candy'], type: 'candy', label: 'ลูกอม' },
  { keys: ['ขนมปัง', 'bread'], type: 'bread', label: 'ขนมปัง' },
  { keys: ['ขนม', 'snack'], type: 'donut', label: 'ขนม' },
  { keys: ['ไข่', 'egg'], type: 'egg', label: 'ไข่' },
  { keys: ['แมว', 'cat', 'kitten'], type: 'cat', label: 'แมว' },
  { keys: ['หมา', 'สุนัข', 'dog', 'puppy'], type: 'dog', label: 'สุนัข' },
  { keys: ['แกะ', 'ลูกแกะ', 'sheep', 'lamb'], type: 'sheep', label: 'ลูกแกะ' },
  { keys: ['กระต่าย', 'rabbit', 'bunny'], type: 'rabbit', label: 'กระต่าย' },
  { keys: ['นก', 'bird'], type: 'bird', label: 'นก' },
  { keys: ['สตรอเบอร์รี่', 'สตรอเบอรี', 'strawberry'], type: 'strawberry', label: 'สตรอเบอร์รี่' },
  { keys: ['แอปเปิ้ล', 'แอปเปิล', 'apple'], type: 'apple', label: 'แอปเปิล' },
  { keys: ['ส้ม', 'orange'], type: 'orange', label: 'ส้ม' },
  { keys: ['กล้วย', 'banana'], type: 'banana', label: 'กล้วย' },
  { keys: ['องุ่น', 'grape', 'grapes'], type: 'grape', label: 'องุ่น' },
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
  const occurrences = ITEM_TYPES.flatMap((item) => item.keys.flatMap((key) => {
    const matches: Array<{ item: typeof item; index: number; end: number; keyLength: number }> = [];
    let fromIndex = 0;
    while (fromIndex < lower.length) {
      const index = lower.indexOf(key, fromIndex);
      if (index < 0) break;
      const isShortThaiKeyword = key.length <= 2 && /[ก-๙]/.test(key);
      const previousCharacter = index > 0 ? lower[index - 1] : '';
      const nextCharacter = lower[index + key.length] ?? '';
      if (isShortThaiKeyword && (/[ก-๙]/.test(previousCharacter) || /[ก-๙]/.test(nextCharacter))) {
        fromIndex = index + Math.max(1, key.length);
        continue;
      }
      matches.push({ item, index, end: index + key.length, keyLength: key.length });
      fromIndex = index + Math.max(1, key.length);
    }
    return matches;
  }));

  // Prefer the longest word when item names overlap. For example, "ขนม"
  // must not also be interpreted as "นม" simply because it contains that
  // shorter word.
  const nonOverlapping = occurrences.filter((candidate) => !occurrences.some((other) => (
    other.item.type !== candidate.item.type
      && other.keyLength > candidate.keyLength
      && other.index <= candidate.index
      && other.end >= candidate.end
  )));

  const found = nonOverlapping
    .sort((a, b) => a.index - b.index || b.keyLength - a.keyLength)
    .filter((entry, index, list) => list.findIndex((candidate) => candidate.item.type === entry.item.type) === index)
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
    // 🍩 Shaded glazed donut that remains clear at counting size.
    return `<g transform="translate(${x} ${y})">
      <ellipse cx="${cx}" cy="${cy + s * 0.09}" rx="${s * 0.43}" ry="${s * 0.35}" fill="#713F12" opacity="0.25"/>
      <circle cx="${cx}" cy="${cy}" r="${s * 0.42}" fill="url(#donutDough)" stroke="#78350F" stroke-width="2.5"/>
      <path d="M${cx - s * 0.34} ${cy - s * 0.06} C${cx - s * 0.28} ${cy - s * 0.38}, ${cx + s * 0.28} ${cy - s * 0.38}, ${cx + s * 0.35} ${cy - s * 0.04} C${cx + s * 0.22} ${cy + s * 0.12}, ${cx - s * 0.22} ${cy + s * 0.12}, ${cx - s * 0.34} ${cy - s * 0.06}Z" fill="url(#donutIcing)"/>
      <circle cx="${cx}" cy="${cy}" r="${s * 0.14}" fill="#FFF7ED" stroke="#B45309" stroke-width="2"/>
      <ellipse cx="${cx - s * 0.14}" cy="${cy - s * 0.2}" rx="${s * 0.11}" ry="${s * 0.045}" fill="#FFFFFF" opacity="0.5" transform="rotate(-18 ${cx - s * 0.14} ${cy - s * 0.2})"/>
      <line x1="${cx - s * 0.2}" y1="${cy - s * 0.15}" x2="${cx - s * 0.1}" y2="${cy - s * 0.22}" stroke="#FEF08A" stroke-width="3" stroke-linecap="round"/>
      <line x1="${cx + s * 0.1}" y1="${cy - s * 0.18}" x2="${cx + s * 0.22}" y2="${cy - s * 0.12}" stroke="#60A5FA" stroke-width="3" stroke-linecap="round"/>
      <line x1="${cx - s * 0.22}" y1="${cy + s * 0.1}" x2="${cx - s * 0.12}" y2="${cy + s * 0.2}" stroke="#4ADE80" stroke-width="3" stroke-linecap="round"/>
      <line x1="${cx + s * 0.12}" y1="${cy + s * 0.15}" x2="${cx + s * 0.22}" y2="${cy + s * 0.08}" stroke="#FACC15" stroke-width="3" stroke-linecap="round"/>
    </g>`;
  }

  if (type === 'cupcake') {
    return `<g transform="translate(${x} ${y})">
      <path d="M${cx - s * 0.28} ${cy} L${cx - s * 0.2} ${cy + s * 0.38} L${cx + s * 0.2} ${cy + s * 0.38} L${cx + s * 0.28} ${cy}Z" fill="#60A5FA" stroke="#1D4ED8" stroke-width="2.5"/>
      <path d="M${cx - s * 0.3} ${cy} C${cx - s * 0.3} ${cy - s * 0.2}, ${cx - s * 0.08} ${cy - s * 0.24}, ${cx} ${cy - s * 0.12} C${cx + s * 0.08} ${cy - s * 0.29}, ${cx + s * 0.32} ${cy - s * 0.19}, ${cx + s * 0.3} ${cy}Z" fill="#FDA4AF" stroke="#DB2777" stroke-width="2.5"/>
      <circle cx="${cx}" cy="${cy - s * 0.25}" r="${s * 0.07}" fill="#EF4444"/>
      <path d="M${cx - s * 0.13} ${cy + s * 0.04}V${cy + s * 0.32}M${cx} ${cy + s * 0.03}V${cy + s * 0.35}M${cx + s * 0.13} ${cy + s * 0.04}V${cy + s * 0.32}" stroke="#DBEAFE" stroke-width="2"/>
    </g>`;
  }

  if (type === 'candy') {
    return `<g transform="translate(${x} ${y})">
      <path d="M${cx - s * 0.24} ${cy} L${cx - s * 0.45} ${cy - s * 0.18} L${cx - s * 0.43} ${cy + s * 0.2}Z" fill="#FBBF24" stroke="#D97706" stroke-width="2"/>
      <path d="M${cx + s * 0.24} ${cy} L${cx + s * 0.45} ${cy - s * 0.18} L${cx + s * 0.43} ${cy + s * 0.2}Z" fill="#FBBF24" stroke="#D97706" stroke-width="2"/>
      <ellipse cx="${cx}" cy="${cy}" rx="${s * 0.28}" ry="${s * 0.23}" fill="#F472B6" stroke="#BE185D" stroke-width="2.5"/>
      <path d="M${cx - s * 0.15} ${cy - s * 0.13} Q${cx} ${cy} ${cx + s * 0.15} ${cy + s * 0.13}" fill="none" stroke="#FDE68A" stroke-width="5" stroke-linecap="round"/>
    </g>`;
  }

  if (type === 'bread') {
    return `<g transform="translate(${x} ${y})">
      <path d="M${cx - s * 0.34} ${cy + s * 0.3}V${cy - s * 0.05} C${cx - s * 0.4} ${cy - s * 0.36}, ${cx - s * 0.08} ${cy - s * 0.42}, ${cx} ${cy - s * 0.24} C${cx + s * 0.08} ${cy - s * 0.42}, ${cx + s * 0.4} ${cy - s * 0.36}, ${cx + s * 0.34} ${cy - s * 0.05}V${cy + s * 0.3}Z" fill="#FCD58D" stroke="#B45309" stroke-width="3"/>
      <path d="M${cx - s * 0.23} ${cy - s * 0.05}Q${cx} ${cy - s * 0.2} ${cx + s * 0.23} ${cy - s * 0.05}" fill="none" stroke="#FDE68A" stroke-width="5" stroke-linecap="round"/>
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

  if (type === 'banana') {
    return `<g transform="translate(${x} ${y})">
      <path d="M${cx - s * 0.34} ${cy - s * 0.2} C${cx - s * 0.18} ${cy + s * 0.38}, ${cx + s * 0.28} ${cy + s * 0.38}, ${cx + s * 0.38} ${cy - s * 0.06} C${cx + s * 0.16} ${cy + s * 0.16}, ${cx - s * 0.08} ${cy + s * 0.12}, ${cx - s * 0.34} ${cy - s * 0.2}Z" fill="#FACC15" stroke="#CA8A04" stroke-width="3"/>
      <path d="M${cx - s * 0.36} ${cy - s * 0.22}l${-s * 0.03} ${-s * 0.08}M${cx + s * 0.38} ${cy - s * 0.06}l${s * 0.04} ${-s * 0.08}" stroke="#854D0E" stroke-width="4" stroke-linecap="round"/>
    </g>`;
  }

  if (type === 'grape') {
    const grapes = [[0, -0.2], [-0.13, -0.08], [0.13, -0.08], [-0.2, 0.07], [0, 0.07], [0.2, 0.07], [-0.12, 0.22], [0.12, 0.22], [0, 0.35]];
    return `<g transform="translate(${x} ${y})">
      <path d="M${cx} ${cy - s * 0.3}Q${cx + s * 0.08} ${cy - s * 0.48} ${cx + s * 0.2} ${cy - s * 0.4}" fill="none" stroke="#166534" stroke-width="4"/>
      <ellipse cx="${cx + s * 0.18}" cy="${cy - s * 0.38}" rx="${s * 0.16}" ry="${s * 0.08}" fill="#4ADE80" transform="rotate(-20 ${cx + s * 0.18} ${cy - s * 0.38})"/>
      ${grapes.map(([gx, gy]) => `<circle cx="${cx + gx * s}" cy="${cy + gy * s}" r="${s * 0.12}" fill="#8B5CF6" stroke="#5B21B6" stroke-width="2"/>`).join('')}
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

function overlaySvg(_question: string, visual: MathVisualData, transparentBackground = false) {
  const operationText: Record<string, { left: string; right: string }> = {
    '+': { left: 'ของที่มีอยู่', right: 'เพิ่มเข้ามาอีก' },
    '-': { left: 'ของทั้งหมด', right: 'นำออก' },
    '×': { left: 'จำนวนกลุ่ม', right: 'จำนวนในแต่ละกลุ่ม' },
    '÷': { left: 'ของทั้งหมด', right: 'แบ่งเป็นกลุ่ม' },
  };
  const copy = operationText[visual.operator] ?? { left: 'กลุ่มที่ 1', right: 'กลุ่มที่ 2' };
  const removedOverlay = visual.operator === '-'
    ? `<g opacity="0.9" stroke="#EF4444" stroke-width="12" stroke-linecap="round">
        <line x1="745" y1="185" x2="1165" y2="655"/>
        <line x1="1165" y1="185" x2="745" y2="655"/>
      </g>`
    : '';

  return Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${WIDTH}" height="${HEIGHT}">
    <defs>
      <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0%" stop-color="#EFF6FF"/>
        <stop offset="50%" stop-color="#F0FDF4"/>
        <stop offset="100%" stop-color="#FAF5FF"/>
      </linearGradient>
      <radialGradient id="donutDough" cx="35%" cy="25%"><stop offset="0" stop-color="#FCD58D"/><stop offset="65%" stop-color="#D97706"/><stop offset="100%" stop-color="#92400E"/></radialGradient>
      <linearGradient id="donutIcing" x1="0" y1="0" x2="0.8" y2="1"><stop offset="0" stop-color="#FDA4AF"/><stop offset="50%" stop-color="#F472B6"/><stop offset="100%" stop-color="#DB2777"/></linearGradient>
    </defs>
    ${transparentBackground ? '' : `<rect width="${WIDTH}" height="${HEIGHT}" fill="url(#bg)"/>
    <circle cx="150" cy="100" r="80" fill="#FEF08A" opacity="0.3"/>
    <circle cx="1150" cy="650" r="120" fill="#FBCFE8" opacity="0.3"/>`}
    <style>
      text { font-family: 'Noto Sans Thai', 'Chakra Petch', 'Tahoma', sans-serif; }
    </style>
    
    <!-- Left Card Container -->
    <rect x="50" y="50" width="550" height="668" rx="36" fill="#FFFFFF" fill-opacity="${transparentBackground ? '0.82' : '0.88'}" stroke="#F472B6" stroke-width="6"/>
    <text x="325" y="92" font-size="28" font-weight="700" text-anchor="middle" fill="#DB2777">${escapeXml(formatCountLabel(visual.leftItem, visual.leftLabel, visual.leftCount))}</text>
    <text x="325" y="124" font-size="18" font-weight="600" text-anchor="middle" fill="#64748B">${copy.left}</text>
    ${objectGrid(visual.leftItem, visual.leftCount, 75, 145, 500, 548)}

    <!-- Right Card Container -->
    <rect x="680" y="50" width="550" height="668" rx="36" fill="#FFFFFF" fill-opacity="${transparentBackground ? '0.82' : '0.88'}" stroke="#60A5FA" stroke-width="6"/>
    <text x="955" y="92" font-size="28" font-weight="700" text-anchor="middle" fill="#2563EB">${escapeXml(formatCountLabel(visual.rightItem, visual.rightLabel, visual.rightCount))}</text>
    <text x="955" y="124" font-size="18" font-weight="600" text-anchor="middle" fill="#64748B">${copy.right}</text>
    ${objectGrid(visual.rightItem, visual.rightCount, 705, 145, 500, 548)}
    ${removedOverlay}

    <!-- Center Math Operator Circle -->
    <circle cx="640" cy="384" r="52" fill="#8B5CF6" stroke="#FFFFFF" stroke-width="6"/>
    <text x="640" y="403" font-size="56" font-weight="800" text-anchor="middle" fill="#FFFFFF">${escapeXml(visual.operator)}</text>
  </svg>`);
}

function itemClassifier(type: string) {
  const classifiers: Record<string, string> = {
    fish: 'ตัว', cat: 'ตัว', dog: 'ตัว', sheep: 'ตัว', rabbit: 'ตัว', bird: 'ตัว',
    donut: 'ชิ้น', cookie: 'ชิ้น', cupcake: 'ชิ้น', candy: 'ชิ้น', bread: 'ชิ้น',
    egg: 'ฟอง', strawberry: 'ลูก', apple: 'ลูก', orange: 'ลูก', banana: 'ลูก', grape: 'พวง',
    ball: 'ลูก', star: 'ดวง', flower: 'ดอก',
    book: 'เล่ม', pencil: 'แท่ง', balloon: 'ลูก', car: 'คัน', milk: 'กล่อง',
  };
  return classifiers[type] ?? 'ชิ้น';
}

function formatCountLabel(type: string, label: string, count: number) {
  return `${label} ${count} ${itemClassifier(type)}`;
}

function storyObjectCluster(type: string, count: number, x: number, y: number, width: number, height: number, fixedSize?: number) {
  if (count <= 0) return '';
  const columns = Math.min(5, Math.max(3, Math.ceil(Math.sqrt(count * 1.5))));
  const rows = Math.ceil(count / columns);
  const cellWidth = width / columns;
  const cellHeight = height / rows;
  const size = fixedSize ?? Math.max(38, Math.min(76, cellWidth * 0.68, cellHeight * 0.72));
  let result = '';

  for (let index = 0; index < count; index++) {
    const row = Math.floor(index / columns);
    const column = index % columns;
    const itemsInRow = Math.min(columns, count - row * columns);
    const rowOffset = (columns - itemsInRow) * cellWidth * 0.5;
    const jitterX = ((index * 17) % 9) - 4;
    const jitterY = ((index * 13) % 7) - 3;
    const itemX = x + rowOffset + column * cellWidth + (cellWidth - size) / 2 + jitterX;
    const itemY = y + row * cellHeight + (cellHeight - size) / 2 + jitterY;
    result += `<ellipse cx="${itemX + size / 2}" cy="${itemY + size * 0.84}" rx="${size * 0.34}" ry="${size * 0.1}" fill="#422006" opacity="0.18"/>`;
    result += objectShape(type, itemX, itemY, size);
  }
  return result;
}

// Kept as a code-only scene renderer for future template variants.
export function storyOverlaySvg(visual: MathVisualData) {
  const copy: Record<string, { left: string; right: string; action: string; color: string }> = {
    '+': { left: 'มีอยู่เดิม', right: 'นำมาเพิ่ม', action: 'นำมารวมกัน', color: '#7C3AED' },
    '-': { left: 'มีทั้งหมด', right: 'นำออกไป', action: 'เอาออก', color: '#DC2626' },
    '×': { left: 'จำนวนกลุ่ม', right: 'กลุ่มละ', action: 'จัดกลุ่มเท่า ๆ กัน', color: '#D97706' },
    '÷': { left: 'มีทั้งหมด', right: 'แบ่งเป็น', action: 'แบ่งเท่า ๆ กัน', color: '#059669' },
  };
  const text = copy[visual.operator] ?? { left: 'กลุ่มแรก', right: 'กลุ่มที่สอง', action: 'ลองนับดู', color: '#7C3AED' };
  const equation = `${visual.leftCount} ${visual.operator} ${visual.rightCount} = ?`;
  const removed = visual.operator === '-'
    ? `<g stroke="#DC2626" stroke-width="10" stroke-linecap="round" opacity="0.82">
        <line x1="760" y1="350" x2="1130" y2="650"/><line x1="1130" y1="350" x2="760" y2="650"/>
      </g>`
    : '';

  return Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${WIDTH}" height="${HEIGHT}">
    <defs>
      <filter id="shadow" x="-30%" y="-30%" width="160%" height="160%">
        <feDropShadow dx="0" dy="8" stdDeviation="8" flood-color="#1F2937" flood-opacity="0.28"/>
      </filter>
      <linearGradient id="wood" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stop-color="#F5C77A"/><stop offset="1" stop-color="#C98238"/>
      </linearGradient>
      <radialGradient id="donutDough" cx="35%" cy="25%"><stop offset="0" stop-color="#FCD58D"/><stop offset="65%" stop-color="#D97706"/><stop offset="100%" stop-color="#92400E"/></radialGradient>
      <linearGradient id="donutIcing" x1="0" y1="0" x2="0.8" y2="1"><stop offset="0" stop-color="#FDA4AF"/><stop offset="50%" stop-color="#F472B6"/><stop offset="100%" stop-color="#DB2777"/></linearGradient>
      <linearGradient id="basket" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FBBF24"/><stop offset="55%" stop-color="#D97706"/><stop offset="100%" stop-color="#92400E"/></linearGradient>
    </defs>
    <style>text { font-family: 'Noto Sans Thai', 'Tahoma', sans-serif; }</style>

    <!-- Story title sign -->
    <g filter="url(#shadow)">
      <rect x="420" y="28" width="440" height="112" rx="22" fill="url(#wood)" stroke="#713F12" stroke-width="5"/>
      <circle cx="447" cy="55" r="5" fill="#713F12"/><circle cx="833" cy="55" r="5" fill="#713F12"/>
      <text x="640" y="79" text-anchor="middle" font-size="26" font-weight="700" fill="#713F12">โจทย์คณิตศาสตร์</text>
      <text x="640" y="121" text-anchor="middle" font-size="42" font-weight="900" fill="#172554">${escapeXml(equation)}</text>
    </g>

    <!-- Translucent counting areas keep the story visible while making every item easy to count. -->
    <g filter="url(#shadow)">
      <path d="M55 335 Q310 280 595 335 L565 690 Q310 730 85 690 Z" fill="#FFF7ED" fill-opacity="0.86" stroke="#FB7185" stroke-width="5"/>
      <path d="M685 335 Q960 280 1225 335 L1195 690 Q950 730 715 690 Z" fill="#EFF6FF" fill-opacity="0.86" stroke="#60A5FA" stroke-width="5"/>
    </g>

    <!-- Compact narrative labels -->
    <g filter="url(#shadow)">
      <rect x="105" y="235" width="420" height="88" rx="44" fill="#FFFFFF" fill-opacity="0.94" stroke="#FB7185" stroke-width="4"/>
      <text x="315" y="272" text-anchor="middle" font-size="21" font-weight="700" fill="#64748B">${text.left}</text>
      <text x="315" y="306" text-anchor="middle" font-size="31" font-weight="900" fill="#DB2777">${escapeXml(formatCountLabel(visual.leftItem, visual.leftLabel, visual.leftCount))}</text>
      <rect x="755" y="235" width="420" height="88" rx="44" fill="#FFFFFF" fill-opacity="0.94" stroke="#60A5FA" stroke-width="4"/>
      <text x="965" y="272" text-anchor="middle" font-size="21" font-weight="700" fill="#64748B">${text.right}</text>
      <text x="965" y="306" text-anchor="middle" font-size="31" font-weight="900" fill="#2563EB">${escapeXml(formatCountLabel(visual.rightItem, visual.rightLabel, visual.rightCount))}</text>
    </g>

    ${storyObjectCluster(visual.leftItem, visual.leftCount, 95, 350, 450, 320)}
    ${storyObjectCluster(visual.rightItem, visual.rightCount, 735, 350, 450, 320)}
    ${removed}

    <!-- Action connector -->
    <g filter="url(#shadow)">
      <circle cx="640" cy="500" r="55" fill="${text.color}" stroke="#FFFFFF" stroke-width="7"/>
      <text x="640" y="520" text-anchor="middle" font-size="55" font-weight="900" fill="#FFFFFF">${escapeXml(visual.operator)}</text>
      <rect x="525" y="575" width="230" height="54" rx="27" fill="#FFFFFF" fill-opacity="0.94"/>
      <text x="640" y="610" text-anchor="middle" font-size="21" font-weight="800" fill="${text.color}">${text.action}</text>
    </g>
  </svg>`);
}

function subtractionAppleTemplateOverlay(visual: MathVisualData) {
  const equation = `${visual.leftCount} − ${visual.rightCount} = ?`;
  const classifier = itemClassifier(visual.leftItem);
  return Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${WIDTH}" height="${HEIGHT}">
    <defs>
      <filter id="softShadow" x="-30%" y="-30%" width="160%" height="160%"><feDropShadow dx="0" dy="5" stdDeviation="5" flood-color="#44200B" flood-opacity="0.3"/></filter>
      <radialGradient id="donutDough" cx="35%" cy="25%"><stop offset="0" stop-color="#FCD58D"/><stop offset="65%" stop-color="#D97706"/><stop offset="100%" stop-color="#92400E"/></radialGradient>
      <linearGradient id="donutIcing" x1="0" y1="0" x2="0.8" y2="1"><stop offset="0" stop-color="#FDA4AF"/><stop offset="50%" stop-color="#F472B6"/><stop offset="100%" stop-color="#DB2777"/></linearGradient>
    </defs>
    <style>text { font-family: 'Noto Sans Thai', 'Tahoma', sans-serif; paint-order: stroke; stroke: #FFF7ED; stroke-width: 3px; stroke-linejoin: round; }</style>

    <text x="640" y="75" text-anchor="middle" font-size="31" font-weight="800" fill="#4A2A16">โจทย์คณิตศาสตร์</text>
    <text x="640" y="133" text-anchor="middle" font-size="54" font-weight="900" fill="#172554">${escapeXml(equation)}</text>

    <text x="350" y="213" text-anchor="middle" font-size="25" font-weight="700" fill="#3F2A20">มี${escapeXml(visual.leftLabel)}</text>
    <text x="350" y="255" text-anchor="middle" font-size="37" font-weight="900" fill="#E11D48">${visual.leftCount} ${classifier}</text>
    <text x="1032" y="213" text-anchor="middle" font-size="25" font-weight="700" fill="#3F2A20">นำออกไป</text>
    <text x="1032" y="255" text-anchor="middle" font-size="37" font-weight="900" fill="#2563EB">${visual.rightCount} ${classifier}</text>

    ${storyObjectCluster(visual.leftItem, visual.leftCount, 245, 390, 330, 170)}
    ${storyObjectCluster(visual.leftItem, visual.rightCount, 865, 350, 225, 155, 68)}

    <g filter="url(#softShadow)">
      <path d="M790 415 C820 380 850 380 875 408" fill="none" stroke="#2563EB" stroke-width="10" stroke-linecap="round"/>
      <polygon points="870,392 902,410 872,428" fill="#2563EB"/>
    </g>

    <text x="515" y="675" text-anchor="middle" font-size="31" font-weight="800" fill="#3F2A20">คิดสิ... เหลือ${escapeXml(visual.leftLabel)}กี่${classifier}?</text>
    <g filter="url(#softShadow)">
      <rect x="738" y="631" width="145" height="105" rx="14" fill="#FFFDF5" stroke="#DB2777" stroke-width="5" stroke-dasharray="13 9"/>
      <text x="810" y="700" text-anchor="middle" font-size="46" font-weight="900" fill="#DB2777">?</text>
    </g>
  </svg>`);
}

function additionDonutTemplateOverlay(visual: MathVisualData) {
  const equation = `${visual.leftCount} + ${visual.rightCount} = ?`;
  return Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${WIDTH}" height="${HEIGHT}">
    <defs>
      <filter id="softShadow" x="-30%" y="-30%" width="160%" height="160%"><feDropShadow dx="0" dy="5" stdDeviation="5" flood-color="#44200B" flood-opacity="0.3"/></filter>
      <radialGradient id="donutDough" cx="35%" cy="25%"><stop offset="0" stop-color="#FCD58D"/><stop offset="65%" stop-color="#D97706"/><stop offset="100%" stop-color="#92400E"/></radialGradient>
      <linearGradient id="donutIcing" x1="0" y1="0" x2="0.8" y2="1"><stop offset="0" stop-color="#FDA4AF"/><stop offset="50%" stop-color="#F472B6"/><stop offset="100%" stop-color="#DB2777"/></linearGradient>
    </defs>
    <style>text { font-family: 'Noto Sans Thai', 'Tahoma', sans-serif; paint-order: stroke; stroke: #FFF7ED; stroke-width: 3px; stroke-linejoin: round; }</style>

    <text x="605" y="73" text-anchor="middle" font-size="31" font-weight="800" fill="#4A2A16">โจทย์คณิตศาสตร์</text>
    <text x="605" y="132" text-anchor="middle" font-size="54" font-weight="900" fill="#172554">${escapeXml(equation)}</text>

    <text x="350" y="204" text-anchor="middle" font-size="25" font-weight="700" fill="#3F2A20">มี${escapeXml(visual.leftLabel)}อยู่เดิม</text>
    <text x="350" y="247" text-anchor="middle" font-size="37" font-weight="900" fill="#E11D48">${visual.leftCount} ชิ้น</text>
    <text x="795" y="204" text-anchor="middle" font-size="25" font-weight="700" fill="#3F2A20">นำมาเพิ่มอีก</text>
    <text x="795" y="247" text-anchor="middle" font-size="37" font-weight="900" fill="#2563EB">${visual.rightCount} ชิ้น</text>

    ${storyObjectCluster(visual.leftItem, visual.leftCount, 322, 450, 270, 145, 57)}
    ${storyObjectCluster(visual.leftItem, visual.rightCount, 635, 435, 220, 115, 59)}

    <g filter="url(#softShadow)">
      <circle cx="615" cy="572" r="36" fill="#F43F5E" stroke="#FFFFFF" stroke-width="5"/>
      <text x="615" y="590" text-anchor="middle" font-size="48" font-weight="900" fill="#FFFFFF" stroke="none">+</text>
    </g>

    <text x="1082" y="365" text-anchor="middle" font-size="29" font-weight="800" fill="#FFFFFF" stroke="#111827" stroke-width="5">รวมแล้ว</text>
    <text x="1082" y="408" text-anchor="middle" font-size="29" font-weight="800" fill="#FFFFFF" stroke="#111827" stroke-width="5">มีกี่ชิ้นนะ?</text>
    <text x="1085" y="518" text-anchor="middle" font-size="52" font-weight="900" fill="#E11D48">?</text>

    <text x="610" y="680" text-anchor="middle" font-size="30" font-weight="800" fill="#3F2A20">คิดสิ... รวมแล้วมี${escapeXml(visual.leftLabel)}ทั้งหมดกี่ชิ้น?</text>
  </svg>`);
}

async function createAdditionTemplateImage(visual: MathVisualData) {
  const snackTypes = new Set(['donut', 'cookie', 'cupcake', 'candy', 'bread']);
  if (visual.operator !== '+' || !snackTypes.has(visual.leftItem)) return null;
  try {
    const templatePath = path.join(process.cwd(), 'public', 'math-templates', 'addition-donut-shop.png');
    const template = await readFile(templatePath);
    return await sharp(template)
      .resize(WIDTH, HEIGHT, { fit: 'cover' })
      .composite([{ input: additionDonutTemplateOverlay(visual) }])
      .png()
      .toBuffer();
  } catch (error) {
    console.warn('Addition donut template unavailable, falling back to generated scene:', error);
    return null;
  }
}

async function createSubtractionTemplateImage(visual: MathVisualData) {
  const fruitTypes = new Set(['apple', 'orange', 'banana', 'strawberry', 'grape']);
  if (visual.operator !== '-' || !fruitTypes.has(visual.leftItem)) return null;
  try {
    const templatePath = path.join(process.cwd(), 'public', 'math-templates', 'subtraction-apple-farm.png');
    const template = await readFile(templatePath);
    const overlay = subtractionAppleTemplateOverlay(visual);
    return await sharp(template)
      .resize(WIDTH, HEIGHT, { fit: 'cover' })
      .composite([{ input: overlay }])
      .png()
      .toBuffer();
  } catch (error) {
    console.warn('Subtraction apple template unavailable, falling back to generated scene:', error);
    return null;
  }
}

export async function createMathSimulationImage(question: string, equation?: string) {
  const visualData = extractMathVisualData(question, equation);
  const additionTemplateImage = await createAdditionTemplateImage(visualData);
  if (additionTemplateImage) {
    return {
      buffer: additionTemplateImage,
      provider: 'local-template-addition-snack',
      visualPrompt: `Reusable addition template: ${visualData.leftCount} + ${visualData.rightCount}`,
      visualData,
    };
  }
  const templateImage = await createSubtractionTemplateImage(visualData);
  if (templateImage) {
    return {
      buffer: templateImage,
      provider: 'local-template-subtraction-fruit',
      visualPrompt: `Reusable subtraction template: ${visualData.leftCount} - ${visualData.rightCount}`,
      visualData,
    };
  }
  // Build the counting scene locally. AI image generators are intentionally not
  // used here because they cannot guarantee that the rendered object count is
  // mathematically correct.
  const svgBuffer = overlaySvg(question, visualData, false);
  const pngBuffer = await sharp(svgBuffer).png().toBuffer();

  return {
    buffer: pngBuffer,
    provider: 'local-svg-deterministic',
    visualPrompt: `Local visual: ${visualData.leftCount} ${visualData.leftLabel} ${visualData.operator} ${visualData.rightCount} ${visualData.rightLabel}`,
    visualData,
  };
}

