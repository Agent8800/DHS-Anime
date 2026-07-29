const mongoose = require('mongoose');

const downloadSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  anime: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Anime',
    required: true
  },
  episode: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Episode',
    required: true
  },
  quality: {
    type: String,
    default: '1080p'
  },
  status: {
    type: String,
    enum: ['pending', 'downloading', 'completed', 'failed', 'paused', 'cancelled'],
    default: 'pending'
  },
  progress: {
    type: Number, // 0-100
    default: 0
  },
  downloadedBytes: {
    type: Number,
    default: 0
  },
  totalBytes: {
    type: Number,
    default: 0
  },
  downloadSpeed: {
    type: Number, // bytes per second
    default: 0
  },
  remainingTime: {
    type: Number, // seconds
    default: 0
  },
  filePath: {
    type: String,
    default: ''
  },
  fileName: {
    type: String,
    default: ''
  },
  error: {
    type: String,
    default: ''
  },
  retryCount: {
    type: Number,
    default: 0
  },
  maxRetries: {
    type: Number,
    default: 3
  }
}, {
  timestamps: true
});

downloadSchema.index({ user: 1, status: 1 });
downloadSchema.index({ user: 1, anime: 1 });
downloadSchema.index({ status: 1, createdAt: 1 });

// Update progress
downloadSchema.methods.updateProgress = function(downloaded, total, speed) {
  this.downloadedBytes = downloaded;
  this.totalBytes = total;
  this.progress = total > 0 ? Math.round((downloaded / total) * 100) : 0;
  this.downloadSpeed = speed;
  this.remainingTime = speed > 0 ? Math.round((total - downloaded) / speed) : 0;
  if (this.progress >= 100) {
    this.status = 'completed';
  }
  return this.save();
};

module.exports = mongoose.model('Download', downloadSchema);
