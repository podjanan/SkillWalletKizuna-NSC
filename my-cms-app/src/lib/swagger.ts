// lib/swagger.ts
import { createSwaggerSpec } from 'next-swagger-doc';

function getServers() {
  const servers: { url: string; description: string }[] = [];
  if (process.env.NODE_ENV === 'development') {
    servers.push({ url: 'http://localhost:3000', description: 'Local Development' });
  }
  if (process.env.NEXT_PUBLIC_API_URL) {
    servers.push({ url: process.env.NEXT_PUBLIC_API_URL, description: 'Production' });
  }
  if (servers.length === 0) {
    servers.push({ url: 'http://localhost:3000', description: 'Default' });
  }
  return servers;
}

const BearerAuth = { bearerAuth: [] };

// ---- Real UUIDs from DB ----
const EX = {
  activityIdLang:     '199b25bb-62ee-4252-b3d6-776bcb5438bb',
  activityIdCalc:     '3ed75a53-ec81-45bf-868a-19f82a557051',
  activityIdPhys:     'f67e4fa1-664f-48b1-8ddb-6e3279739317',
  parentId:           'd8270438-f781-4974-83cf-7a639d84ff25',
  parentId2:          'b7144b24-4646-4633-b63e-8ddc062e2b2b',
  childId:            'd8dc80f8-3e0c-419c-85f0-a66b3ef06b60',
  childId2:           '02dd8546-2587-4b3f-ae2f-67c751c4f1ce',
  medalId:            'c4b30733-b797-41a5-a4f9-cc53cd8e6f42',
  medalId2:           '162eb6a2-0c26-43e5-92e4-2c8ea0b64b3c',
  recordId:           '7668075e-bca1-40b6-b02b-f819fb4e2929',
  redemptionId:       '801e8f4a-527e-4779-be6d-9ba30a2edccf',
};

export const getApiDocs = () => {
  return createSwaggerSpec({
    apiFolder: 'src/app/api',
    definition: {
      openapi: '3.0.0',
      info: {
        title: 'Skill Wallet Kizuna — Backend API',
        version: '1.0.0',
        description: `
## ภาพรวมระบบ

**Skill Wallet Kizuna** คือแพลตฟอร์มส่งเสริมการเรียนรู้สำหรับเด็ก โดยผู้ปกครองสามารถกำหนดกิจกรรม ติดตามผล และมอบรางวัลเป็น Wallet Points ที่เด็กสามารถแลกของรางวัลได้

API นี้รองรับทั้ง **Flutter Mobile App** และ **Admin CMS** (Next.js)

---

## 🔐 Authentication

| วิธี | ใช้เมื่อ | วิธีส่ง |
|---|---|---|
| **Bearer Token** | Flutter/Mobile App | \`Authorization: Bearer <supabase_access_token>\` |
| **Cookie Session** | Admin CMS (browser) | ส่งอัตโนมัติผ่าน Supabase cookie |
| **API Key** | Server-to-server | \`X-API-Key: <key>\` |

> Token ได้จาก \`supabase.auth.getSession().session.access_token\` — มีอายุ 1 ชั่วโมง ต้อง refresh ก่อนหมดอายุ

---

## 📚 ประเภทกิจกรรม (Category)

| Category | รูปแบบ | แหล่งเนื้อหา | segments |
|---|---|---|---|
| \`ด้านภาษา\` | ดูวิดีโอ + ตอบ subtitle | YouTube | \`[{ id, start, end, text }]\` |
| \`ด้านร่างกาย\` | ดูสาธิตและทำตาม | TikTok | \`null\` |
| \`ด้านคำนวณ\` | ตอบคำถาม Q&A | ระบบภายใน | \`[{ id, question, answer, hint, score }]\` |

---

## 💰 ระบบ Wallet & Rewards

- เด็กแต่ละคนมี **Wallet Points** สะสมจากการทำกิจกรรมครบ
- ผู้ปกครองสร้าง **Medal (รางวัล)** พร้อมกำหนดราคา (points)
- เด็กแลก Medal ผ่าน \`POST /children/{id}/redeem-medal\`
- ผู้ปกครองยืนยันการแลกผ่าน \`POST /children/{id}/redemptions/{rid}/confirm\`
        `,
        contact: { name: 'Skill Wallet Kizuna Team' },
      },
      servers: getServers(),
      components: {
        securitySchemes: {
          bearerAuth: {
            type: 'http',
            scheme: 'bearer',
            bearerFormat: 'JWT',
            description: 'Supabase Access Token จาก `supabase.auth.getSession()`',
          },
        },
        schemas: {
          Error: {
            type: 'object',
            properties: {
              error: { type: 'string', example: 'Something went wrong' },
            },
          },
          Pagination: {
            type: 'object',
            properties: {
              currentPage:  { type: 'integer', example: 1 },
              totalPages:   { type: 'integer', example: 3 },
              total:        { type: 'integer', example: 28 },
              limit:        { type: 'integer', example: 10 },
            },
          },
          Activity: {
            type: 'object',
            properties: {
              activityId:          { type: 'string', format: 'uuid', example: EX.activityIdLang },
              nameActivity:        { type: 'string', example: '5-Minute English Conversation Practice' },
              category:            { type: 'string', enum: ['ด้านภาษา', 'ด้านร่างกาย', 'ด้านคำนวณ'], example: 'ด้านภาษา' },
              descriptionActivity: { type: 'string', example: 'ฝึกบทสนทนาภาษาอังกฤษ 5 นาที เกี่ยวกับความฝันและแผนในอนาคต' },
              content:             { type: 'string', example: 'Video Source: YouTube ID 8fEo9YvaUcg' },
              difficulty:          { type: 'string', enum: ['ง่าย', 'กลาง', 'ยาก'], example: 'กลาง' },
              maxScore:            { type: 'number', example: 135 },
              videoUrl:            { type: 'string', nullable: true, example: 'https://www.youtube.com/watch?v=8fEo9YvaUcg' },
              thumbnailUrl:        { type: 'string', nullable: true, example: null },
              tiktokHtmlContent:   { type: 'string', nullable: true, example: null },
              segments: {
                nullable: true,
                example: [
                  { id: 'seg_1773932681427_0', start: 11.8, end: 14.2, text: 'Hi, John!' },
                  { id: 'seg_1773932681427_1', start: 14.2, end: 15.4, text: 'Hi, Jessica!' },
                ],
              },
              playCount:  { type: 'number', example: 15 },
              isPublic:   { type: 'boolean', example: true },
              parentId:   { type: 'string', format: 'uuid', example: EX.parentId },
              createdAt:  { type: 'string', format: 'date-time', example: '2026-03-19T15:04:51.387Z' },
              updatedAt:  { type: 'string', format: 'date-time', example: '2026-03-19T15:04:51.381Z' },
            },
          },
          Child: {
            type: 'object',
            properties: {
              child_id:     { type: 'string', format: 'uuid', example: EX.childId },
              name_surname: { type: 'string', example: 'อรณะภา รพรี' },
              birthday:     { type: 'string', format: 'date-time', nullable: true, example: '2016-02-12T00:00:00.000Z' },
              wallet:       { type: 'number', example: 509 },
              update_wallet:{ type: 'number', nullable: true, example: 1035 },
              photo_url:    { type: 'string', nullable: true, example: null },
            },
          },
          Parent: {
            type: 'object',
            properties: {
              parentId:    { type: 'string', format: 'uuid', example: EX.parentId },
              nameSurname: { type: 'string', nullable: true, example: 'สมชาย ใจดี' },
              email:       { type: 'string', format: 'email', example: 'parent@example.com' },
            },
          },
          Medal: {
            type: 'object',
            properties: {
              id:           { type: 'string', format: 'uuid', example: EX.medalId },
              name_medals:  { type: 'string', example: 'ยูทูป สิบนาที' },
              point_medals: { type: 'number', example: 100 },
              created_at:   { type: 'string', format: 'date-time', example: '2026-02-02T19:54:56.712Z' },
            },
          },
          ActivityRecord: {
            type: 'object',
            properties: {
              ActivityRecord_id: { type: 'string', format: 'uuid', example: EX.recordId },
              child_id:          { type: 'string', format: 'uuid', example: EX.childId },
              activity_id:       { type: 'string', format: 'uuid', example: EX.activityIdCalc },
              parent_id:         { type: 'string', format: 'uuid', example: EX.parentId },
              point:             { type: 'number', example: 31 },
              time_spent:        { type: 'number', example: 7, description: 'วินาที' },
              date:              { type: 'string', format: 'date-time', example: '2026-02-27T03:16:30.996Z' },
              segment_results: {
                nullable: true,
                example: [
                  { id: 'q_1772144979516', text: '2+9', maxScore: 10, recognizedText: '11' },
                  { id: 'q_1772144992693', text: '78-6', maxScore: 10, recognizedText: '72' },
                ],
              },
              evidence: {
                nullable: true,
                example: {
                  status: 'Pending Approval',
                  description: null,
                  imagePathLocal: null,
                  videoPathLocal: null,
                },
              },
            },
          },
        },
      },

      tags: [
        { name: 'Activities',       description: '📚 กิจกรรมการเรียนรู้ — ดึง สร้าง แก้ไข ลบ' },
        { name: 'Parents',          description: '👨‍👩‍👧 ข้อมูลและรูปโปรไฟล์ผู้ปกครอง' },
        { name: 'Children',         description: '👶 จัดการข้อมูลเด็ก กระเป๋าคะแนน และรูปโปรไฟล์' },
        { name: 'Rewards',          description: '🎁 รางวัลและการแลกคะแนน' },
        { name: 'Activity Records', description: '📊 บันทึกผลกิจกรรมและปรับคะแนน' },
        { name: 'AI & Video',       description: '🤖 AI ประเมินการออกเสียง + ดึงข้อมูลวิดีโอ YouTube/TikTok' },
        { name: 'Admin',            description: '🔐 จัดการผู้ใช้ทั้งหมด (Admin only)' },
      ],

      paths: {

        // ============================================================
        // ACTIVITIES
        // ============================================================
        '/api/activities': {
          get: {
            tags: ['Activities'],
            summary: 'ดึงรายการกิจกรรมทั้งหมด',
            description: 'รองรับ filter, sort, pagination — ใช้ได้ทั้ง Flutter และ Admin CMS',
            parameters: [
              { name: 'page',      in: 'query', schema: { type: 'integer', default: 1 },   description: 'หน้าที่ต้องการ' },
              { name: 'limit',     in: 'query', schema: { type: 'integer', default: 10 },  description: 'จำนวนต่อหน้า' },
              { name: 'search',    in: 'query', schema: { type: 'string' },                description: 'ค้นหาจากชื่อกิจกรรม' },
              { name: 'category',  in: 'query', schema: { type: 'string', enum: ['ด้านภาษา', 'ด้านร่างกาย', 'ด้านคำนวณ'] }, description: 'กรองตาม category' },
              { name: 'level',     in: 'query', schema: { type: 'string', enum: ['ง่าย', 'กลาง', 'ยาก'] },                  description: 'กรองตามระดับความยาก' },
              { name: 'parentId',  in: 'query', schema: { type: 'string', example: EX.parentId },                            description: 'แสดง public + กิจกรรมของ parent นี้' },
              { name: 'ownedBy',   in: 'query', schema: { type: 'string', example: EX.parentId },                            description: 'แสดงเฉพาะกิจกรรมที่ parent นี้สร้าง' },
              { name: 'sortBy',    in: 'query', schema: { type: 'string', enum: ['created_at', 'play_count'], default: 'created_at' } },
              { name: 'sortOrder', in: 'query', schema: { type: 'string', enum: ['asc', 'desc'], default: 'desc' } },
            ],
            responses: {
              200: {
                description: 'สำเร็จ',
                content: {
                  'application/json': {
                    schema: {
                      type: 'object',
                      properties: {
                        success:    { type: 'boolean', example: true },
                        data:       { type: 'array', items: { $ref: '#/components/schemas/Activity' } },
                        pagination: { $ref: '#/components/schemas/Pagination' },
                      },
                    },
                    example: {
                      success: true,
                      data: [
                        {
                          activityId: EX.activityIdLang,
                          nameActivity: '5-Minute English Conversation Practice',
                          category: 'ด้านภาษา',
                          descriptionActivity: 'ฝึกบทสนทนาภาษาอังกฤษ 5 นาที',
                          content: 'Video Source: YouTube ID 8fEo9YvaUcg',
                          difficulty: 'กลาง',
                          maxScore: 135,
                          videoUrl: 'https://www.youtube.com/watch?v=8fEo9YvaUcg',
                          thumbnailUrl: null,
                          tiktokHtmlContent: null,
                          segments: [
                            { id: 'seg_1773932681427_0', start: 11.8, end: 14.2, text: 'Hi, John!' },
                            { id: 'seg_1773932681427_1', start: 14.2, end: 15.4, text: 'Hi, Jessica!' },
                          ],
                          playCount: 0,
                          isPublic: true,
                          parentId: EX.parentId,
                          createdAt: '2026-03-19T15:04:51.387Z',
                          updatedAt: '2026-03-19T15:04:51.381Z',
                        },
                        {
                          activityId: EX.activityIdPhys,
                          nameActivity: 'Cup pyramid with flashcards',
                          category: 'ด้านร่างกาย',
                          descriptionActivity: 'Cup pyramid + flashcards = FUN English learning',
                          content: 'วิ่งไปหยิบถ้วยทีละใบและสร้างพีระมิด ผู้ที่หาการ์ดคำศัพท์ได้ก่อนชนะ',
                          difficulty: 'กลาง',
                          maxScore: 100,
                          videoUrl: 'https://www.tiktok.com/@teacher.rahman/video/7587077060342975764',
                          thumbnailUrl: null,
                          segments: null,
                          playCount: 15,
                          isPublic: true,
                          parentId: EX.parentId,
                          createdAt: '2026-02-02T10:56:16.037Z',
                          updatedAt: '2026-02-09T10:24:45.921Z',
                        },
                        {
                          activityId: EX.activityIdCalc,
                          nameActivity: 'การบ้านคณิต',
                          category: 'ด้านคำนวณ',
                          descriptionActivity: 'การบ้านของน้องกอล์ฟ วันที่ 3/4/69',
                          content: 'ตั้งใจคิด คณิต ป.2',
                          difficulty: 'กลาง',
                          maxScore: 31,
                          videoUrl: null,
                          segments: [
                            { id: 'q_1772144979516', hint: '', score: 10, answer: '11',  question: '2+9' },
                            { id: 'q_1772144992693', hint: '', score: 10, answer: '72',  question: '78-6' },
                            { id: 'q_1772145001956', hint: '', score: 10, answer: '109', question: '47+62' },
                            { id: 'q_1772145018545', hint: '', score: 1,  answer: '788', question: '665+123' },
                          ],
                          playCount: 1,
                          isPublic: true,
                          parentId: EX.parentId2,
                          createdAt: '2026-02-26T22:30:34.174Z',
                          updatedAt: '2026-02-26T22:30:34.143Z',
                        },
                      ],
                      pagination: { currentPage: 1, totalPages: 3, total: 28, limit: 10 },
                    },
                  },
                },
              },
            },
          },
          post: {
            tags: ['Activities'],
            summary: 'สร้างกิจกรรมใหม่',
            security: [BearerAuth],
            requestBody: {
              required: true,
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    required: ['name', 'category', 'content', 'difficulty', 'maxScore', 'parentId'],
                    properties: {
                      name:        { type: 'string' },
                      category:    { type: 'string', enum: ['ด้านภาษา', 'ด้านร่างกาย', 'ด้านคำนวณ'] },
                      content:     { type: 'string' },
                      difficulty:  { type: 'string', enum: ['ง่าย', 'กลาง', 'ยาก'] },
                      maxScore:    { type: 'number' },
                      parentId:    { type: 'string', format: 'uuid' },
                      description: { type: 'string' },
                      videoUrl:    { type: 'string' },
                      thumbnailUrl:{ type: 'string' },
                      isPublic:    { type: 'boolean', default: true },
                      segments:    { type: 'array', items: { type: 'object' } },
                    },
                  },
                  example: {
                    name: 'การบ้านคณิต ป.2',
                    category: 'ด้านคำนวณ',
                    content: 'ตั้งใจคิด คำนวณให้ถูกต้อง',
                    difficulty: 'กลาง',
                    maxScore: 31,
                    parentId: EX.parentId2,
                    description: 'การบ้านคณิตศาสตร์ ป.2 ฝึกบวกลบ',
                    videoUrl: null,
                    isPublic: true,
                    segments: [
                      { id: 'q_1', hint: '', score: 10, answer: '11',  question: '2+9' },
                      { id: 'q_2', hint: '', score: 10, answer: '72',  question: '78-6' },
                      { id: 'q_3', hint: '', score: 11, answer: '109', question: '47+62' },
                    ],
                  },
                },
              },
            },
            responses: {
              201: {
                description: 'สร้างสำเร็จ',
                content: {
                  'application/json': {
                    schema: { $ref: '#/components/schemas/Activity' },
                    example: {
                      activityId: EX.activityIdCalc,
                      nameActivity: 'การบ้านคณิต ป.2',
                      category: 'ด้านคำนวณ',
                      maxScore: 31,
                      isPublic: true,
                      createdAt: '2026-02-26T22:30:34.174Z',
                    },
                  },
                },
              },
              400: { description: 'ข้อมูลไม่ครบหรือไม่ถูกต้อง', content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' } } } },
            },
          },
        },

        '/api/activities/{id}': {
          get: {
            tags: ['Activities'],
            summary: 'ดึงกิจกรรมตาม ID',
            parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' }, example: EX.activityIdPhys }],
            responses: {
              200: {
                description: 'สำเร็จ',
                content: {
                  'application/json': {
                    schema: { $ref: '#/components/schemas/Activity' },
                    example: {
                      activityId: EX.activityIdPhys,
                      nameActivity: 'Cup pyramid with flashcards',
                      category: 'ด้านร่างกาย',
                      descriptionActivity: 'Cup pyramid + flashcards = FUN English learning',
                      content: 'วิ่งไปหยิบถ้วยทีละใบและสร้างพีระมิด ผู้ที่หาการ์ดคำศัพท์ได้ก่อนชนะ',
                      difficulty: 'กลาง',
                      maxScore: 100,
                      videoUrl: 'https://www.tiktok.com/@teacher.rahman/video/7587077060342975764',
                      segments: null,
                      playCount: 15,
                      isPublic: true,
                      parentId: EX.parentId,
                      createdAt: '2026-02-02T10:56:16.037Z',
                    },
                  },
                },
              },
              404: { description: 'ไม่พบกิจกรรม', content: { 'application/json': { schema: { $ref: '#/components/schemas/Error' }, example: { error: 'Activity not found' } } } },
            },
          },
          patch: {
            tags: ['Activities'],
            summary: 'แก้ไขกิจกรรม',
            security: [BearerAuth],
            parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' }, example: EX.activityIdCalc }],
            requestBody: {
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    properties: {
                      name:        { type: 'string' },
                      category:    { type: 'string' },
                      content:     { type: 'string' },
                      difficulty:  { type: 'string' },
                      maxScore:    { type: 'number' },
                      description: { type: 'string' },
                      videoUrl:    { type: 'string' },
                      thumbnailUrl:{ type: 'string' },
                      isPublic:    { type: 'boolean' },
                      segments:    { type: 'array', items: { type: 'object' } },
                    },
                  },
                  example: { isPublic: false, maxScore: 40 },
                },
              },
            },
            responses: {
              200: { description: 'แก้ไขสำเร็จ', content: { 'application/json': { schema: { $ref: '#/components/schemas/Activity' } } } },
              404: { description: 'ไม่พบกิจกรรม' },
            },
          },
          delete: {
            tags: ['Activities'],
            summary: 'ลบกิจกรรม',
            security: [BearerAuth],
            parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' }, example: EX.activityIdCalc }],
            responses: {
              204: { description: 'ลบสำเร็จ' },
              404: { description: 'ไม่พบกิจกรรม' },
            },
          },
        },

        // ============================================================
        // PARENTS
        // ============================================================
        '/api/parents/me': {
          get: {
            tags: ['Parents'],
            summary: 'ดึงข้อมูล parent ของตัวเอง',
            security: [BearerAuth],
            responses: {
              200: {
                description: 'สำเร็จ',
                content: {
                  'application/json': {
                    schema: { $ref: '#/components/schemas/Parent' },
                    example: { parentId: EX.parentId, nameSurname: 'สมชาย ใจดี', email: 'aiiadorarin@gmail.com' },
                  },
                },
              },
              401: { description: 'ไม่ได้ login' },
              404: { description: 'ไม่พบ parent profile — ต้อง sync ก่อน' },
            },
          },
        },

        '/api/parents/sync': {
          post: {
            tags: ['Parents'],
            summary: 'Sync ข้อมูล parent หลัง login',
            description: 'เรียกหลัง login ทุกครั้ง — สร้างหรืออัปเดต parent record ใน database อัตโนมัติ',
            security: [BearerAuth],
            requestBody: {
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    properties: {
                      email:    { type: 'string', format: 'email' },
                      fullName: { type: 'string' },
                    },
                  },
                  example: { email: 'parent@example.com', fullName: 'สมชาย ใจดี' },
                },
              },
            },
            responses: {
              200: {
                description: 'Sync สำเร็จ',
                content: {
                  'application/json': {
                    example: {
                      success: true,
                      parent: { parentId: EX.parentId, nameSurname: 'สมชาย ใจดี', email: 'parent@example.com' },
                    },
                  },
                },
              },
            },
          },
        },

        '/api/parents/photo': {
          post: {
            tags: ['Parents'],
            summary: 'อัปโหลดรูปโปรไฟล์ผู้ปกครอง',
            description: 'อัปโหลดรูปไปยัง Supabase Storage bucket `avatars` แล้วอัปเดต user metadata',
            security: [BearerAuth],
            requestBody: {
              required: true,
              content: {
                'multipart/form-data': {
                  schema: {
                    type: 'object',
                    required: ['photo'],
                    properties: {
                      photo: {
                        type: 'string',
                        format: 'binary',
                        description: 'ไฟล์รูปภาพ (JPEG, PNG, WebP — ไม่เกิน 5 MB)',
                      },
                    },
                  },
                },
              },
            },
            responses: {
              200: {
                description: 'อัปโหลดสำเร็จ',
                content: {
                  'application/json': {
                    example: {
                      success: true,
                      photoUrl: 'https://xxxx.supabase.co/storage/v1/object/public/avatars/86562d56-c225-4256-a4d3-13441d654ea0/profile.jpg?v=1748000000000',
                    },
                  },
                },
              },
              400: { description: 'ไม่ส่งไฟล์ / ไฟล์ใหญ่เกิน / ประเภทไฟล์ไม่รองรับ' },
              401: { description: 'ไม่ได้ login' },
            },
          },
        },

        // ============================================================
        // CHILDREN
        // ============================================================
        '/api/children': {
          get: {
            tags: ['Children'],
            summary: 'ดึงรายชื่อเด็กทั้งหมดของ parent',
            security: [BearerAuth],
            responses: {
              200: {
                description: 'สำเร็จ',
                content: {
                  'application/json': {
                    example: [
                      {
                        child_id: EX.childId,
                        relationship: 'ลูก',
                        child: {
                          child_id: EX.childId,
                          name_surname: 'อรณะภา รพรี',
                          birthday: '2016-02-12T00:00:00.000Z',
                          wallet: 509,
                          update_wallet: 1035,
                          photo_url: null,
                        },
                      },
                      {
                        child_id: EX.childId2,
                        relationship: 'ลูก',
                        child: {
                          child_id: EX.childId2,
                          name_surname: 'Natu',
                          birthday: '2021-02-02T00:00:00.000Z',
                          wallet: 0,
                          update_wallet: null,
                          photo_url: null,
                        },
                      },
                    ],
                  },
                },
              },
            },
          },
          post: {
            tags: ['Children'],
            summary: 'เพิ่มเด็กใหม่',
            security: [BearerAuth],
            requestBody: {
              required: true,
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    required: ['fullName'],
                    properties: {
                      fullName:     { type: 'string' },
                      birthday:     { type: 'string', format: 'date' },
                      relationship: { type: 'string' },
                    },
                  },
                  example: { fullName: 'ด.ช.สมศักดิ์ ใจดี', birthday: '2018-07-20', relationship: 'ลูก' },
                },
              },
            },
            responses: {
              201: {
                description: 'เพิ่มสำเร็จ',
                content: {
                  'application/json': {
                    example: {
                      child_id: '02dd8546-2587-4b3f-ae2f-67c751c4f1ce',
                      name_surname: 'ด.ช.สมศักดิ์ ใจดี',
                      birthday: '2018-07-20T00:00:00.000Z',
                      wallet: 0,
                      photo_url: null,
                    },
                  },
                },
              },
              400: { description: 'ข้อมูลไม่ครบ' },
            },
          },
        },

        '/api/children/{id}': {
          get: {
            tags: ['Children'],
            summary: 'ดึงข้อมูลเด็กตาม ID',
            security: [BearerAuth],
            parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' }, example: EX.childId }],
            responses: {
              200: {
                description: 'สำเร็จ',
                content: {
                  'application/json': {
                    schema: { $ref: '#/components/schemas/Child' },
                    example: {
                      child_id: EX.childId,
                      name_surname: 'อรณะภา รพรี',
                      birthday: '2016-02-12T00:00:00.000Z',
                      wallet: 509,
                      update_wallet: 1035,
                      photo_url: null,
                    },
                  },
                },
              },
              403: { description: 'ไม่มีสิทธิ์เข้าถึงเด็กคนนี้' },
              404: { description: 'ไม่พบเด็ก' },
            },
          },
          patch: {
            tags: ['Children'],
            summary: 'แก้ไขข้อมูลเด็ก',
            security: [BearerAuth],
            parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' }, example: EX.childId }],
            requestBody: {
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    properties: {
                      fullName: { type: 'string' },
                      birthday: { type: 'string', format: 'date' },
                      photoUrl: { type: 'string' },
                    },
                  },
                  example: { fullName: 'อรณะภา รพรี', birthday: '2016-02-12' },
                },
              },
            },
            responses: {
              200: {
                description: 'แก้ไขสำเร็จ',
                content: {
                  'application/json': {
                    example: { child_id: EX.childId, name_surname: 'อรณะภา รพรี', wallet: 509 },
                  },
                },
              },
            },
          },
          delete: {
            tags: ['Children'],
            summary: 'ลบเด็กออกจาก parent',
            security: [BearerAuth],
            parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' }, example: EX.childId2 }],
            responses: {
              200: { description: 'ลบสำเร็จ', content: { 'application/json': { example: { success: true } } } },
            },
          },
        },

        '/api/children/{id}/photo': {
          post: {
            tags: ['Children'],
            summary: 'อัปโหลดรูปโปรไฟล์เด็ก',
            description: 'อัปโหลดรูปไปยัง Supabase Storage `avatars/children/{childId}/profile.jpg` แล้วอัปเดต `photo_url` ในตาราง child',
            security: [BearerAuth],
            parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' }, example: EX.childId }],
            requestBody: {
              required: true,
              content: {
                'multipart/form-data': {
                  schema: {
                    type: 'object',
                    required: ['photo'],
                    properties: {
                      photo: { type: 'string', format: 'binary', description: 'ไฟล์รูปภาพ (JPEG, PNG, WebP — ไม่เกิน 5 MB)' },
                    },
                  },
                },
              },
            },
            responses: {
              200: {
                description: 'อัปโหลดสำเร็จ',
                content: {
                  'application/json': {
                    example: {
                      success: true,
                      photoUrl: 'https://xxxx.supabase.co/storage/v1/object/public/avatars/children/d8dc80f8-3e0c-419c-85f0-a66b3ef06b60/profile.jpg?v=1748000000000',
                    },
                  },
                },
              },
              400: { description: 'ไม่ส่งไฟล์ / ไฟล์ใหญ่เกิน / ประเภทไฟล์ไม่รองรับ' },
              403: { description: 'ไม่มีสิทธิ์เข้าถึงเด็กคนนี้' },
            },
          },
        },

        '/api/children/{id}/stats': {
          get: {
            tags: ['Children'],
            summary: 'ดึงสถิติของเด็ก',
            security: [BearerAuth],
            parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' }, example: EX.childId }],
            responses: {
              200: {
                description: 'สำเร็จ',
                content: {
                  'application/json': {
                    example: { wallet: 509, name: 'อรณะภา รพรี', totalActivities: 12 },
                  },
                },
              },
            },
          },
        },

        '/api/children/{id}/activity-history': {
          get: {
            tags: ['Children'],
            summary: 'ดึงประวัติการทำกิจกรรมของเด็ก',
            security: [BearerAuth],
            parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' }, example: EX.childId }],
            responses: {
              200: {
                description: 'สำเร็จ',
                content: {
                  'application/json': {
                    example: [
                      {
                        ActivityRecord_id: EX.recordId,
                        child_id: EX.childId,
                        activity_id: EX.activityIdCalc,
                        point: 31,
                        time_spent: 7,
                        date: '2026-02-27T03:16:30.996Z',
                        segment_results: [
                          { id: 'q_1772144979516', text: '2+9',  maxScore: 10, recognizedText: '11' },
                          { id: 'q_1772144992693', text: '78-6', maxScore: 10, recognizedText: '72' },
                        ],
                        evidence: { status: 'Pending Approval', description: null },
                      },
                    ],
                  },
                },
              },
            },
          },
        },

        '/api/children/{id}/redemptions': {
          get: {
            tags: ['Children'],
            summary: 'ดึงประวัติการแลกรางวัลของเด็ก',
            security: [BearerAuth],
            parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' }, example: EX.childId }],
            responses: {
              200: {
                description: 'สำเร็จ',
                content: {
                  'application/json': {
                    example: [
                      {
                        redemption_id: EX.redemptionId,
                        date_redemption: '2026-02-03T02:55:04.731Z',
                        point_for_reward: 100,
                        medals: { id: EX.medalId, name_medals: 'ยูทูป สิบนาที', point_medals: 100 },
                      },
                    ],
                  },
                },
              },
            },
          },
        },

        // ============================================================
        // REWARDS / MEDALS
        // ============================================================
        '/api/medals': {
          get: {
            tags: ['Rewards'],
            summary: 'ดึงรายการรางวัลของ parent',
            security: [BearerAuth],
            responses: {
              200: {
                description: 'สำเร็จ',
                content: {
                  'application/json': {
                    example: [
                      { id: EX.medalId,  name_medals: 'ยูทูป สิบนาที', point_medals: 100, created_at: '2026-02-02T19:54:56.712Z' },
                      { id: EX.medalId2, name_medals: '[ITEM]TOY',      point_medals: 25,  created_at: '2026-02-22T10:39:01.903Z' },
                    ],
                  },
                },
              },
            },
          },
          post: {
            tags: ['Rewards'],
            summary: 'สร้างรางวัลใหม่',
            security: [BearerAuth],
            requestBody: {
              required: true,
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    required: ['name', 'cost'],
                    properties: {
                      name: { type: 'string' },
                      cost: { type: 'number' },
                    },
                  },
                  example: { name: 'ไอศกรีม 1 ลูก', cost: 50 },
                },
              },
            },
            responses: {
              201: {
                description: 'สร้างสำเร็จ',
                content: {
                  'application/json': {
                    example: { id: EX.medalId2, name_medals: 'ไอศกรีม 1 ลูก', point_medals: 50 },
                  },
                },
              },
            },
          },
        },

        '/api/update-medal': {
          post: {
            tags: ['Rewards'],
            summary: 'แก้ไขรางวัล',
            security: [BearerAuth],
            requestBody: {
              required: true,
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    required: ['medalsId', 'name', 'cost'],
                    properties: {
                      medalsId: { type: 'string', format: 'uuid' },
                      name:     { type: 'string' },
                      cost:     { type: 'number' },
                    },
                  },
                  example: { medalsId: EX.medalId2, name: '[ITEM]TOY ของเล่นชิ้นใหม่', cost: 30 },
                },
              },
            },
            responses: {
              200: { description: 'แก้ไขสำเร็จ', content: { 'application/json': { example: { success: true, message: 'Medal updated successfully' } } } },
              403: { description: 'ไม่มีสิทธิ์แก้ไขรางวัลนี้' },
            },
          },
        },

        '/api/delete-medal': {
          post: {
            tags: ['Rewards'],
            summary: 'ลบรางวัล',
            security: [BearerAuth],
            requestBody: {
              required: true,
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    required: ['medalsId'],
                    properties: { medalsId: { type: 'string', format: 'uuid' } },
                  },
                  example: { medalsId: EX.medalId2 },
                },
              },
            },
            responses: {
              200: { description: 'ลบสำเร็จ', content: { 'application/json': { example: { success: true, message: 'Medal deleted successfully' } } } },
              403: { description: 'ไม่มีสิทธิ์ลบรางวัลนี้' },
            },
          },
        },

        '/api/redeem-medal': {
          post: {
            tags: ['Rewards'],
            summary: 'แลกรางวัลด้วยคะแนน',
            description: 'หักคะแนนจาก wallet ของเด็กและบันทึก redemption record',
            security: [BearerAuth],
            requestBody: {
              required: true,
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    required: ['childId', 'medalsId', 'cost'],
                    properties: {
                      childId:  { type: 'string', format: 'uuid' },
                      medalsId: { type: 'string', format: 'uuid' },
                      cost:     { type: 'number' },
                    },
                  },
                  example: { childId: EX.childId, medalsId: EX.medalId, cost: 100 },
                },
              },
            },
            responses: {
              200: {
                description: 'แลกสำเร็จ',
                content: {
                  'application/json': {
                    example: { success: true, message: 'Medal redeemed successfully!', newWallet: 409, cost: 100 },
                  },
                },
              },
              400: { description: 'คะแนนไม่พอ', content: { 'application/json': { example: { error: 'Insufficient wallet balance' } } } },
              403: { description: 'ไม่มีสิทธิ์เข้าถึงเด็กคนนี้' },
            },
          },
        },

        // ============================================================
        // ACTIVITY RECORDS
        // ============================================================
        '/api/complete-quest': {
          post: {
            tags: ['Activity Records'],
            summary: 'บันทึกผลการทำกิจกรรม',
            description: 'บันทึก activity_record + เพิ่มคะแนนใน wallet + เพิ่ม play_count',
            security: [BearerAuth],
            requestBody: {
              required: true,
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    required: ['childId', 'activityId', 'totalScoreEarned'],
                    properties: {
                      childId:          { type: 'string', format: 'uuid' },
                      activityId:       { type: 'string', format: 'uuid' },
                      totalScoreEarned: { type: 'number' },
                      timeSpent:        { type: 'number', description: 'วินาที' },
                      segmentResults:   { type: 'object', nullable: true },
                      evidence:         { type: 'object', nullable: true },
                      parentScore:      { type: 'number', nullable: true },
                    },
                  },
                  example: {
                    childId: EX.childId,
                    activityId: EX.activityIdCalc,
                    totalScoreEarned: 31,
                    timeSpent: 7,
                    segmentResults: [
                      { id: 'q_1772144979516', text: '2+9',  maxScore: 10, recognizedText: '11' },
                      { id: 'q_1772144992693', text: '78-6', maxScore: 10, recognizedText: '72' },
                    ],
                    evidence: { status: 'Pending Approval', description: null },
                  },
                },
              },
            },
            responses: {
              200: {
                description: 'บันทึกสำเร็จ',
                content: {
                  'application/json': {
                    example: {
                      success: true,
                      message: 'Quest completed successfully!',
                      scoreEarned: 31,
                      newWallet: 540,
                      activityRecord: {
                        ActivityRecord_id: EX.recordId,
                        child_id: EX.childId,
                        activity_id: EX.activityIdCalc,
                        point: 31,
                        time_spent: 7,
                        date: '2026-02-27T03:16:30.996Z',
                      },
                    },
                  },
                },
              },
              403: { description: 'ไม่มีสิทธิ์เข้าถึงเด็กคนนี้' },
            },
          },
        },

        '/api/adjust-wallet': {
          post: {
            tags: ['Activity Records'],
            summary: 'ปรับคะแนน wallet ของเด็ก (บวก/ลบ)',
            description: 'wallet จะถูก clamp ไว้ที่ [0, 999999]',
            security: [BearerAuth],
            requestBody: {
              required: true,
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    required: ['childId', 'delta'],
                    properties: {
                      childId: { type: 'string', format: 'uuid' },
                      delta:   { type: 'number', description: 'จำนวนที่ต้องการเพิ่ม (บวก) หรือลด (ลบ)' },
                    },
                  },
                  example: { childId: EX.childId, delta: -50 },
                },
              },
            },
            responses: {
              200: {
                description: 'ปรับสำเร็จ',
                content: {
                  'application/json': {
                    example: { success: true, newWallet: 459, delta: -50 },
                  },
                },
              },
            },
          },
        },

        // ============================================================
        // AI & VIDEO
        // ============================================================
        '/api/ai-evaluation': {
          post: {
            tags: ['AI & Video'],
            summary: 'ประเมินการออกเสียงด้วย AI Whisper',
            description: 'รับไฟล์เสียงและข้อความอ้างอิง แล้วคืนคะแนนความถูกต้อง 0-100',
            requestBody: {
              required: true,
              content: {
                'multipart/form-data': {
                  schema: {
                    type: 'object',
                    required: ['file', 'text'],
                    properties: {
                      file: { type: 'string', format: 'binary', description: 'ไฟล์เสียง (.wav, .mp3, .m4a)' },
                      text: { type: 'string', description: 'ข้อความที่เด็กควรพูด (จาก segment)' },
                    },
                  },
                },
              },
            },
            responses: {
              200: {
                description: 'ประเมินสำเร็จ',
                content: {
                  'application/json': {
                    example: { text: 'Hi John', score: 88.5 },
                  },
                },
              },
            },
          },
        },

        '/api/evaluate': {
          post: {
            tags: ['AI & Video'],
            summary: 'Proxy → AI evaluation (รองรับ CORS สำหรับ Flutter)',
            description: 'Forward multipart request ไปยัง /api/ai-evaluation — response เหมือนกัน',
            requestBody: {
              required: true,
              content: {
                'multipart/form-data': {
                  schema: {
                    type: 'object',
                    required: ['file', 'text'],
                    properties: {
                      file: { type: 'string', format: 'binary' },
                      text: { type: 'string', example: 'Hi, John!' },
                    },
                  },
                },
              },
            },
            responses: {
              200: { description: 'สำเร็จ', content: { 'application/json': { example: { text: 'Hi John', score: 88.5 } } } },
            },
          },
        },

        '/api/fetch-video-data': {
          post: {
            tags: ['AI & Video'],
            summary: 'ดึงข้อมูลและ subtitles จาก YouTube',
            requestBody: {
              required: true,
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    required: ['videoUrl'],
                    properties: { videoUrl: { type: 'string' } },
                  },
                  example: { videoUrl: 'https://www.youtube.com/watch?v=8fEo9YvaUcg' },
                },
              },
            },
            responses: {
              200: {
                description: 'สำเร็จ',
                content: {
                  'application/json': {
                    example: {
                      videoId: '8fEo9YvaUcg',
                      title: '5-Minute English Conversation Practice: Talking About Dreams & Future Plans',
                      description: 'Welcome to another 5-Minute English Conversation Practice!',
                      segments: [
                        { start: 11.8, end: 14.2, text: 'Hi, John!' },
                        { start: 14.2, end: 15.4, text: 'Hi, Jessica!' },
                        { start: 15.4, end: 16.7, text: 'How are you?' },
                      ],
                    },
                  },
                },
              },
              400: { description: 'URL ไม่ถูกต้องหรือวิดีโอไม่มี subtitles', content: { 'application/json': { example: { error: 'Could not extract video ID' } } } },
            },
          },
        },

        '/api/tiktok-oembed': {
          post: {
            tags: ['AI & Video'],
            summary: 'ดึงข้อมูล embed จาก TikTok',
            description: 'Proxy TikTok oEmbed API เพื่อหลีกเลี่ยง CORS',
            requestBody: {
              required: true,
              content: {
                'application/json': {
                  schema: {
                    type: 'object',
                    required: ['videoUrl'],
                    properties: { videoUrl: { type: 'string' } },
                  },
                  example: { videoUrl: 'https://www.tiktok.com/@teacher.rahman/video/7587077060342975764' },
                },
              },
            },
            responses: {
              200: {
                description: 'สำเร็จ',
                content: {
                  'application/json': {
                    example: {
                      thumbnailUrl: 'https://p16-sign.tiktokcdn-us.com/xxx.jpeg',
                      html: '<blockquote class="tiktok-embed" ...>...</blockquote>',
                      title: 'Cup pyramid with flashcards',
                      authorName: 'teacher.rahman',
                    },
                  },
                },
              },
            },
          },
        },

        // ============================================================
        // ADMIN
        // ============================================================
        '/api/users': {
          get: {
            tags: ['Admin'],
            summary: '[Admin] ดึงรายชื่อผู้ใช้ทั้งหมด',
            parameters: [
              { name: 'page',         in: 'query', schema: { type: 'integer', default: 1 } },
              { name: 'limit',        in: 'query', schema: { type: 'integer', default: 10 } },
              { name: 'search',       in: 'query', schema: { type: 'string' }, description: 'ค้นหาจากชื่อหรืออีเมล' },
              { name: 'status',       in: 'query', schema: { type: 'string', enum: ['Active', 'Inactive'] } },
              { name: 'verification', in: 'query', schema: { type: 'string', enum: ['Verified', 'Unverified'] } },
            ],
            responses: {
              200: {
                description: 'สำเร็จ',
                content: {
                  'application/json': {
                    example: {
                      users: [
                        {
                          id: EX.parentId,
                          fullName: 'สมชาย ใจดี',
                          email: 'aiiadorarin@gmail.com',
                          role: 'user',
                          status: 'Active',
                          verification: 'Verified',
                          childrenCount: 2,
                          activityRecordCount: 12,
                          createdAt: '2026-01-15T11:45:06.648Z',
                        },
                      ],
                      pagination: { currentPage: 1, totalPages: 3, total: 28, limit: 10 },
                    },
                  },
                },
              },
            },
          },
        },

        '/api/users/{id}': {
          get: {
            tags: ['Admin'],
            summary: '[Admin] ดึงรายละเอียดผู้ใช้',
            parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' }, example: EX.parentId }],
            responses: {
              200: { description: 'สำเร็จ — รวมข้อมูลเด็ก กิจกรรม รางวัล และประวัติแลก' },
              404: { description: 'ไม่พบผู้ใช้' },
            },
          },
          patch: {
            tags: ['Admin'],
            summary: '[Admin] เปลี่ยน role ผู้ใช้',
            security: [BearerAuth],
            parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' }, example: EX.parentId }],
            requestBody: {
              required: true,
              content: {
                'application/json': {
                  schema: { type: 'object', required: ['role'], properties: { role: { type: 'string', enum: ['user', 'admin'] } } },
                  example: { role: 'admin' },
                },
              },
            },
            responses: {
              200: { description: 'เปลี่ยน role สำเร็จ', content: { 'application/json': { example: { success: true, role: 'admin' } } } },
            },
          },
          delete: {
            tags: ['Admin'],
            summary: '[Admin] ลบผู้ใช้และข้อมูลทั้งหมด',
            description: 'ลบ parent, เด็กทั้งหมด, กิจกรรม, บันทึก, รางวัล และบัญชี Supabase Auth',
            security: [BearerAuth],
            parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string', format: 'uuid' }, example: EX.parentId }],
            responses: {
              200: { description: 'ลบสำเร็จ', content: { 'application/json': { example: { success: true } } } },
              404: { description: 'ไม่พบผู้ใช้' },
            },
          },
        },
      },
    },
  });
};
