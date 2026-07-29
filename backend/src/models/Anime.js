const mongoose = require('mongoose');

const characterSchema = new mongoose.Schema({
  name: String,
  image: String,
  role: String // Main, Supporting
}, { _id: false });

const animeSchema = new mongoose.Schema({
  anilistId: {
    type: Number,
    unique: true,
    sparse: true
  },
  malId: {
    type: Number,
    sparse: true
  },
  title: {
    type: String,
    required: true,
    trim: true,
    index: 'text'
  },
  alternativeTitles: [{
    type: String,
    trim: true
  }],
  description: {
    type: String,
    default: ''
  },
  genres: [{
    type: String,
    trim: true
  }],
  studios: [{
    type: String,
    trim: true
  }],
  status: {
    type: String,
    enum: ['ongoing', 'completed', 'upcoming', 'hiatus'],
    default: 'ongoing'
  },
  type: {
    type: String,
    enum: ['TV', 'Movie', 'OVA', 'ONA', 'Special'],
    default: 'TV'
  },
  rating: {
    type: Number,
    default: 0,
    min: 0,
    max: 10
  },
  releaseDate: {
    type: Date
  },
  releaseYear: {
    type: Number
  },
  totalEpisodes: {
    type: Number,
    default: 0
  },
  poster: {
    url: String,
    publicId: String
  },
  banner: {
    url: String,
    publicId: String
  },
  characters: [characterSchema],
  trailer: {
    url: String,
    site: String,
    thumbnail: String
  },
  language: {
    type: [String],
    default: ['Hindi']
  },
  isPremium: {
    type: Boolean,
    default: false
  },
  isFeatured: {
    type: Boolean,
    default: false
  },
  isActive: {
    type: Boolean,
    default: true
  },
  viewCount: {
    type: Number,
    default: 0
  },
  downloadCount: {
    type: Number,
    default: 0
  },
  bookmarkCount: {
    type: Number,
    default: 0
  },
  tags: [{
    type: String,
    trim: true
  }],
  relatedAnime: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Anime'
  }],
  recommendations: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Anime'
  }],
  metaFetched: {
    type: Boolean,
    default: false
  },
  metaSource: {
    type: String,
    enum: ['anilist', 'mal', 'manual'],
    default: 'manual'
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Virtual for episode count from actual episodes
animeSchema.virtual('episodeCount', {
  ref: 'Episode',
  localField: '_id',
  foreignField: 'anime',
  count: true
});

// Virtual for folders
animeSchema.virtual('folders', {
  ref: 'Folder',
  localField: '_id',
  foreignField: 'anime'
});

// Index for search
animeSchema.index({ title: 'text', description: 'text', alternativeTitles: 'text', tags: 'text' });
animeSchema.index({ genres: 1 });
animeSchema.index({ status: 1 });
animeSchema.index({ rating: -1 });
animeSchema.index({ createdAt: -1 });
animeSchema.index({ viewCount: -1 });
animeSchema.index({ isFeatured: 1, isActive: 1 });

// Increment view count
animeSchema.methods.incrementViews = function() {
  this.viewCount += 1;
  return this.save({ validateBeforeSave: false });
};

// Increment download count
animeSchema.methods.incrementDownloads = function() {
  this.downloadCount += 1;
  return this.save({ validateBeforeSave: false });
};

module.exports = mongoose.model('Anime', animeSchema);
