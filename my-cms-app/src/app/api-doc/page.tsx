'use client';

import dynamic from 'next/dynamic';
import 'swagger-ui-react/swagger-ui.css';

const SwaggerUI = dynamic(() => import('swagger-ui-react'), { ssr: false });

export default function ApiDocPage() {
  return (
    <div className="min-h-screen bg-gray--light1">
      {/* Header */}
      <div className="bg-white border-b border-gray4 px-8 py-4 flex items-center justify-between">
        <div>
          <h1 className="heading-h5 text-dark">Skill Wallet Kizuna — API Reference</h1>
          <p className="body-small-regular text-secondary--text mt-1">
            Backend API สำหรับ Flutter App และ Admin CMS
          </p>
        </div>
        <span className="body-xs-medium px-3 py-1 bg-green--light6 text-green--dark rounded-full">
          v1.0.0
        </span>
      </div>

      {/* Warning banner */}
      <div className="mx-8 mt-4 px-4 py-3 bg-yellow--light3 border border-yellow--light rounded-lg flex items-start gap-3">
        <span className="body-small-bold text-dark mt-0.5">⚠️</span>
        <p className="body-small-regular text-dark">
          การกด <strong>Execute</strong> จะส่ง request จริงไปยัง database — แนะนำใช้เฉพาะ GET สำหรับการทดสอบ
        </p>
      </div>

      {/* Swagger UI */}
      <div className="px-8 py-6">
        <div className="bg-white rounded-lg shadow overflow-hidden">
          <SwaggerUI url="/api/api-doc" />
        </div>
      </div>
    </div>
  );
}
