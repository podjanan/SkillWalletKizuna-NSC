import { auth } from './auth'
import { headers } from 'next/headers'

export type UserRole = 'user' | 'admin'

export function getUserRole(user: { role?: string }): UserRole {
  if (user.role === 'admin') return 'admin'
  return 'user'
}

export async function getServerSession() {
  const headersList = await headers()
  return auth.api.getSession({ headers: headersList })
}
