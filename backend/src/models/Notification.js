const mongoose = require('mongoose');

const notificationSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }, // null for broadcast notifications
  title: {
    type: String,
    required: true
  },
  body: {
    type: String,
    required: true
  },
  type: {
    type: String,
    enum: ['new_episode', 'new_donghua', 'announcement', 'maintenance', 'offer', 'bookmark_update', 'system'],
    default: 'system'
  },
  image: {
    type: String,
    default: ''
  },
  data: {
    animeId: { type: mongoose.Schema.Types.ObjectId, ref: 'Anime' },
    episodeId: { type: mongoose.Schema.Types.ObjectId, ref: 'Episode' },
    url: String,
    extra: mongoose.Schema.Types.Mixed
  },
  isRead: {
    type: Boolean,
    default: false
  },
  // For broadcast notifications (user == null): users who have read it.
  // Personal notifications use isRead instead.
  readBy: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  isBroadcast: {
    type: Boolean,
    default: false
  },
  sentVia: {
    type: String,
    enum: ['push', 'in_app', 'both'],
    default: 'in_app'
  }
}, {
  timestamps: true
});

notificationSchema.index({ user: 1, isRead: 1, createdAt: -1 });
notificationSchema.index({ isBroadcast: 1, createdAt: -1 });

module.exports = mongoose.model('Notification', notificationSchema);
