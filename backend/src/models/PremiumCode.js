const mongoose = require('mongoose');

/**
 * One-time activation codes for Premium.
 * The dev/admin generates batches from the admin panel and shares them
 * with users (giveaways, manual sales, support). A user redeems a code
 * in the app; free users keep solving the shortener before downloads,
 * premium users skip it entirely.
 */
const premiumCodeSchema = new mongoose.Schema({
  code: {
    type: String,
    required: true,
    unique: true,
    uppercase: true,
    trim: true,
    index: true
  },
  durationDays: {
    type: Number,
    default: 30,
    min: 1,
    max: 3650
  },
  isUsed: {
    type: Boolean,
    default: false,
    index: true
  },
  usedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  usedAt: {
    type: Date,
    default: null
  },
  note: {
    type: String,
    default: '',
    maxlength: 120
  },
  createdBy: {
    type: String,
    default: 'admin'
  }
}, {
  timestamps: true
});

module.exports = mongoose.model('PremiumCode', premiumCodeSchema);
