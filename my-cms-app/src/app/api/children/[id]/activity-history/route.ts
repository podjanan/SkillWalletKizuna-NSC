import { NextRequest, NextResponse } from 'next/server';
import { getAuthenticatedParent } from '@/lib/get-parent';
import { prisma } from '@/lib/prisma';

type RouteContext = { params: Promise<{ id: string }> };

/**
 * GET /api/children/[id]/activity-history
 */
export async function GET(request: NextRequest, context: RouteContext) {
  const auth = await getAuthenticatedParent(request);
  if (auth.error) return auth.error;

  const { id: childId } = await context.params;

  try {
    const records = await prisma.activity_record.findMany({
      where: { child_id: childId },
      include: {
        activity: {
          select: { name_activity: true, category: true, maxscore: true },
        },
      },
      orderBy: { created_at: 'desc' },
    });

    const mappedRecords = records.map((record) => {
      const evidence =
        record.evidence &&
        typeof record.evidence === 'object' &&
        !Array.isArray(record.evidence)
          ? (record.evidence as Record<string, unknown>)
          : null;

      if (record.activity) {
        return record;
      }

      if (evidence?.type === 'space_adventure') {
        const maxScore =
          typeof evidence.maxScore === 'number'
            ? evidence.maxScore
            : Number(evidence.maxScore ?? 0) || 100;

        return {
          ...record,
          activity: {
            name_activity: 'SPACE ADVENTURE',
            category: 'LANGUAGE',
            maxscore: maxScore,
          },
        };
      }

      if (evidence?.type !== 'voice_quest') {
        return record;
      }

      const maxScore =
        typeof evidence.maxScore === 'number'
          ? evidence.maxScore
          : Number(evidence.maxScore ?? 0) || 100;

      return {
        ...record,
        activity: {
          name_activity: 'VOICE QUEST',
          category: 'LANGUAGE',
          maxscore: maxScore,
        },
      };
    });

    return NextResponse.json(mappedRecords);
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Unknown error';
    return NextResponse.json(
      { error: 'Failed to get activity history', details: message },
      { status: 500 }
    );
  }
}
