'use client'

import { useEffect, useState } from 'react'
import { useRouter } from 'next/navigation'
import { authClient } from '@/lib/auth-client'
import { LogOut } from 'lucide-react'

interface UserData {
  email: string
  name?: string
}

export default function UserProfile() {
  const router = useRouter()
  const [user, setUser] = useState<UserData | null>(null)
  const [showMenu, setShowMenu] = useState(false)

  useEffect(() => {
    authClient.getSession().then(({ data: session }) => {
      if (session?.user) {
        setUser({
          email: session.user.email || '',
          name: session.user.name || session.user.email?.split('@')[0] || 'User',
        })
      }
    })
  }, [])

  const handleLogout = async () => {
    await authClient.signOut()
    router.push('/login')
  }

  if (!user) return null

  return (
    <div className="relative">
      <button
        onClick={() => setShowMenu(!showMenu)}
        className="flex items-center gap-3 px-4 py-2 bg-white border border-gray-200 rounded-lg hover:bg-gray-50 transition-colors"
      >
        <div className="flex items-center justify-center w-10 h-10 bg-gradient-to-br from-blue-500 to-purple-500 rounded-full text-white font-semibold">
          {user.name?.charAt(0).toUpperCase() || 'U'}
        </div>
        <div className="text-left">
          <p className="text-sm font-semibold text-gray-900">
            {user.name}
          </p>
          <p className="text-xs text-gray-500">
            Admin
          </p>
        </div>
      </button>

      {showMenu && (
        <>
          <div
            className="fixed inset-0 z-10"
            onClick={() => setShowMenu(false)}
          />
          <div className="absolute right-0 mt-2 w-64 bg-white rounded-lg shadow-xl border border-gray-200 py-2 z-20">
            <div className="px-4 py-3 border-b border-gray-100">
              <p className="text-sm font-semibold text-gray-900">
                {user.name}
              </p>
              <p className="text-xs text-gray-500 mt-1">
                {user.email}
              </p>
            </div>
            <div className="py-2">
              <button
                onClick={handleLogout}
                className="w-full px-4 py-2 text-left text-sm text-red-600 hover:bg-red-50 flex items-center gap-3 transition-colors"
              >
                <LogOut className="w-4 h-4" />
                ออกจากระบบ
              </button>
            </div>
          </div>
        </>
      )}
    </div>
  )
}
