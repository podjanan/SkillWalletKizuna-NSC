import { PrismaClient } from '@prisma/client'
import * as fs from 'fs'
import * as path from 'path'

function loadEnv() {
  const envPath = path.resolve(__dirname, '../.env')
  if (fs.existsSync(envPath)) {
    const envConfig = fs.readFileSync(envPath, 'utf-8')
    for (const line of envConfig.split('\n')) {
      const trimmed = line.trim()
      if (!trimmed || trimmed.startsWith('#')) continue
      const match = trimmed.match(/^\s*([\w.-]+)\s*=\s*(.*)?\s*$/)
      if (match) {
        const key = match[1]
        let value = match[2] || ''
        if (value.startsWith('"') && value.endsWith('"')) value = value.slice(1, -1)
        process.env[key] = value
      }
    }
  }
}
loadEnv()

const prisma = new PrismaClient()

async function main() {
  const user = await prisma.user.findUnique({
    where: { email: 'admin@swk.local' },
    include: {
      accounts: true,
      sessions: true,
    }
  })
  console.log('User Record:', JSON.stringify(user, null, 2))
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect())
