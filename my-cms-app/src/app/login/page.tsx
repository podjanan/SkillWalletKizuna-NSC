'use client'

import { useRouter, useSearchParams } from 'next/navigation'
import { useState, useEffect, Suspense } from 'react'
import { authClient } from '@/lib/auth-client'
import { LogIn, Mail, Lock, AlertCircle } from 'lucide-react'

function LoginForm() {
  const router = useRouter()
  const searchParams = useSearchParams()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    const urlError = searchParams.get('error')
    if (urlError === 'unauthorized') {
      setError('คุณไม่มีสิทธิ์เข้าถึงระบบนี้ เฉพาะผู้ดูแลระบบเท่านั้น')
    }
  }, [searchParams])

  // Redirect if already logged in as admin
  useEffect(() => {
    authClient.getSession().then(({ data: session }) => {
      if ((session?.user as any)?.role === 'admin') {
        router.push('/admin/activities')
      }
    })
  }, [router])

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault()
    setError('')
    setLoading(true)

    try {
      const { data, error: signInError } = await authClient.signIn.email({
        email,
        password,
      })

      if (signInError) {
        setError(signInError.message || 'เข้าสู่ระบบไม่สำเร็จ')
        return
      }

      const role = (data?.user as any)?.role
      if (role !== 'admin') {
        await authClient.signOut()
        setError('คุณไม่มีสิทธิ์เข้าถึงระบบนี้ เฉพาะผู้ดูแลระบบเท่านั้น')
        return
      }

      window.location.href = '/admin/activities'
    } catch {
      setError('เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-purple--light6 via-white to-purple--light5 flex items-center justify-center p-4">
      <div className="w-full max-w-md">
        {/* Card Container */}
        <div className="bg-white rounded-2xl shadow-2xl overflow-hidden border border-gray4">
          {/* Header Section */}
          <div className="bg-gradient-to-r from-purple to-purple--dark px-8 py-10 text-center">
            <div className="flex justify-center mb-4">
            </div>
            <h1 className="heading-h2 text-white mb-2">
              Skill Wallet Kizuna
            </h1>
            <p className="body-small-regular text-white/90">
              Admin Content Management System
            </p>
          </div>

          {/* Form Section */}
          <div className="px-8 py-10">
            <h2 className="heading-h4 mb-2 text-center">
              เข้าสู่ระบบ
            </h2>
            <p className="body-small-regular text-secondary--text text-center mb-8">
              กรุณาเข้าสู่ระบบเพื่อจัดการเนื้อหา
            </p>

            <form onSubmit={handleLogin} className="space-y-6">
              {/* Email Input */}
              <div>
                <label htmlFor="email" className="block body-small-medium mb-2">
                  อีเมล
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Mail className="h-5 w-5 text-secondary--text" />
                  </div>
                  <input
                    id="email"
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="your@email.com"
                    required
                    className="block w-full pl-10 pr-3 py-3 border border-gray6 rounded-lg body-medium-regular focus:ring-2 focus:ring-purple focus:border-purple transition-colors"
                  />
                </div>
              </div>

              {/* Password Input */}
              <div>
                <label htmlFor="password" className="block body-small-medium mb-2">
                  รหัสผ่าน
                </label>
                <div className="relative">
                  <div className="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                    <Lock className="h-5 w-5 text-secondary--text" />
                  </div>
                  <input
                    id="password"
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••"
                    required
                    className="block w-full pl-10 pr-3 py-3 border border-gray6 rounded-lg body-medium-regular focus:ring-2 focus:ring-purple focus:border-purple transition-colors"
                  />
                </div>
              </div>

              {/* Error Message */}
              {error && (
                <div className="bg-red--light1 border border-red rounded-lg p-4 flex items-start gap-3">
                  <AlertCircle className="h-5 w-5 text-red flex-shrink-0 mt-0.5" />
                  <div className="flex-1">
                    <p className="body-small-medium text-red--dark">เข้าสู่ระบบไม่สำเร็จ</p>
                    <p className="body-small-regular text-red mt-1">{error}</p>
                  </div>
                </div>
              )}

              {/* Submit Button */}
              <button
                type="submit"
                disabled={loading}
                className="btn-primary w-full py-3 px-4 rounded-lg transition-all duration-200 transform hover:scale-[1.02] active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none flex items-center justify-center gap-2"
              >
                {loading ? (
                  <>
                    <svg className="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                      <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                      <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                    </svg>
                    กำลังเข้าสู่ระบบ...
                  </>
                ) : (
                  <>
                    <LogIn className="h-5 w-5" />
                    เข้าสู่ระบบ
                  </>
                )}
              </button>
            </form>
          </div>

          {/* Footer */}
          <div className="bg-gray--light1 px-8 py-4 border-t border-gray4">
            <p className="body-xs-regular text-secondary--text text-center">
              © 2026 Skill Wallet Kizuna. All rights reserved.
            </p>
          </div>
        </div>

        {/* Help Text */}
        <p className="text-center mt-6 body-small-regular text-secondary--text">
          ต้องการความช่วยเหลือ? ติดต่อผู้ดูแลระบบ
        </p>
      </div>
    </div>
  )
}

export default function LoginPage() {
  return (
    <Suspense>
      <LoginForm />
    </Suspense>
  )
}
