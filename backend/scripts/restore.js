#!/usr/bin/env node

require('dotenv').config({ path: '../.env' });
const mongoose = require('mongoose');
const BackupService = require('../src/services/backupService');
const path = require('path');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/donghuahub';

async function runRestore() {
  const backupFile = process.argv[2];
  const overwrite = process.argv.includes('--overwrite');

  if (!backupFile) {
    console.error('❌ Please provide backup file path');
    console.log('Usage: node restore.js <backup-file.json> [--overwrite]');
    process.exit(1);
  }

  try {
    console.log('🔄 Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    const filePath = path.resolve(backupFile);
    console.log(`\n📥 Starting restore from: ${filePath}`);
    console.log(`   Overwrite mode: ${overwrite ? 'ON' : 'OFF'}`);

    const result = await BackupService.importData(filePath, { overwrite });

    console.log('\n✅ Restore completed!');
    console.log('\nImported:');
    Object.entries(result.imported).forEach(([name, count]) => {
      console.log(`  - ${name}: ${count}`);
    });

    if (Object.values(result.skipped).some(v => v > 0)) {
      console.log('\nSkipped (duplicates):');
      Object.entries(result.skipped).forEach(([name, count]) => {
        if (count > 0) console.log(`  - ${name}: ${count}`);
      });
    }

    if (result.errors.length > 0) {
      console.log(`\n⚠️  ${result.errors.length} errors:`);
      result.errors.slice(0, 10).forEach(err => {
        console.log(`  - [${err.collection}] ${err.item}: ${err.error}`);
      });
      if (result.errors.length > 10) {
        console.log(`  ... and ${result.errors.length - 10} more`);
      }
    }

    await mongoose.disconnect();
    process.exit(0);
  } catch (error) {
    console.error('❌ Restore failed:', error.message);
    await mongoose.disconnect();
    process.exit(1);
  }
}

runRestore();
