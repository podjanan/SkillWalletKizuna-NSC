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
      question: `น้องมีแอปเปิ้ล ${left} ลูก และได้รับเพิ่มอีก ${right} ลูก ตอนนี้น้องมีแอปเปิ้ลทั้งหมดกี่ลูก?`,
      hint: `นำจำนวนแอปเปิ้ลเดิม ${left} มาบวกกับจำนวนที่ได้รับเพิ่ม ${right}`,
    };
  }
  if (operator === '-') {
    return {
      question: `น้องมีแอปเปิ้ล ${left} ลูก กินไป ${right} ลูก น้องจะเหลือแอปเปิ้ลกี่ลูก?`,
      hint: `นำจำนวนแอปเปิ้ลที่กินไป ${right} ออกจากจำนวนเดิม ${left}`,
    };
  }
  if (operator === '*') {
    return {
      question: `มีตะกร้า ${left} ใบ แต่ละใบมีส้ม ${right} ลูก ในตะกร้าทั้งหมดมีส้มกี่ลูก?`,
      hint: `นำจำนวนตะกร้า ${left} คูณกับจำนวนส้มในแต่ละตะกร้า ${right}`,
    };
  }
  return {
    question: `มีส้ม ${left} ลูก แบ่งให้เพื่อน ${right} คนเท่า ๆ กัน เพื่อนแต่ละคนจะได้ส้มกี่ลูก?`,
    hint: `นำจำนวนส้มทั้งหมด ${left} หารด้วยจำนวนเพื่อน ${right}`,
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
