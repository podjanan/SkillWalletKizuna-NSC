import { betterAuth } from 'better-auth'
import { prismaAdapter } from 'better-auth/adapters/prisma'
import { bearer } from 'better-auth/plugins'
import { prisma } from './prisma'

export const auth = betterAuth({
  baseURL: process.env.BETTER_AUTH_URL,
  database: prismaAdapter(prisma, {
    provider: 'postgresql',
  }),
  emailAndPassword: {
    enabled: true,
  },
  socialProviders: {
    ...(process.env.GOOGLE_CLIENT_ID && process.env.GOOGLE_CLIENT_SECRET
      ? {
          google: {
            clientId: process.env.GOOGLE_CLIENT_ID,
            clientSecret: process.env.GOOGLE_CLIENT_SECRET,
          },
        }
      : {}),
    ...(process.env.FACEBOOK_APP_ID && process.env.FACEBOOK_APP_SECRET
      ? {
          facebook: {
            clientId: process.env.FACEBOOK_APP_ID,
            clientSecret: process.env.FACEBOOK_APP_SECRET,
          },
        }
      : {}),
  },
  plugins: [bearer()],
  account: {
    accountLinking: {
      enabled: true,
      trustedProviders: ['google', 'facebook'],
    },
  },
  user: {
    additionalFields: {
      role: {
        type: 'string',
        defaultValue: 'user',
        input: false,
      },
    },
  },
  trustedOrigins: [
    'http://localhost:3000',
    'http://localhost:3001',
    'http://localhost:*',
    'http://127.0.0.1:*',
    'http://10.0.2.2:*',
    'https://skillwalletkool.duckdns.org',
    'https://skillwalletkizuna.duckdns.org',
    `http://103.216.158.225:3000`,
    process.env.BETTER_AUTH_TRUSTED_ORIGIN,
  ].filter(Boolean) as string[],
})
