const mongoose = require('mongoose');

const folderSchema = new mongoose.Schema({
  anime: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Anime',
    required: true
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    default: ''
  },
  episodeRange: {
    start: Number,
    end: Number
  },
  order: {
    type: Number,
    default: 0
  },
  isPremium: {
    type: Boolean,
    default: false
  },
  episodeCount: {
    type: Number,
    default: 0
  },
  gridLayout: {
    type: String,
    enum: ['2x2', '4x4', '5x5', '6x6', '8x8', 'custom'],
    default: '4x4'
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Virtual for episodes in this folder
folderSchema.virtual('episodes', {
  ref: 'Episode',
  localField: '_id',
  foreignField: 'folder'
});

// Update episode count
folderSchema.methods.updateEpisodeCount = async function() {
  const Episode = require('./Episode');
  this.episodeCount = await Episode.countDocuments({ folder: this._id, isActive: true });
  return this.save();
};

module.exports = mongoose.model('Folder', folderSchema);
