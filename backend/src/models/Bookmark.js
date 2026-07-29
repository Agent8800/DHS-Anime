const mongoose = require('mongoose');

const bookmarkSchema = new mongoose.Schema({
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
  note: {
    type: String,
    default: ''
  },
  notificationEnabled: {
    type: Boolean,
    default: true
  }
}, {
  timestamps: true
});

// Prevent duplicate bookmarks
bookmarkSchema.index({ user: 1, anime: 1 }, { unique: true });
bookmarkSchema.index({ user: 1, createdAt: -1 });

module.exports = mongoose.model('Bookmark', bookmarkSchema);
