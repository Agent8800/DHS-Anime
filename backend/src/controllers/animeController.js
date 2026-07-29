const Anime = require('../models/Anime');
const Episode = require('../models/Episode');
const Folder = require('../models/Folder');
const WatchHistory = require('../models/WatchHistory');
const Bookmark = require('../models/Bookmark');

/**
 * Get all anime with pagination and filtering
 */
const getAnimeList = async (req, res) => {
  try {
    const {
      page = 1,
      limit = 20,
      genre,
      status,
      year,
      studio,
      language,
      sort = 'newest',
      search,
      featured
    } = req.query;

    const query = { isActive: true };

    // Search
    if (search) {
      query.$text = { $search: search };
    }

    // Filters
    if (genre) query.genres = { $in: genre.split(',') };
    if (status) query.status = status;
    if (year) query.releaseYear = parseInt(year);
    if (studio) query.studios = { $in: [studio] };
    if (language) query.language = { $in: language.split(',') };
    if (featured === 'true') query.isFeatured = true;

    // Sort
    let sortObj = {};
    switch (sort) {
      case 'popular':
        sortObj = { viewCount: -1 };
        break;
      case 'rating':
        sortObj = { rating: -1 };
        break;
      case 'alphabetical':
        sortObj = { title: 1 };
        break;
      case 'oldest':
        sortObj = { createdAt: 1 };
        break;
      case 'newest':
      default:
        sortObj = { createdAt: -1 };
        break;
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [anime, total] = await Promise.all([
      Anime.find(query)
        .sort(sortObj)
        .skip(skip)
        .limit(parseInt(limit))
        .select('-__v'),
      Anime.countDocuments(query)
    ]);

    res.status(200).json({
      success: true,
      data: {
        anime,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit))
        }
      }
    });
  } catch (error) {
    console.error('Get anime list error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get anime list'
    });
  }
};

/**
 * Get anime by ID with episodes
 */
const getAnimeById = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.userId;

    const anime = await Anime.findById(id)
      .populate('relatedAnime', 'title poster rating status')
      .populate('recommendations', 'title poster rating status');

    if (!anime || !anime.isActive) {
      return res.status(404).json({
        success: false,
        message: 'Anime not found'
      });
    }

    // Get folders with episode counts
    const folders = await Folder.find({ anime: id })
      .sort({ order: 1 });

    // Get episode counts per folder
    const folderData = await Promise.all(
      folders.map(async (folder) => {
        const episodeCount = await Episode.countDocuments({
          folder: folder._id,
          isActive: true
        });
        return {
          ...folder.toObject(),
          episodeCount
        };
      })
    );

    // Get user's watch history for this anime
    let watchHistory = [];
    let bookmark = null;
    
    if (userId) {
      watchHistory = await WatchHistory.find({ user: userId, anime: id })
        .populate('episode', 'episodeNumber title thumbnail')
        .sort({ updatedAt: -1 });
      
      bookmark = await Bookmark.findOne({ user: userId, anime: id });
    }

    res.status(200).json({
      success: true,
      data: {
        anime,
        folders: folderData,
        watchHistory,
        bookmark: !!bookmark
      }
    });
  } catch (error) {
    console.error('Get anime by ID error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get anime details'
    });
  }
};

/**
 * Get home screen data
 */
const getHomeData = async (req, res) => {
  try {
    const userId = req.userId;

    // Fetch all sections in parallel
    const [
      continueWatching,
      recentlyUpdated,
      trending,
      popular,
      latestEpisodes,
      featured,
      topRated
    ] = await Promise.all([
      // Continue Watching
      userId ? getContinueWatching(userId) : [],
      
      // Recently Updated
      Anime.find({ isActive: true })
        .sort({ updatedAt: -1 })
        .limit(15)
        .select('title poster rating status genres'),
      
      // Trending (most viewed this week)
      Anime.find({ isActive: true })
        .sort({ viewCount: -1 })
        .limit(15)
        .select('title poster rating status genres viewCount'),
      
      // Popular (all time views)
      Anime.find({ isActive: true })
        .sort({ viewCount: -1 })
        .limit(15)
        .select('title poster rating status genres viewCount'),
      
      // Latest Episodes
      Episode.find({ isActive: true })
        .sort({ createdAt: -1 })
        .limit(20)
        .populate('anime', 'title poster rating status')
        .select('episodeNumber title thumbnail anime language quality'),
      
      // Featured
      Anime.find({ isActive: true, isFeatured: true })
        .sort({ createdAt: -1 })
        .limit(10)
        .select('title poster banner rating status genres description'),
      
      // Top Rated
      Anime.find({ isActive: true, rating: { $gt: 0 } })
        .sort({ rating: -1 })
        .limit(15)
        .select('title poster rating status genres')
    ]);

    // Get genres
    const genres = await Anime.distinct('genres', { isActive: true });

    res.status(200).json({
      success: true,
      data: {
        continueWatching,
        recentlyUpdated,
        trending,
        popular,
        latestEpisodes,
        featured,
        topRated,
        genres: genres.sort(),
        announcements: await getActiveAnnouncements(userId)
      }
    });
  } catch (error) {
    console.error('Get home data error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get home data'
    });
  }
};

/**
 * Get continue watching data for a user
 */
const getContinueWatching = async (userId) => {
  const history = await WatchHistory.find({
    user: userId,
    completed: false,
    progress: { $gt: 0, $lt: 90 }
  })
    .populate('anime', 'title poster rating status')
    .populate('episode', 'episodeNumber title thumbnail')
    .sort({ updatedAt: -1 })
    .limit(20);

  return history;
};

/**
 * Get active announcements
 */
const getActiveAnnouncements = async (userId) => {
  const Announcement = require('../models/Announcement');
  
  const query = {
    isActive: true,
    startDate: { $lte: new Date() },
    $or: [
      { endDate: null },
      { endDate: { $gte: new Date() } }
    ]
  };

  if (userId) {
    query.dismissedBy = { $ne: userId };
  }

  return Announcement.find(query)
    .sort({ priority: -1, createdAt: -1 })
    .limit(5);
};

/**
 * Search anime with instant results
 */
const searchAnime = async (req, res) => {
  try {
    const { q, genre, year, status, studio, language, sort = 'newest', page = 1, limit = 20 } = req.query;

    if (!q && !genre && !year && !status) {
      return res.status(400).json({
        success: false,
        message: 'Search query or filter required'
      });
    }

    const query = { isActive: true };

    if (q) {
      query.$or = [
        { title: { $regex: q, $options: 'i' } },
        { alternativeTitles: { $regex: q, $options: 'i' } },
        { tags: { $regex: q, $options: 'i' } }
      ];
    }

    if (genre) query.genres = { $in: genre.split(',') };
    if (status) query.status = status;
    if (year) query.releaseYear = parseInt(year);
    if (studio) query.studios = { $in: [studio] };
    if (language) query.language = { $in: language.split(',') };

    let sortObj = {};
    switch (sort) {
      case 'popular': sortObj = { viewCount: -1 }; break;
      case 'rating': sortObj = { rating: -1 }; break;
      case 'alphabetical': sortObj = { title: 1 }; break;
      case 'newest':
      default: sortObj = { createdAt: -1 }; break;
    }

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [results, total] = await Promise.all([
      Anime.find(query)
        .sort(sortObj)
        .skip(skip)
        .limit(parseInt(limit))
        .select('title poster rating status genres releaseYear viewCount'),
      Anime.countDocuments(query)
    ]);

    res.status(200).json({
      success: true,
      data: {
        results,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit))
        }
      }
    });
  } catch (error) {
    console.error('Search error:', error);
    res.status(500).json({
      success: false,
      message: 'Search failed'
    });
  }
};

/**
 * Get trending anime
 */
const getTrending = async (req, res) => {
  try {
    const { limit = 20 } = req.query;

    const anime = await Anime.find({ isActive: true })
      .sort({ viewCount: -1, rating: -1 })
      .limit(parseInt(limit))
      .select('title poster banner rating status genres viewCount description');

    res.status(200).json({
      success: true,
      data: { anime }
    });
  } catch (error) {
    console.error('Get trending error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get trending anime'
    });
  }
};

/**
 * Get anime by genre
 */
const getByGenre = async (req, res) => {
  try {
    const { genre } = req.params;
    const { page = 1, limit = 20 } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [anime, total] = await Promise.all([
      Anime.find({ isActive: true, genres: genre })
        .sort({ viewCount: -1 })
        .skip(skip)
        .limit(parseInt(limit))
        .select('title poster rating status genres'),
      Anime.countDocuments({ isActive: true, genres: genre })
    ]);

    res.status(200).json({
      success: true,
      data: {
        anime,
        genre,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit))
        }
      }
    });
  } catch (error) {
    console.error('Get by genre error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get anime by genre'
    });
  }
};

/**
 * Increment anime view count
 */
const incrementView = async (req, res) => {
  try {
    const { id } = req.params;
    
    await Anime.findByIdAndUpdate(id, { $inc: { viewCount: 1 } });

    res.status(200).json({
      success: true,
      message: 'View recorded'
    });
  } catch (error) {
    console.error('Increment view error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to record view'
    });
  }
};

module.exports = {
  getAnimeList,
  getAnimeById,
  getHomeData,
  searchAnime,
  getTrending,
  getByGenre,
  incrementView
};
