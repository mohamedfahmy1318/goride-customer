const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
db.settings({ 
  ignoreUndefinedProperties: true,
  databaseId: 'default'
});

// Read the collections.json file
const data = JSON.parse(fs.readFileSync('./collections.json', 'utf8'));

// Function to convert special types
function convertValue(value) {
  if (value === null || value === undefined) {
    return value;
  }
  
  if (typeof value === 'object') {
    // Handle timestamp
    if (value.__datatype__ === 'timestamp' && value.value) {
      return admin.firestore.Timestamp.fromMillis(
        value.value._seconds * 1000 + Math.floor(value.value._nanoseconds / 1000000)
      );
    }
    
    // Handle GeoPoint
    if (value.__datatype__ === 'geopoint' && value.value) {
      return new admin.firestore.GeoPoint(value.value._latitude, value.value._longitude);
    }
    
    // Handle arrays
    if (Array.isArray(value)) {
      return value.map(item => convertValue(item));
    }
    
    // Handle nested objects (but skip __collections__)
    const converted = {};
    for (const [key, val] of Object.entries(value)) {
      if (key !== '__collections__') {
        converted[key] = convertValue(val);
      }
    }
    return converted;
  }
  
  return value;
}

// Function to import a single document
async function importDocument(collectionName, docId, docData) {
  const cleanData = {};
  
  for (const [key, value] of Object.entries(docData)) {
    if (key !== '__collections__') {
      cleanData[key] = convertValue(value);
    }
  }
  
  try {
    await db.collection(collectionName).doc(docId).set(cleanData);
    return true;
  } catch (error) {
    console.error(`Error importing ${collectionName}/${docId}:`, error.message);
    return false;
  }
}

// Main import function
async function importData() {
  const collections = data.__collections__;
  
  if (!collections) {
    console.error('No __collections__ found in data');
    return;
  }
  
  let totalDocs = 0;
  let successDocs = 0;
  let failedDocs = 0;
  
  for (const [collectionName, documents] of Object.entries(collections)) {
    console.log(`\nImporting collection: ${collectionName}`);
    
    const docEntries = Object.entries(documents);
    console.log(`  Found ${docEntries.length} documents`);
    
    // Import in batches of 50
    const batchSize = 50;
    for (let i = 0; i < docEntries.length; i += batchSize) {
      const batch = docEntries.slice(i, i + batchSize);
      
      const promises = batch.map(([docId, docData]) => 
        importDocument(collectionName, docId, docData)
      );
      
      const results = await Promise.all(promises);
      const batchSuccess = results.filter(r => r).length;
      
      successDocs += batchSuccess;
      failedDocs += batch.length - batchSuccess;
      totalDocs += batch.length;
      
      process.stdout.write(`  Progress: ${Math.min(i + batchSize, docEntries.length)}/${docEntries.length}\r`);
    }
    
    console.log(`  Completed: ${collectionName}`);
  }
  
  console.log(`\n========================================`);
  console.log(`Import completed!`);
  console.log(`Total documents: ${totalDocs}`);
  console.log(`Successful: ${successDocs}`);
  console.log(`Failed: ${failedDocs}`);
  console.log(`========================================`);
  
  process.exit(0);
}

importData().catch(error => {
  console.error('Import failed:', error);
  process.exit(1);
});
