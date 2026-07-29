const mongoose = require('mongoose');

const premiumSchema = new mongoose.Schema({
  user: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  type: {
    type: String,
    enum: ['monthly', 'yearly', 'lifetime'],
    required: true
  },
  startDate: {
    type: Date,
    default: Date.now
  },
  expiryDate: {
    type: Date
  },
  isActive: {
    type: Boolean,
    default: true
  },
  paymentMethod: {
    type: String,
    enum: ['razorpay', 'stripe', 'manual', 'google_play'],
    default: 'manual'
  },
  paymentId: {
    type: String,
    default: ''
  },
  amount: {
    type: Number,
    default: 0
  },
  currency: {
    type: String,
    default: 'INR'
  },
  grantedBy: {
    type: String, // Admin who granted it
    default: 'system'
  },
  notes: {
    type: String,
    default: ''
  }
}, {
  timestamps: true
});

premiumSchema.index({ user: 1 });
premiumSchema.index({ isActive: 1, expiryDate: 1 });

// Check if premium is still valid
premiumSchema.methods.isValid = function() {
  if (this.type === 'lifetime') return this.isActive;
  return this.isActive && new Date() < this.expiryDate;
};

module.exports = mongoose.model('Premium', premiumSchema);
