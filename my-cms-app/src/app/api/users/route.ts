// app/api/users/route.ts
import { NextResponse } from 'next/server';
import { prisma } from '@/lib/prisma';

export async function GET(request: Request) {
  try {
    const { searchParams } = new URL(request.url);
    const search = searchParams.get('search');
    const page = parseInt(searchParams.get('page') || '1');
    const limit = parseInt(searchParams.get('limit') || '10');
    const skip = (page - 1) * limit;

    // --- Admins (from ba_user, no parent record) ---
    const adminWhere: any = { role: 'admin' };
    if (search) {
      adminWhere.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } },
      ];
    }

    const admins = await prisma.user.findMany({
      where: adminWhere,
      orderBy: { createdAt: 'asc' },
      include: { accounts: { select: { providerId: true } } },
    });

    const adminRows = admins.map((u) => ({
      id: u.id,
      fullName: u.name,
      email: u.email,
      role: 'admin' as const,
      providers: u.accounts.map((a) => a.providerId),
      // status: 'Active',       // TODO: not yet implemented — hardcoded mock
      // verification: 'Verified', // TODO: not yet implemented — hardcoded mock
      photoUrl: u.image ?? undefined,
      createdAt: u.createdAt.toISOString(),
      childrenCount: 0,
      activityRecordCount: 0,
      isAdmin: true,
    }));

    // --- Regular users (from parent table) ---
    const parentWhere: any = {};
    if (search) {
      parentWhere.OR = [
        { name_surname: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } },
      ];
    }

    const totalCount = await prisma.parent.count({ where: parentWhere });
    const totalPages = Math.ceil(totalCount / limit);

    const parents = await prisma.parent.findMany({
      where: parentWhere,
      skip,
      take: limit,
      include: {
        parent_and_child: { select: { child_id: true } },
        activity_record: { select: { ActivityRecord_id: true } },
        ba_user: {
          select: {
            role: true,
            image: true,
            accounts: { select: { providerId: true } },
          },
        },
      },
      orderBy: { created_date: 'desc' },
    });

    const userRows = parents.map((parent) => ({
      id: parent.parent_id,
      fullName: parent.name_surname || 'N/A',
      email: parent.email,
      role: parent.ba_user?.role || 'user',
      providers: parent.ba_user?.accounts.map((a) => a.providerId) ?? [],
      // status: 'Active',       // TODO: not yet implemented — hardcoded mock
      // verification: 'Verified', // TODO: not yet implemented — hardcoded mock
      photoUrl: parent.ba_user?.image ?? undefined,
      createdAt: parent.created_date.toISOString(),
      childrenCount: parent.parent_and_child.length,
      activityRecordCount: parent.activity_record.length,
      isAdmin: false,
    }));

    // Admins always on top
    const users = [...adminRows, ...userRows];

    return NextResponse.json({
      users,
      pagination: {
        currentPage: page,
        totalPages,
        totalCount,
        limit,
      },
    });
  } catch (error: any) {
    console.error('GET /api/users error:', error);
    return NextResponse.json(
      { error: 'Failed to fetch users', details: error.message },
      { status: 500 }
    );
  }
}
