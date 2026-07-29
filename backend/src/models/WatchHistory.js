const mongoose = require('mongoose');

const watchHistorySchema = new mongoose.Schema({
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
  currentTime: {
    type: Number, // in seconds
    default: 0
  },
  duration: {
    type: Number, // in seconds
    default: 0
  },
  progress: {
    type: Number, // percentage 0-100
    default: 0
  },
  completed: {
    type: Boolean,
    default: false
  },
  quality: {
    type: String,
    default: '1080p'
  },
  lastUpdated: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Compound indexes
watchHistorySchema.index({ user: 1, anime: 1 });
watchHistorySchema.index({ user: 1, updatedAt: -1 });
watchHistorySchema.index({ user: 1, completed: 1 });

// Update progress
watchHistorySchema.methods.updateProgress = function(currentTime, duration) {
  this.currentTime = currentTime;
  this.duration = duration;
  this.progress = duration > 0 ? Math.round((currentTime / duration) * 100) : 0;
  this.completed = this.progress >= 90; // Mark as completed at 90%
  this.lastUpdated = new Date();
  return this.save();
};

module.exports = mongoose.model('WatchHistory', watchHistorySchema);
