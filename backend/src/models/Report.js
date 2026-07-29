const mongoose = require('mongoose');

const reportSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  anime: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Anime'
  },
  episode: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Episode'
  },
  type: {
    type: String,
    enum: ['video_not_playing', 'wrong_video', 'audio_issue', 'subtitle_issue', 'broken_link', 'content_issue', 'other'],
    required: true
  },
  description: {
    type: String,
    required: true
  },
  status: {
    type: String,
    enum: ['pending', 'reviewing', 'resolved', 'dismissed'],
    default: 'pending'
  },
  priority: {
    type: String,
    enum: ['low', 'medium', 'high', 'critical'],
    default: 'medium'
  },
  adminNotes: {
    type: String,
    default: ''
  },
  resolvedBy: {
    type: String,
    default: ''
  },
  resolvedAt: {
    type: Date
  },
  deviceInfo: {
    platform: String,
    version: String,
    model: String
  }
}, {
  timestamps: true
});

reportSchema.index({ status: 1, priority: 1 });
reportSchema.index({ anime: 1 });
reportSchema.index({ episode: 1 });
reportSchema.index({ user: 1 });

module.exports = mongoose.model('Report', reportSchema);
