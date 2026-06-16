import { createAuthClient } from 'better-auth/react'

export const authClient = createAuthClient({
  fetchOptions: {
    headers: {
      'ngrok-skip-browser-warning': 'true',
    },
  },
})
