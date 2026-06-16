import { NextRequest, NextResponse } from 'next/server';
import { auth } from '@/lib/auth';
import { prisma } from '@/lib/prisma';

/**
 * POST /api/parents/sync
 * Upsert parent record for authenticated user.
 * Called after login/register from Flutter (Bearer token) or web (cookie).
 *
 * Body: { email?: string, fullName?: string }
 * Response: { success: true, parent: { parentId, nameSurname, email } }
 */
export async function POST(request: NextRequest) {
  try {
    const session = await auth.api.getSession({ headers: request.headers });

    if (!session?.user) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 });
    }

    const { user } = session;
    const body = await request.json();
    const { email, fullName } = body;

    const emailToSave = email || user.email;

    // 1. หาจาก user_id ก่อน (login ครั้งที่ 2 เป็นต้นไป)
    let existing = await prisma.parent.findFirst({
      where: { user_id: user.id },
      select: { parent_id: true, name_surname: true, email: true, user_id: true },
    });

    // 2. Fallback: หาจาก email (กรณี migrate จาก Supabase — user_id ยัง NULL)
    if (!existing && emailToSave) {
      existing = await prisma.parent.findFirst({
        where: { email: emailToSave, user_id: null },
        select: { parent_id: true, name_surname: true, email: true, user_id: true },
      });

      // Link user_id ให้ทันที
      if (existing) {
        await prisma.parent.update({
          where: { parent_id: existing.parent_id },
          data: { user_id: user.id },
        });
      }
    }

    let parent;

    if (existing) {
      if (fullName) {
        parent = await prisma.parent.update({
          where: { parent_id: existing.parent_id },
          data: { name_surname: fullName },
          select: { parent_id: true, name_surname: true, email: true },
        });
      } else {
        parent = existing;
      }
    } else {
      const nameToSave = fullName || emailToSave?.split('@')[0] || 'User';
      parent = await prisma.parent.create({
        data: {
          user_id: user.id,
          email: emailToSave,
          name_surname: nameToSave,
        },
        select: { parent_id: true, name_surname: true, email: true },
      });
    }

    return NextResponse.json({
      success: true,
      parent: {
        parentId: parent.parent_id,
        nameSurname: parent.name_surname,
        email: parent.email,
      },
    });
  } catch (err: any) {
    return NextResponse.json(
      { error: 'Sync failed', details: err.message },
      { status: 500 }
    );
  }
}
