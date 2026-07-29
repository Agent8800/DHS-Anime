const mongoose = require('mongoose');

const appSettingsSchema = new mongoose.Schema({
  key: {
    type: String,
    required: true,
    unique: true
  },
  value: {
    type: mongoose.Schema.Types.Mixed,
    required: true
  },
  description: {
    type: String,
    default: ''
  },
  category: {
    type: String,
    enum: ['general', 'player', 'download', 'shortner', 'notification', 'ui', 'security'],
    default: 'general'
  }
}, {
  timestamps: true
});

appSettingsSchema.index({ key: 1 });
appSettingsSchema.index({ category: 1 });

module.exports = mongoose.model('AppSettings', appSettingsSchema);
