/** @type {import('next').NextConfig} */
const nextConfig = {
  // Suppress workspace root warning
  outputFileTracingRoot: require('path').join(__dirname),

  // Production optimization
  experimental: {
    // Optimize for production builds
    optimizePackageImports: ['lucide-react'],
  },
}

module.exports = nextConfig
