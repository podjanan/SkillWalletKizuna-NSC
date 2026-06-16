// app/api/users/[id]/route.ts
import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

export async function GET(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const params = await context.params;

    const parent = await prisma.parent.findUnique({
      where: { parent_id: params.id },
      include: {
        ba_user: true,
        parent_and_child: {
          include: {
            child: {
              select: {
                child_id: true,
                name_surname: true,
                birthday: true,
                wallet: true,
                update_wallet: true,
              },
            },
          },
        },
        activity_record: {
          take: 10,
          orderBy: { created_at: 'desc' },
          include: {
            child: { select: { name_surname: true } },
            activity: { select: { name_activity: true, category: true } },
          },
        },
        parent_and_medals: {
          include: {
            medals: { select: { id: true, name_medals: true, point_medals: true } },
          },
        },
        redemption: {
          take: 10,
          orderBy: { created_at: 'desc' },
          include: {
            child: { select: { name_surname: true } },
            medals: { select: { name_medals: true } },
          },
        },
      },
    });

    if (!parent) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 });
    }

    const children = parent.parent_and_child.map((pc) => ({
      id: pc.child?.child_id || '',
      fullName: pc.child?.name_surname || 'N/A',
      dob: pc.child?.birthday?.toISOString(),
      score: pc.child?.wallet ? Number(pc.child.wallet) : 0,
      scoreUpdate: pc.child?.update_wallet ? Number(pc.child.update_wallet) : 0,
      relationship: pc.relationship || 'N/A',
    }));

    const recentActivities = parent.activity_record.map((record) => ({
      id: record.ActivityRecord_id,
      activityName: record.activity?.name_activity || 'N/A',
      category: record.activity?.category || 'N/A',
      dateCompleted: record.date?.toISOString() || record.created_at.toISOString(),
      scoreEarned: record.point ? Number(record.point) : 0,
      status: 'Completed',
    }));

    const rewards = parent.parent_and_medals.map((pm) => ({
      rewardId: pm.medals?.id || '',
      name: pm.medals?.name_medals || 'N/A',
      cost: pm.medals?.point_medals ? Number(pm.medals.point_medals) : 0,
    }));

    const recentRedemptions = parent.redemption.map((redemption) => ({
      id: redemption.redemption_id,
      rewardName: redemption.medals?.name_medals || 'N/A',
      childName: redemption.child?.name_surname || 'N/A',
      dateRedeemed: redemption.date_redemption?.toISOString() || redemption.created_at.toISOString(),
      scoreUsed: redemption.point_for_reward ? Number(redemption.point_for_reward) : 0,
    }));

    const userDetail = {
      id: parent.parent_id,
      userId: parent.user_id,
      fullName: parent.name_surname || 'N/A',
      email: parent.email,
      role: parent.ba_user?.role || 'user',
      status: 'Active',
      verification: 'Verified',
      photoUrl: parent.ba_user?.image ?? undefined,
      createdAt: parent.created_date.toISOString(),
      children,
      recentActivities,
      rewards,
      recentRedemptions,
    };

    return NextResponse.json(userDetail);
  } catch (error: any) {
    const params = await context.params;
    console.error(`GET /api/users/${params.id} error:`, error);
    return NextResponse.json(
      { error: 'Failed to fetch user detail', details: error.message },
      { status: 500 }
    );
  }
}

export async function PATCH(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const params = await context.params;
    const body = await request.json();
    const { role } = body;

    if (!role || !['user', 'admin'].includes(role)) {
      return NextResponse.json(
        { error: 'Invalid role. Must be "user" or "admin".' },
        { status: 400 }
      );
    }

    const parent = await prisma.parent.findUnique({
      where: { parent_id: params.id },
      select: { user_id: true },
    });

    if (!parent || !parent.user_id) {
      return NextResponse.json(
        { error: 'User not found or no linked auth user' },
        { status: 404 }
      );
    }

    await prisma.user.update({
      where: { id: parent.user_id },
      data: { role },
    });

    return NextResponse.json({ success: true, role });
  } catch (error: any) {
    const params = await context.params;
    console.error(`PATCH /api/users/${params.id} error:`, error);
    return NextResponse.json(
      { error: 'Failed to update role', details: error.message },
      { status: 500 }
    );
  }
}

/**
 * DELETE /api/users/[id]
 * Admin: permanently delete a parent account and their auth user.
 */
export async function DELETE(
  request: Request,
  context: { params: Promise<{ id: string }> }
) {
  try {
    const params = await context.params;

    const parent = await prisma.parent.findUnique({
      where: { parent_id: params.id },
      select: { user_id: true },
    });

    if (!parent) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 });
    }

    // Collect child IDs and medal IDs before cascade removes the join tables
    const parentChildren = await prisma.parent_and_child.findMany({
      where: { parent_id: params.id },
      select: { child_id: true },
    });
    const childIds = parentChildren.map(pc => pc.child_id).filter(Boolean) as string[];

    const parentMedals = await prisma.parent_and_medals.findMany({
      where: { parent_id: params.id },
      select: { medals_id: true },
    });
    const medalIds = parentMedals.map(pm => pm.medals_id).filter(Boolean) as string[];

    // Clear NoAction FK references to medals before deleting medals
    if (medalIds.length > 0) {
      await prisma.activity_record.deleteMany({ where: { medals_id: { in: medalIds } } });
      await prisma.redemption.deleteMany({ where: { medals_id: { in: medalIds } } });
      await prisma.medals.deleteMany({ where: { id: { in: medalIds } } });
    }

    // Clear NoAction FK references to children before deleting children
    if (childIds.length > 0) {
      await prisma.activity_record.deleteMany({ where: { child_id: { in: childIds } } });
      await prisma.redemption.deleteMany({ where: { child_id: { in: childIds } } });
    }

    // Delete activities created by this parent (onDelete: NoAction on parent FK)
    await prisma.activity.deleteMany({ where: { parent_id: params.id } });

    // Delete parent record (cascades: activity_record, parent_and_child, parent_and_medals, redemption)
    await prisma.parent.delete({ where: { parent_id: params.id } });

    // Delete children (now safe — all FK references cleared above)
    if (childIds.length > 0) {
      await prisma.child.deleteMany({ where: { child_id: { in: childIds } } });
    }

    // Delete Better Auth user (cascades sessions and accounts)
    if (parent.user_id) {
      await prisma.user.delete({ where: { id: parent.user_id } });
    }

    return NextResponse.json({ success: true });
  } catch (error: any) {
    const params = await context.params;
    console.error(`DELETE /api/users/${params.id} error:`, error);
    return NextResponse.json(
      { error: 'Failed to delete user', details: error.message },
      { status: 500 }
    );
  }
}
