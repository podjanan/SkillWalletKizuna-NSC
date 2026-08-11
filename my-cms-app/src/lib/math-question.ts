export type ParsedEquation = {
  left: number;
  right: number;
  operator: '+' | '-' | '*' | '/';
  answer: number;
};

export type MathStoryItem = {
  name: string;
  classifier: 'ชิ้น' | 'ลูก' | 'พวง';
};

const ADDITION_SNACKS: MathStoryItem[] = [
  { name: 'โดนัท', classifier: 'ชิ้น' },
  { name: 'คุกกี้', classifier: 'ชิ้น' },
  { name: 'คัพเค้ก', classifier: 'ชิ้น' },
  { name: 'ลูกอม', classifier: 'ชิ้น' },
  { name: 'ขนมปัง', classifier: 'ชิ้น' },
];

const SUBTRACTION_FRUITS: MathStoryItem[] = [
  { name: 'แอปเปิล', classifier: 'ลูก' },
  { name: 'ส้ม', classifier: 'ลูก' },
  { name: 'กล้วย', classifier: 'ลูก' },
  { name: 'สตรอเบอร์รี่', classifier: 'ลูก' },
  { name: 'องุ่น', classifier: 'พวง' },
];

export function randomStoryItem(operator: ParsedEquation['operator']): MathStoryItem | null {
  const items = operator === '+' ? ADDITION_SNACKS : operator === '-' ? SUBTRACTION_FRUITS : null;
  return items ? items[Math.floor(Math.random() * items.length)] : null;
}

export function parseEquation(value: string): ParsedEquation | null {
  const expression = value.split('=')[0].trim().replace(/[xX×]/g, '*').replace(/÷/g, '/');
  const match = expression.match(/^(-?\d+(?:\.\d+)?)\s*([+\-*/])\s*(-?\d+(?:\.\d+)?)$/);
  if (!match) return null;

  const left = Number(match[1]);
  const right = Number(match[3]);
  const operator = match[2] as ParsedEquation['operator'];
  if (operator === '/' && right === 0) return null;

  const answer = operator === '+'
    ? left + right
    : operator === '-'
      ? left - right
      : operator === '*'
        ? left * right
        : left / right;

  return Number.isFinite(answer) ? { left, right, operator, answer } : null;
}

export function fallbackQuestion(equation: ParsedEquation, storyItem = randomStoryItem(equation.operator)) {
  const { left, right, operator } = equation;
  if (operator === '+') {
    const item = storyItem ?? ADDITION_SNACKS[0];
    return {
      question: `มี${item.name} ${left} ${item.classifier} แม่ให้อีก ${right} ${item.classifier} รวมมี${item.name}กี่${item.classifier}?`,
      solution: buildMathSolution(equation, item),
    };
  }
  if (operator === '-') {
    const item = storyItem ?? SUBTRACTION_FRUITS[0];
    return {
      question: `มี${item.name} ${left} ${item.classifier} กินไป ${right} ${item.classifier} เหลือ${item.name}กี่${item.classifier}?`,
      solution: buildMathSolution(equation, item),
    };
  }
  if (operator === '*') {
    return {
      question: `มีจาน ${left} ใบ แต่ละใบมีส้ม ${right} ลูก รวมมีส้มกี่ลูก?`,
      solution: buildMathSolution(equation),
    };
  }
  return {
    question: `มีส้ม ${left} ลูก แบ่งให้เพื่อน ${right} คน เท่าๆ กัน จะได้คนละกี่ลูก?`,
    solution: buildMathSolution(equation),
  };
}

export function buildMathSolution(
  equation: ParsedEquation,
  storyItem?: MathStoryItem | null,
) {
  const symbol = equation.operator === '*' ? '×' : equation.operator === '/' ? '÷' : equation.operator;
  const operation = equation.operator === '+'
    ? 'นำจำนวนเดิมมาบวกกับจำนวนที่เพิ่มมา'
    : equation.operator === '-'
      ? 'นำจำนวนที่เอาออกมาลบจากจำนวนเริ่มต้น'
      : equation.operator === '*'
        ? 'นำจำนวนกลุ่มคูณด้วยจำนวนสิ่งของในแต่ละกลุ่ม'
        : 'นำจำนวนสิ่งของทั้งหมดหารด้วยจำนวนกลุ่ม';
  const unit = storyItem?.classifier ?? 'ลูก';

  return `${operation}\n${equation.left} ${symbol} ${equation.right} = ${equation.answer}\nดังนั้น คำตอบคือ ${equation.answer} ${unit}`;
}

export function questionMatchesEquation(question: string, equation: ParsedEquation) {
  const numericValues = Array.from(question.matchAll(/-?\d+(?:\.\d+)?/g), (match) => Number(match[0]));
  const expectedValues = [equation.left, equation.right];
  const hasBothOperands = expectedValues.every((value, index) => {
    const earlierMatches = expectedValues.slice(0, index).filter((item) => item === value).length;
    return numericValues.filter((item) => item === value).length > earlierMatches;
  });
  if (!hasBothOperands) return false;

  if (equation.operator === '+') {
    const riskyGrouping = /(แต่ละ|คนละ|กล่องละ|ชิ้นละ|ใบละ|เท่า\s*ๆ\s*กัน|แบ่งให้|เด็ก\s*\d+\s*คน)/;
    return !riskyGrouping.test(question) && /(เพิ่ม|อีก|รวม|ทั้งหมด|บวก)/.test(question);
  }
  if (equation.operator === '-') return /(เหลือ|กินไป|เอาออก|ให้ไป|ลดลง|ความต่าง)/.test(question);
  if (equation.operator === '*') return /(แต่ละ|คนละ|กล่องละ|ชิ้นละ|ใบละ|กลุ่มละ|คูณ)/.test(question);
  return /(แบ่ง|หาร|เท่า\s*ๆ\s*กัน|คนละ)/.test(question);
}

export function operatorDescription(operator: ParsedEquation['operator']) {
  if (operator === '+') return 'การบวก: มีจำนวนเดิม แล้วได้รับเพิ่มอีกหนึ่งจำนวน จากนั้นถามจำนวนรวม ห้ามใช้คำว่า แต่ละ คนละ หรือสร้างหลายกลุ่ม';
  if (operator === '-') return 'การลบ: มีจำนวนเริ่มต้น แล้วนำจำนวนที่สองออก จากนั้นถามจำนวนที่เหลือ';
  if (operator === '*') return 'การคูณ: จำนวนแรกคือจำนวนกลุ่ม และจำนวนที่สองคือจำนวนสิ่งของต่อกลุ่ม';
  return 'การหาร: จำนวนแรกคือสิ่งของทั้งหมด แบ่งเป็นจำนวนกลุ่มตามจำนวนที่สอง แล้วถามจำนวนต่อกลุ่ม';
}
