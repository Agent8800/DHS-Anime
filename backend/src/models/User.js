const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  clerkId: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  avatar: {
    type: String,
    default: ''
  },
  role: {
    type: String,
    enum: ['user', 'admin'],
    default: 'user'
  },
  isPremium: {
    type: Boolean,
    default: false
  },
  premiumExpiry: {
    type: Date,
    default: null
  },
  premiumType: {
    type: String,
    enum: ['none', 'monthly', 'lifetime'],
    default: 'none'
  },
  devices: [{
    deviceId: String,
    deviceName: String,
    platform: String,
    lastActive: Date,
    ip: String
  }],
  preferences: {
    darkMode: { type: Boolean, default: true },
    amoledMode: { type: Boolean, default: false },
    themeColor: { type: String, default: '#6C63FF' },
    defaultQuality: { type: String, default: '1080p' },
    defaultLanguage: { type: String, default: 'Hindi' },
    subtitleSize: { type: String, default: 'medium' },
    autoPlay: { type: Boolean, default: true },
    downloadQuality: { type: String, default: '720p' }
  },
  fcmToken: {
    type: String,
    default: ''
  },
  isActive: {
    type: Boolean,
    default: true
  },
  lastLogin: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// Virtual for checking premium status
userSchema.virtual('isPremiumActive').get(function() {
  if (this.premiumType === 'lifetime') return true;
  if (this.premiumType === 'monthly' && this.premiumExpiry) {
    return new Date() < this.premiumExpiry;
  }
  return false;
});

// Update last login
userSchema.methods.updateLastLogin = function() {
  this.lastLogin = new Date();
  return this.save();
};

// Add device
userSchema.methods.addDevice = function(deviceInfo) {
  const existingIndex = this.devices.findIndex(d => d.deviceId === deviceInfo.deviceId);
  if (existingIndex >= 0) {
    this.devices[existingIndex] = { ...deviceInfo, lastActive: new Date() };
  } else {
    this.devices.push({ ...deviceInfo, lastActive: new Date() });
  }
  return this.save();
};

module.exports = mongoose.model('User', userSchema);
