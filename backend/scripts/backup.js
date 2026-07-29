#!/usr/bin/env node

require('dotenv').config({ path: '../.env' });
const mongoose = require('mongoose');
const BackupService = require('../src/services/backupService');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/donghuahub';

async function runBackup() {
  try {
    console.log('🔄 Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    console.log('\n📦 Starting backup...');
    const result = await BackupService.exportData();

    console.log('\n✅ Backup completed successfully!');
    console.log(`📁 File: ${result.filePath}`);
    console.log(`📊 Total records: ${result.totalRecords}`);
    console.log('\nCollections:');
    result.collections.forEach(col => {
      console.log(`  - ${col.name}: ${col.count} records`);
    });

    await mongoose.disconnect();
    process.exit(0);
  } catch (error) {
    console.error('❌ Backup failed:', error.message);
    await mongoose.disconnect();
    process.exit(1);
  }
}

runBackup();
