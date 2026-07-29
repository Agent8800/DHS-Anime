const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI, {
      // Mongoose 8 uses these defaults, but we can be explicit
    });

    console.log(`✅ MongoDB Connected: ${conn.connection.host}`);

    // Create indexes
    await createIndexes();

    return conn;
  } catch (error) {
    console.error(`❌ MongoDB Connection Error: ${error.message}`);
    process.exit(1);
  }
};

const createIndexes = async () => {
  try {
    const Anime = require('../models/Anime');
    const Episode = require('../models/Episode');
    const User = require('../models/User');
    const WatchHistory = require('../models/WatchHistory');

    // Anime indexes
    await Anime.collection.createIndex({ title: 'text', description: 'text', alternativeTitles: 'text' });
    await Anime.collection.createIndex({ genres: 1 });
    await Anime.collection.createIndex({ status: 1 });
    await Anime.collection.createIndex({ rating: -1 });
    await Anime.collection.createIndex({ createdAt: -1 });
    await Anime.collection.createIndex({ anilistId: 1 }, { unique: true, sparse: true });

    // Episode indexes
    await Episode.collection.createIndex({ anime: 1, episodeNumber: 1 });
    await Episode.collection.createIndex({ anime: 1, folder: 1 });
    await Episode.collection.createIndex({ createdAt: -1 });

    // User indexes
    await User.collection.createIndex({ clerkId: 1 }, { unique: true });
    await User.collection.createIndex({ email: 1 });

    // Watch History indexes
    await WatchHistory.collection.createIndex({ user: 1, anime: 1 });
    await WatchHistory.collection.createIndex({ user: 1, updatedAt: -1 });

    console.log('✅ Database indexes created');
  } catch (error) {
    console.log('⚠️  Index creation skipped (may already exist)');
  }
};

module.exports = connectDB;
