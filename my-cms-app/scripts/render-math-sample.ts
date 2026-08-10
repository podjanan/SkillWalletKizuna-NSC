import { mkdir, writeFile } from 'node:fs/promises';
import path from 'node:path';
import { createMathSimulationImage } from '../src/lib/math-simulation-image';

async function main() {
  const outputDirectory = path.resolve(process.cwd(), 'tmp', 'math-simulation');
  await mkdir(outputDirectory, { recursive: true });
  const question = process.env.MATH_SAMPLE_QUESTION
    ?? 'แม่ซื้อขนมมาทั้งหมด 15 ชิ้น แล้วได้อีก 8 ชิ้น รวมมีขนมทั้งหมดกี่ชิ้น?';
  const equation = process.env.MATH_SAMPLE_EQUATION ?? '15 + 8';
  const filename = process.env.MATH_SAMPLE_FILENAME ?? 'local-story-sample.png';
  const result = await createMathSimulationImage(question, equation);
  const outputPath = path.join(outputDirectory, filename);
  await writeFile(outputPath, result.buffer);
  console.log(JSON.stringify({ outputPath, provider: result.provider, visualData: result.visualData }, null, 2));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
