#!/usr/bin/env node

require('dotenv').config({ path: '../.env' });
const mongoose = require('mongoose');
const AppSettings = require('../src/models/AppSettings');

const MONGODB_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/donghuahub';

const defaultSettings = [
  {
    key: 'app_name',
    value: 'DonghuaHub',
    description: 'Application name',
    category: 'general'
  },
  {
    key: 'app_version',
    value: '1.0.0',
    description: 'Current app version',
    category: 'general'
  },
  {
    key: 'maintenance_mode',
    value: false,
    description: 'Enable maintenance mode',
    category: 'general'
  },
  {
    key: 'maintenance_message',
    value: 'We are currently under maintenance. Please try again later.',
    description: 'Maintenance mode message',
    category: 'general'
  },
  {
    key: 'shortner_enabled',
    value: true,
    description: 'Enable shortner for free users',
    category: 'shortner'
  },
  {
    key: 'shortner_provider',
    value: 'generic',
    description: 'Shortner provider name',
    category: 'shortner'
  },
  {
    key: 'shortner_url',
    value: 'https://example.com/shortner',
    description: 'Shortner URL',
    category: 'shortner'
  },
  {
    key: 'shortner_duration_hours',
    value: 4,
    description: 'Shortner session duration in hours',
    category: 'shortner'
  },
  {
    key: 'default_video_quality',
    value: '1080p',
    description: 'Default video quality',
    category: 'player'
  },
  {
    key: 'available_qualities',
    value: ['360p', '480p', '720p', '1080p'],
    description: 'Available video qualities',
    category: 'player'
  },
  {
    key: 'auto_play_next',
    value: true,
    description: 'Auto play next episode',
    category: 'player'
  },
  {
    key: 'skip_intro_duration',
    value: 90,
    description: 'Default intro skip duration in seconds',
    category: 'player'
  },
  {
    key: 'default_language',
    value: 'Hindi',
    description: 'Default language',
    category: 'player'
  },
  {
    key: 'available_languages',
    value: ['Hindi', 'English', 'Japanese', 'Chinese'],
    description: 'Available languages',
    category: 'player'
  },
  {
    key: 'max_download_quality_free',
    value: '720p',
    description: 'Max download quality for free users',
    category: 'download'
  },
  {
    key: 'max_download_quality_premium',
    value: '1080p',
    description: 'Max download quality for premium users',
    category: 'download'
  },
  {
    key: 'max_concurrent_downloads',
    value: 3,
    description: 'Max concurrent downloads',
    category: 'download'
  },
  {
    key: 'enable_ads',
    value: true,
    description: 'Enable ads for free users',
    category: 'general'
  },
  {
    key: 'banner_auto_scroll',
    value: true,
    description: 'Auto scroll banner on home screen',
    category: 'ui'
  },
  {
    key: 'banner_interval_seconds',
    value: 5,
    description: 'Banner auto scroll interval',
    category: 'ui'
  },
  {
    key: 'enable_analytics',
    value: true,
    description: 'Enable analytics tracking',
    category: 'general'
  },
  {
    key: 'force_update_version',
    value: '0.0.0',
    description: 'Force update minimum version',
    category: 'general'
  },
  {
    key: 'force_update_message',
    value: 'Please update to the latest version.',
    description: 'Force update message',
    category: 'general'
  }
];

async function seed() {
  try {
    console.log('🔄 Connecting to MongoDB...');
    await mongoose.connect(MONGODB_URI);
    console.log('✅ Connected to MongoDB');

    console.log('\n🌱 Seeding database...');

    // Seed app settings
    for (const setting of defaultSettings) {
      await AppSettings.findOneAndUpdate(
        { key: setting.key },
        setting,
        { upsert: true, new: true }
      );
    }
    console.log(`✅ Seeded ${defaultSettings.length} app settings`);

    console.log('\n✅ Database seeding completed!');
    await mongoose.disconnect();
    process.exit(0);
  } catch (error) {
    console.error('❌ Seeding failed:', error.message);
    await mongoose.disconnect();
    process.exit(1);
  }
}

seed();
