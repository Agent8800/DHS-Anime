const mongoose = require('mongoose');

const shortnerSessionSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  episode: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Episode'
  },
  anime: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Anime'
  },
  action: {
    type: String,
    enum: ['stream', 'download'],
    required: true
  },
  shortnerProvider: {
    type: String,
    default: 'generic'
  },
  shortnerUrl: {
    type: String,
    default: ''
  },
  solvedAt: {
    type: Date,
    default: Date.now
  },
  expireAt: {
    type: Date,
    required: true
  },
  isExpired: {
    type: Boolean,
    default: false
  },
  quality: {
    type: String,
    default: '1080p'
  }
}, {
  timestamps: true
});

shortnerSessionSchema.index({ user: 1, episode: 1, action: 1 });
shortnerSessionSchema.index({ expireAt: 1 }, { expireAfterSeconds: 0 });
shortnerSessionSchema.index({ user: 1, isExpired: 1 });

// Check if session is still valid
shortnerSessionSchema.methods.isValid = function() {
  return !this.isExpired && new Date() < this.expireAt;
};

// Static method to find valid session
shortnerSessionSchema.statics.findValidSession = function(userId, episodeId, action) {
  return this.findOne({
    user: userId,
    episode: episodeId,
    action: action,
    isExpired: false,
    expireAt: { $gt: new Date() }
  });
};

module.exports = mongoose.model('ShortnerSession', shortnerSessionSchema);
