const fs = require('fs').promises;
const path = require('path');
const Anime = require('../models/Anime');
const Episode = require('../models/Episode');
const Folder = require('../models/Folder');
const User = require('../models/User');
const Bookmark = require('../models/Bookmark');
const WatchHistory = require('../models/WatchHistory');
const Premium = require('../models/Premium');
const AppSettings = require('../models/AppSettings');
const Announcement = require('../models/Announcement');

class BackupService {
  /**
   * Export all MongoDB data to JSON
   */
  static async exportData() {
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const backupDir = path.join(__dirname, '../../backups');
    
    // Ensure backup directory exists
    await fs.mkdir(backupDir, { recursive: true });

    const data = {
      exportedAt: new Date().toISOString(),
      version: '1.0.0',
      collections: {}
    };

    // Export all collections
    const [anime, episodes, folders, users, bookmarks, watchHistory, premium, settings, announcements] = await Promise.all([
      Anime.find().lean(),
      Episode.find().lean(),
      Folder.find().lean(),
      User.find().lean(),
      Bookmark.find().lean(),
      WatchHistory.find().lean(),
      Premium.find().lean(),
      AppSettings.find().lean(),
      Announcement.find().lean()
    ]);

    data.collections = {
      anime,
      episodes,
      folders,
      users: users.map(u => ({ ...u, __v: undefined })), // Remove version key
      bookmarks,
      watch_history: watchHistory,
      premium,
      app_settings: settings,
      announcements
    };

    // Count total records
    data.totalRecords = Object.values(data.collections).reduce((sum, col) => sum + col.length, 0);

    // Write to file
    const filePath = path.join(backupDir, `backup-${timestamp}.json`);
    await fs.writeFile(filePath, JSON.stringify(data, null, 2));

    console.log(`✅ Backup exported: ${filePath}`);
    console.log(`   Total records: ${data.totalRecords}`);

    return {
      filePath,
      fileName: `backup-${timestamp}.json`,
      totalRecords: data.totalRecords,
      collections: Object.entries(data.collections).map(([name, items]) => ({
        name,
        count: items.length
      }))
    };
  }

  /**
   * Validate JSON schema before import
   */
  static validateBackupSchema(data) {
    const requiredCollections = ['anime', 'episodes', 'folders', 'users'];
    
    if (!data.collections) {
      throw new Error('Invalid backup: missing collections object');
    }

    for (const collection of requiredCollections) {
      if (!Array.isArray(data.collections[collection])) {
        throw new Error(`Invalid backup: missing or invalid ${collection} collection`);
      }
    }

    // Validate anime schema
    for (const anime of data.collections.anime) {
      if (!anime.title) {
        throw new Error('Invalid anime entry: missing title');
      }
    }

    // Validate episode schema
    for (const episode of data.collections.episodes) {
      if (!episode.anime || !episode.episodeNumber) {
        throw new Error('Invalid episode entry: missing anime or episodeNumber');
      }
    }

    return true;
  }

  /**
   * Import data from JSON backup
   */
  static async importData(filePath, options = { overwrite: false }) {
    const rawData = await fs.readFile(filePath, 'utf-8');
    const data = JSON.parse(rawData);

    // Validate schema
    this.validateBackupSchema(data);

    const results = {
      imported: {},
      skipped: {},
      errors: []
    };

    // Import order matters for relationships
    const importOrder = [
      { name: 'anime', model: Anime },
      { name: 'folders', model: Folder },
      { name: 'episodes', model: Episode },
      { name: 'users', model: User },
      { name: 'app_settings', model: AppSettings },
      { name: 'announcements', model: Announcement },
      { name: 'premium', model: Premium },
      { name: 'bookmarks', model: Bookmark },
      { name: 'watch_history', model: WatchHistory }
    ];

    for (const { name, model } of importOrder) {
      const items = data.collections[name];
      if (!items || !Array.isArray(items)) continue;

      let imported = 0;
      let skipped = 0;

      for (const item of items) {
        try {
          // Remove _id to let MongoDB generate new ones (unless overwriting)
          const itemData = { ...item };
          
          if (!options.overwrite) {
            // Check for duplicates
            let exists = false;
            
            if (name === 'anime' && itemData.anilistId) {
              exists = await model.findOne({ anilistId: itemData.anilistId });
            } else if (name === 'users' && itemData.clerkId) {
              exists = await model.findOne({ clerkId: itemData.clerkId });
            } else if (name === 'app_settings' && itemData.key) {
              exists = await model.findOne({ key: itemData.key });
            }
            
            if (exists) {
              skipped++;
              continue;
            }
          }

          // Remove _id for new documents
          delete itemData._id;
          delete itemData.__v;

          await model.findOneAndUpdate(
            options.overwrite ? { _id: item._id } : { _id: null },
            itemData,
            { upsert: true, new: true }
          );
          imported++;
        } catch (error) {
          results.errors.push({
            collection: name,
            item: item._id || item.title || 'unknown',
            error: error.message
          });
        }
      }

      results.imported[name] = imported;
      results.skipped[name] = skipped;
    }

    console.log('✅ Import completed:', results);
    return results;
  }
}

module.exports = BackupService;
