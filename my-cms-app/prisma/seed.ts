import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()

async function main() {
  console.log('🌱 Start seeding...')

  // ลบข้อมูลเก่า
  await prisma.activity_record.deleteMany()
  await prisma.redemption.deleteMany()
  await prisma.parent_and_medals.deleteMany()
  await prisma.parent_and_child.deleteMany()

  await prisma.medals.deleteMany()
  await prisma.activity.deleteMany()
  await prisma.child.deleteMany()
  await prisma.parent.deleteMany()

  console.log('🗑️ Old data deleted')

  // =====================
  // Parents
  // =====================

  const parent1 = await prisma.parent.create({
    data: {
      name_surname: 'คันธารัตน์ อเนกบุณย์',
      email: 'khantharat.a@sci.kmutnb.ac.th',
    },
  })

  const parent2 = await prisma.parent.create({
    data: {
      name_surname: 'สุวัจชัย กมลสันติโรจน์',
      email: 'suwatchai.k@sci.kmutnb.ac.th',
    },
  })

  const parent3 = await prisma.parent.create({
    data: {
      name_surname: 'ธรรศฏภณ สุระศักดิ์',
      email: 'thattapon.s@sci.kmutnb.ac.th',
    },
  })

  console.log('✅ Parents created')

  // =====================
  // Children
  // =====================

  const child1 = await prisma.child.create({
    data: {
      name_surname: 'ณัฐิวุฒิ สำเภาพันธ์',
      birthday: new Date('2004-05-12'),
      wallet: 180,
    },
  })

  const child2 = await prisma.child.create({
    data: {
      name_surname: 'ณัฏฐณิชา อ่อนสุวรรณ์',
      birthday: new Date('2004-05-20'),
      wallet: 540,
    },
  })

  const child3 = await prisma.child.create({
    data: {
      name_surname: 'ณัฐชนน พูลเพิ่ม',
      birthday: new Date('2003-09-12'),
      wallet: 600,
    },
  })

  const child4 = await prisma.child.create({
    data: {
      name_surname: 'กฤตณัฐ สาโถน',
      birthday: new Date('2003-03-10'),
      wallet: 720,
    },
  })

  console.log('✅ Children created')

  // =====================
  // Parent ↔ Child
  // =====================

  await prisma.parent_and_child.createMany({
    data: [
      {
        parent_id: parent1.parent_id,
        child_id: child1.child_id,
        relationship: 'มารดา',
      },
      {
        parent_id: parent2.parent_id,
        child_id: child2.child_id,
        relationship: 'บิดา',
      },
      {
        parent_id: parent2.parent_id,
        child_id: child3.child_id,
        relationship: 'บิดา',
      },
      {
        parent_id: parent3.parent_id,
        child_id: child4.child_id,
        relationship: 'บิดา',
      },
    ],
  })

  console.log('✅ Parent-Child relations created')

  // =====================
  // Medals (Reward)
  // =====================

  const medal1 = await prisma.medals.create({
    data: {
      name_medals: 'YouTube : 30 นาที',
      point_medals: 120,
    },
  })

  const medal2 = await prisma.medals.create({
    data: {
      name_medals: 'ตุ๊กตาหมี : 1 ตัว',
      point_medals: 420,
    },
  })

  const medal3 = await prisma.medals.create({
    data: {
      name_medals: 'กันดรัม : 1 ตัว',
      point_medals: 680,
    },
  })

  console.log('✅ Medals created')

  // =====================
  // Parent ↔ Medals
  // =====================

  await prisma.parent_and_medals.createMany({
    data: [
      {
        parent_id: parent1.parent_id,
        medals_id: medal1.id,
      },
      {
        parent_id: parent2.parent_id,
        medals_id: medal2.id,
      },
      {
        parent_id: parent3.parent_id,
        medals_id: medal3.id,
      },
    ],
  })

  console.log('✅ Parent-Medals relations created')

  console.log('🎉 Seeding completed')
}

main()
  .catch((e) => {
    console.error(e)
    process.exit(1)
  })
  .finally(async () => {
    await prisma.$disconnect()
  })