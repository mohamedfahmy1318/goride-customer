/**
 * سكريبت لإضافة أنواع المستندات الجديدة للسائقين في Firebase
 * يتم تشغيله باستخدام: node add_new_documents.js
 * 
 * قبل التشغيل، تأكد من:
 * 1. تثبيت firebase-admin: npm install firebase-admin
 * 2. وجود ملف service account key في المجلد
 */

const admin = require('firebase-admin');

// قم بتحديث المسار إلى ملف service account الخاص بك
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

// المستندات الجديدة المطلوب إضافتها
const newDocuments = [
  {
    id: generateId(),
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
  {
    id: generateId(),
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
  {
    id: generateId(),
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
  {
    id: generateId(),
    backSide: false,
    enable: true,
    expireAt: false,
    frontSide: true,
    isDeleted: false,
    title: [
      { title: "Front License Plate", type: "en" },
      { title: "صورة اللوحة الأمامية", type: "ar" },
      { title: "Plaque d'immatriculation avant", type: "fr" }
    ]
  },
  {
    id: generateId(),
    backSide: false,
    enable: true,
    expireAt: false,
    frontSide: true,
    isDeleted: false,
    title: [
      { title: "Back License Plate", type: "en" },
      { title: "صورة اللوحة الخلفية", type: "ar" },
      { title: "Plaque d'immatriculation arrière", type: "fr" }
    ]
  }
];

// دالة توليد ID عشوائي (مثل Firebase)
function generateId() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
  let result = '';
  for (let i = 0; i < 20; i++) {
    result += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return result;
}

async function addNewDocuments() {
  console.log('بدء إضافة المستندات الجديدة...\n');
  
  const batch = db.batch();
  const documentsRef = db.collection('documents');
  
  for (const doc of newDocuments) {
    const docRef = documentsRef.doc(doc.id);
    batch.set(docRef, doc);
    console.log(`تم إضافة: ${doc.title.find(t => t.type === 'ar')?.title || doc.title[0].title}`);
  }
  
  try {
    await batch.commit();
    console.log('\n✅ تم إضافة جميع المستندات بنجاح!');
    console.log('\nالمستندات المضافة:');
    newDocuments.forEach((doc, index) => {
      const arTitle = doc.title.find(t => t.type === 'ar')?.title || doc.title[0].title;
      const enTitle = doc.title.find(t => t.type === 'en')?.title || doc.title[0].title;
      console.log(`${index + 1}. ${arTitle} (${enTitle}) - ID: ${doc.id}`);
    });
  } catch (error) {
    console.error('❌ حدث خطأ:', error);
  }
  
  process.exit(0);
}

addNewDocuments();
