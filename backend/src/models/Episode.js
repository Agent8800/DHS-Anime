const mongoose = require('mongoose');

const videoSourceSchema = new mongoose.Schema({
  quality: {
    type: String,
    enum: ['360p', '480p', '720p', '1080p', '4K'],
    required: true
  },
  url: {
    type: String,
    required: true
  },
  publicId: String,
  fileSize: Number, // in bytes
  format: {
    type: String,
    default: 'mp4'
  },
  isPremium: {
    type: Boolean,
    default: false
  }
}, { _id: true });

/**
 * Third-party download link (Mega, GDrive, Telegram, etc.)
 * Episodes are NOT streamed in-app anymore — users download
 * through these external hosts and play the file with the
 * built-in offline player.
 */
const downloadLinkSchema = new mongoose.Schema({
  host: {
    type: String,
    required: true,
    trim: true // e.g. 'mega', 'gdrive', 'terabox', 'telegram', 'direct'
  },
  label: {
    type: String,
    default: '' // e.g. 'Mega HD', 'GDrive Mirror 1'
  },
  url: {
    type: String,
    required: true
  },
  quality: {
    type: String,
    enum: ['360p', '480p', '720p', '1080p', '4K'],
    default: '720p'
  },
  fileSize: {
    type: Number, // in bytes
    default: 0
  },
  language: {
    type: String,
    default: 'Hindi'
  },
  isActive: {
    type: Boolean,
    default: true
  }
}, { _id: true });

const subtitleSchema = new mongoose.Schema({
  language: {
    type: String,
    required: true
  },
  url: {
    type: String,
    required: true
  },
  publicId: String,
  format: {
    type: String,
    enum: ['srt', 'vtt', 'ass'],
    default: 'srt'
  }
}, { _id: true });

const episodeSchema = new mongoose.Schema({
  anime: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Anime',
    required: true,
    index: true
  },
  folder: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Folder',
    required: true
  },
  episodeNumber: {
    type: Number,
    required: true
  },
  title: {
    type: String,
    default: ''
  },
  description: {
    type: String,
    default: ''
  },
  thumbnail: {
    url: String,
    publicId: String
  },
  sources: [videoSourceSchema], // legacy — kept for backward compatibility, not sent to the app
  downloadLinks: [downloadLinkSchema], // third-party download links shown in the app
  subtitles: [subtitleSchema],
  language: {
    type: String,
    default: 'Hindi'
  },
  duration: {
    type: Number, // in seconds
    default: 0
  },
  isPremium: {
    type: Boolean,
    default: false
  },
  isActive: {
    type: Boolean,
    default: true
  },
  viewCount: {
    type: Number,
    default: 0
  },
  downloadCount: {
    type: Number,
    default: 0
  },
  order: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Compound index
episodeSchema.index({ anime: 1, episodeNumber: 1 });
episodeSchema.index({ anime: 1, folder: 1 });
episodeSchema.index({ folder: 1, order: 1 });

// Increment views
episodeSchema.methods.incrementViews = function() {
  this.viewCount += 1;
  return this.save({ validateBeforeSave: false });
};

// Streaming has been removed from the app — episodes are
// delivered as downloads only. See downloadLinks above.

module.exports = mongoose.model('Episode', episodeSchema);
