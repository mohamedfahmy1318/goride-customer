/**
 * سكريبت لإضافة أنواع المستندات الجديدة للسائقين في Firebase
 * 
 * طريقة التشغيل:
 * 1. تأكد من وجود ملف serviceAccountKey.json في نفس المجلد
 * 2. npm install firebase-admin (إذا لم يكن مثبتاً)
 * 3. node import-new-documents.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
db.settings({ 
  ignoreUndefinedProperties: true,
  databaseId: 'default'
});

// المستندات الجديدة المطلوب إضافتها
const newDocuments = {
  // استمارة السيارة
  "VehicleReg001": {
    id: "VehicleReg001",
    backSide: false,
    enable: true,
    expireAt: true,
    frontSide: true,
    isDeleted: false,
    title: [
      { title: "Vehicle Registration", type: "en" },
      { title: "استمارة السيارة", type: "ar" },
      { title: "Certificat d'immatriculation", type: "fr" }
    ]
  },
  
  // تأمين السيارة
  "VehicleIns001": {
    id: "VehicleIns001",
    backSide: false,
    enable: true,
    expireAt: true,
    frontSide: true,
    isDeleted: false,
    title: [
      { title: "Vehicle Insurance", type: "en" },
      { title: "تأمين السيارة", type: "ar" },
      { title: "Assurance véhicule", type: "fr" }
    ]
  },
  
  // التفويض
  "Authorization001": {
    id: "Authorization001",
    backSide: false,
    enable: true,
    expireAt: false,
    frontSide: true,
    isDeleted: false,
    title: [
      { title: "Authorization", type: "en" },
      { title: "التفويض", type: "ar" },
      { title: "Autorisation", type: "fr" }
    ]
  },
  
  // صورة اللوحة الأمامية
  "FrontPlate001": {
    id: "FrontPlate001",
    backSide: false,
    enable: true,
    expireAt: false,
    frontSide: true,
    isDeleted: false,
    title: [
      { title: "Front License Plate", type: "en" },
      { title: "صورة اللوحة الأمامية", type: "ar" },
      { title: "Plaque avant", type: "fr" }
    ]
  },
  
  // صورة اللوحة الخلفية
  "BackPlate001": {
    id: "BackPlate001",
    backSide: false,
    enable: true,
    expireAt: false,
    frontSide: true,
    isDeleted: false,
    title: [
      { title: "Back License Plate", type: "en" },
      { title: "صورة اللوحة الخلفية", type: "ar" },
      { title: "Plaque arrière", type: "fr" }
    ]
  }
};

async function importNewDocuments() {
  console.log('='.repeat(50));
  console.log('   إضافة أنواع المستندات الجديدة للسائقين');
  console.log('='.repeat(50));
  console.log('');
  
  const batch = db.batch();
  let count = 0;
  
  for (const [docId, docData] of Object.entries(newDocuments)) {
    const docRef = db.collection('documents').doc(docId);
    batch.set(docRef, docData);
    count++;
    
    const arTitle = docData.title.find(t => t.type === 'ar')?.title;
    console.log(`  ✓ ${arTitle}`);
  }
  
  try {
    await batch.commit();
    console.log('');
    console.log('='.repeat(50));
    console.log(`  ✅ تم إضافة ${count} مستندات بنجاح!`);
    console.log('='.repeat(50));
    console.log('');
    console.log('IDs المستندات المضافة:');
    console.log('------------------------');
    Object.entries(newDocuments).forEach(([id, data]) => {
      const arTitle = data.title.find(t => t.type === 'ar')?.title;
      console.log(`${arTitle}: ${id}`);
    });
  } catch (error) {
    console.error('');
    console.error('❌ حدث خطأ:', error.message);
  }
  
  process.exit(0);
}

importNewDocuments();
