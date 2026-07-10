// my-cms-app/scratch/check-activities.js
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  try {
    const activities = await prisma.activity.findMany({
      orderBy: { created_at: 'desc' },
      take: 2
    });
    console.log('Last 2 activities segments:');
    activities.forEach(a => {
      console.log(`- ID: ${a.activity_id}, Name: ${a.name_activity}`);
      console.log('  Segments:', JSON.stringify(a.segments, null, 2));
    });
  } catch (err) {
    console.error(err);
  } finally {
    await prisma.$disconnect();
  }
}

main();
