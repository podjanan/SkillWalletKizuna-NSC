import { PrismaClient } from '@prisma/client'
import * as fs from 'fs'
import * as path from 'path'

// โหลดตัวแปรสภาพแวดล้อมจาก .env ด้วยตนเองก่อนนำเข้าโมดูลอื่น ๆ
function loadEnv() {
  const envPath = path.resolve(__dirname, '../.env')
  if (fs.existsSync(envPath)) {
    console.log(`📝 Loading environment variables from: ${envPath}`)
    const envConfig = fs.readFileSync(envPath, 'utf-8')
    for (const line of envConfig.split('\n')) {
      const trimmed = line.trim()
      if (!trimmed || trimmed.startsWith('#')) continue

      const match = trimmed.match(/^\s*([\w.-]+)\s*=\s*(.*)?\s*$/)
      if (match) {
        const key = match[1]
        let value = match[2] || ''
        if (value.startsWith('"') && value.endsWith('"')) {
          value = value.slice(1, -1)
        } else if (value.startsWith("'") && value.endsWith("'")) {
          value = value.slice(1, -1)
        }
        process.env[key] = value
      }
    }
  } else {
    console.warn(`⚠️ Warning: .env file not found at ${envPath}`)
  }
}

// เรียกโหลด Environment Variables
loadEnv()

// นำเข้า Better Auth และ Prisma ภายหลังจากโหลด Env แล้ว
import { auth } from '../src/lib/auth'
const prisma = new PrismaClient()

const ADMIN_EMAIL = 'admin@swk.local'
const ADMIN_PASSWORD = 'SwkAdmin2026!'
const ADMIN_NAME = 'SWK Admin'

async function main() {
  console.log('=' .repeat(60))
  console.log('SWK Admin Programmatic Seed Script')
  console.log('=' .repeat(60))
  console.log()

  // 1. ตรวจสอบว่ามีผู้ใช้คนนี้ในระบบหรือยัง
  const existing = await prisma.user.findUnique({ where: { email: ADMIN_EMAIL } })
  if (existing) {
    console.log(`User already exists: ${existing.email} (role: ${existing.role})`)
    if (existing.role !== 'admin') {
      await prisma.user.update({
        where: { email: ADMIN_EMAIL },
        data: { role: 'admin' },
      })
      console.log('  → Role updated to admin')
    }

    // ตรวจสอบตาราง parent
    const existingParent = await prisma.parent.findFirst({ where: { user_id: existing.id } })
    if (!existingParent) {
      await prisma.parent.create({
        data: {
          user_id: existing.id,
          email: ADMIN_EMAIL,
          name_surname: ADMIN_NAME,
        }
      })
      console.log('  → Created parent record for admin user')
    }
    return
  }

  // 2. สร้างผู้ใช้ผ่าน Better Auth API เพื่อให้ระบบแฮชรหัสผ่านให้โดยอัตโนมัติ
  console.log(`Creating user: ${ADMIN_NAME} (${ADMIN_EMAIL})...`)
  try {
    const response = await auth.api.signUpEmail({
      body: {
        email: ADMIN_EMAIL,
        password: ADMIN_PASSWORD,
        name: ADMIN_NAME,
      }
    })

    console.log('✅ User created successfully via Better Auth API!')

    // 3. กำหนดสิทธิ์ให้เป็น Admin ในระดับ Database
    const user = await prisma.user.findUnique({ where: { email: ADMIN_EMAIL } })
    if (user) {
      await prisma.user.update({
        where: { id: user.id },
        data: { role: 'admin' },
      })
      console.log('👑 Role updated to admin!')

      // 4. สร้างโปรไฟล์ผู้ปกครอง (Parent) ให้กับแอดมินด้วย
      await prisma.parent.create({
        data: {
          user_id: user.id,
          email: ADMIN_EMAIL,
          name_surname: ADMIN_NAME,
        }
      })
      console.log('👨‍👩‍👧‍👦 Parent record created successfully!')
    }
  } catch (error) {
    console.error('❌ Failed to create user:', error)
  }
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect())
