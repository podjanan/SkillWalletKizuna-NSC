import { NextRequest, NextResponse } from 'next/server'
import { prisma } from './prisma'
import { auth } from './auth'

interface AuthResult {
  user: { id: string; email: string; role: string }
  parent: { parent_id: string; name_surname: string; email: string; user_id: string }
  error?: undefined
}

interface AuthError {
  error: NextResponse
  user?: undefined
  parent?: undefined
}

/**
 * Get authenticated parent from request.
 * Supports both Bearer token (Flutter) and cookie (web) via Better Auth.
 */
export async function getAuthenticatedParent(
  request: NextRequest
): Promise<AuthResult | AuthError> {
  try {
    const session = await auth.api.getSession({ headers: request.headers })

    if (!session?.user) {
      return { error: NextResponse.json({ error: 'Unauthorized' }, { status: 401 }) }
    }

    const parentRow = await prisma.parent.findFirst({
      where: { user_id: session.user.id },
      select: { parent_id: true, name_surname: true, email: true, user_id: true },
    })

    if (!parentRow) {
      return {
        error: NextResponse.json(
          { error: 'Parent not found for this user' },
          { status: 404 }
        ),
      }
    }

    return {
      user: {
        id: session.user.id,
        email: session.user.email,
        role: (session.user as any).role ?? 'user',
      },
      parent: {
        parent_id: parentRow.parent_id,
        name_surname: parentRow.name_surname ?? '',
        email: parentRow.email,
        user_id: parentRow.user_id ?? '',
      },
    }
  } catch (err: any) {
    return {
      error: NextResponse.json(
        { error: 'Authentication failed', details: err.message },
        { status: 500 }
      ),
    }
  }
}
