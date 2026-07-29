const mongoose = require('mongoose');

const announcementSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true
  },
  message: {
    type: String,
    required: true
  },
  type: {
    type: String,
    enum: ['info', 'warning', 'maintenance', 'update', 'offer'],
    default: 'info'
  },
  image: {
    url: String,
    publicId: String
  },
  actionUrl: {
    type: String,
    default: ''
  },
  actionText: {
    type: String,
    default: ''
  },
  isActive: {
    type: Boolean,
    default: true
  },
  priority: {
    type: Number,
    default: 0
  },
  targetAudience: {
    type: String,
    enum: ['all', 'free', 'premium'],
    default: 'all'
  },
  startDate: {
    type: Date,
    default: Date.now
  },
  endDate: {
    type: Date
  },
  dismissible: {
    type: Boolean,
    default: true
  },
  dismissedBy: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  viewCount: {
    type: Number,
    default: 0
  },
  clickCount: {
    type: Number,
    default: 0
  }
}, {
  timestamps: true
});

announcementSchema.index({ isActive: 1, startDate: 1, endDate: 1 });
announcementSchema.index({ priority: -1 });

module.exports = mongoose.model('Announcement', announcementSchema);
