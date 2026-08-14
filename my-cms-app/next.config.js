/** @type {import('next').NextConfig} */
const nextConfig = {
  // Suppress workspace root warning
  outputFileTracingRoot: require('path').join(__dirname),
  allowedDevOrigins: ['finisher-sandal-petted.ngrok-free.dev'],

  // Production optimization
  experimental: {
    // Optimize for production builds
    optimizePackageImports: ['lucide-react'],
    // Dance demonstration videos are uploaded through the authenticated proxy.
    // Keep this slightly above the application-level 200 MB limit to allow
    // multipart headers without Next.js truncating the request body.
    proxyClientMaxBodySize: '210mb',
  },
}

module.exports = nextConfig
