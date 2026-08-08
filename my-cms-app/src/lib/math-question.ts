export type ParsedEquation = {
  left: number;
  right: number;
  operator: '+' | '-' | '*' | '/';
  answer: number;
};

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

export function fallbackQuestion(equation: ParsedEquation) {
  const { left, right, operator } = equation;
  if (operator === '+') {
    return {
      question: `มีขนม ${left} ชิ้น แม่ให้อีก ${right} ชิ้น รวมมีขนมกี่ชิ้น?`,
      hint: `นำ ${left} มาบวกกับ ${right}`,
    };
  }
  if (operator === '-') {
    return {
      question: `มีแอปเปิ้ล ${left} ลูก กินไป ${right} ลูก เหลือแอปเปิ้ลกี่ลูก?`,
      hint: `นำ ${left} ลบด้วย ${right}`,
    };
  }
  if (operator === '*') {
    return {
      question: `มีจาน ${left} ใบ แต่ละใบมีส้ม ${right} ลูก รวมมีส้มกี่ลูก?`,
      hint: `นำ ${left} คูณด้วย ${right}`,
    };
  }
  return {
    question: `มีส้ม ${left} ลูก แบ่งให้เพื่อน ${right} คน เท่าๆ กัน จะได้คนละกี่ลูก?`,
    hint: `นำ ${left} หารด้วย ${right}`,
  };
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
