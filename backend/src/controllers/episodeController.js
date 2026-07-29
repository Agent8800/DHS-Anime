const Episode = require('../models/Episode');
const Folder = require('../models/Folder');
const Anime = require('../models/Anime');
const WatchHistory = require('../models/WatchHistory');
const ShortnerSession = require('../models/ShortnerSession');
const User = require('../models/User');

/**
 * Get episodes by folder
 */
const getEpisodesByFolder = async (req, res) => {
  try {
    const { folderId } = req.params;
    const { sort = 'asc', page = 1, limit = 50 } = req.query;

    const folder = await Folder.findById(folderId);
    if (!folder) {
      return res.status(404).json({
        success: false,
        message: 'Folder not found'
      });
    }

    const sortOrder = sort === 'desc' ? -1 : 1;
    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [episodes, total] = await Promise.all([
      Episode.find({ folder: folderId, isActive: true })
        .sort({ episodeNumber: sortOrder })
        .skip(skip)
        .limit(parseInt(limit))
        .select('-sources -subtitles'), // Don't send video URLs in list
      Episode.countDocuments({ folder: folderId, isActive: true })
    ]);

    // Get user's watch history for these episodes
    let watchHistoryMap = {};
    if (req.userId) {
      const episodeIds = episodes.map(e => e._id);
      const history = await WatchHistory.find({
        user: req.userId,
        episode: { $in: episodeIds }
      });
      
      history.forEach(h => {
        watchHistoryMap[h.episode.toString()] = {
          progress: h.progress,
          currentTime: h.currentTime,
          completed: h.completed
        };
      });
    }

    const episodesWithProgress = episodes.map(ep => ({
      ...ep.toObject(),
      watchProgress: watchHistoryMap[ep._id.toString()] || null
    }));

    res.status(200).json({
      success: true,
      data: {
        folder,
        episodes: episodesWithProgress,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit))
        }
      }
    });
  } catch (error) {
    console.error('Get episodes by folder error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get episodes'
    });
  }
};

/**
 * Get episode details with streaming URL
 */
const getEpisodeDetails = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.userId;

    const episode = await Episode.findById(id)
      .populate('anime', 'title poster rating status totalEpisodes')
      .populate('folder', 'name anime');

    if (!episode || !episode.isActive) {
      return res.status(404).json({
        success: false,
        message: 'Episode not found'
      });
    }

    const isPremium = req.user?.isPremiumActive || false;

    // Check if episode requires premium
    if (episode.isPremium && !isPremium) {
      return res.status(403).json({
        success: false,
        message: 'This episode requires a premium subscription',
        isPremiumRequired: true
      });
    }

    // Filter sources based on premium status
    let availableSources = episode.sources;
    if (!isPremium) {
      availableSources = episode.sources.filter(s => !s.isPremium);
    }

    // Get watch history
    let watchHistory = null;
    if (userId) {
      watchHistory = await WatchHistory.findOne({
        user: userId,
        episode: id
      });
    }

    // Get next and previous episodes
    const [nextEpisode, prevEpisode] = await Promise.all([
      Episode.findOne({
        anime: episode.anime._id,
        episodeNumber: { $gt: episode.episodeNumber },
        isActive: true
      }).sort({ episodeNumber: 1 }).select('episodeNumber title thumbnail'),
      Episode.findOne({
        anime: episode.anime._id,
        episodeNumber: { $lt: episode.episodeNumber },
        isActive: true
      }).sort({ episodeNumber: -1 }).select('episodeNumber title thumbnail')
    ]);

    // Increment view
    await episode.incrementViews();

    res.status(200).json({
      success: true,
      data: {
        episode: {
          ...episode.toObject(),
          sources: availableSources
        },
        watchHistory,
        nextEpisode,
        prevEpisode,
        autoResume: watchHistory && !watchHistory.completed
      }
    });
  } catch (error) {
    console.error('Get episode details error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get episode details'
    });
  }
};

/**
 * Get episode stream URL (requires shortner check for free users)
 */
const getStreamUrl = async (req, res) => {
  try {
    const { id } = req.params;
    const { quality = '1080p' } = req.query;
    const userId = req.userId;

    const episode = await Episode.findById(id);
    if (!episode || !episode.isActive) {
      return res.status(404).json({
        success: false,
        message: 'Episode not found'
      });
    }

    const user = await User.findById(userId);
    const isPremium = user?.isPremiumActive || false;

    // Premium users get direct access
    if (isPremium) {
      const source = episode.sources.find(s => s.quality === quality) || episode.sources[0];
      return res.status(200).json({
        success: true,
        data: {
          url: source?.url,
          quality: source?.quality,
          subtitles: episode.subtitles,
          isPremium: true,
          autoResume: true
        }
      });
    }

    // Free users need shortner session
    const session = await ShortnerSession.findValidSession(userId, id, 'stream');
    
    if (!session) {
      return res.status(403).json({
        success: false,
        message: 'Shortener verification required',
        requiresShortner: true,
        episodeId: id
      });
    }

    // Get the requested quality or fallback
    const source = episode.sources.find(s => s.quality === quality && !s.isPremium) 
      || episode.sources.find(s => !s.isPremium)
      || episode.sources[0];

    res.status(200).json({
      success: true,
      data: {
        url: source?.url,
        quality: source?.quality,
        subtitles: episode.subtitles,
        isPremium: false,
        sessionExpiresAt: session.expireAt
      }
    });
  } catch (error) {
    console.error('Get stream URL error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get stream URL'
    });
  }
};

/**
 * Get download URL (requires shortner check for free users)
 */
const getDownloadUrl = async (req, res) => {
  try {
    const { id } = req.params;
    const { quality = '1080p' } = req.query;
    const userId = req.userId;

    const episode = await Episode.findById(id).populate('anime', 'title');
    if (!episode || !episode.isActive) {
      return res.status(404).json({
        success: false,
        message: 'Episode not found'
      });
    }

    const user = await User.findById(userId);
    const isPremium = user?.isPremiumActive || false;

    // Premium users get direct download
    if (isPremium) {
      const source = episode.sources.find(s => s.quality === quality) || episode.sources[0];
      
      // Increment download count
      await episode.incrementViews();
      await Anime.findByIdAndUpdate(episode.anime, { $inc: { downloadCount: 1 } });

      return res.status(200).json({
        success: true,
        data: {
          url: source?.url,
          quality: source?.quality,
          fileSize: source?.fileSize,
          fileName: `${episode.anime.title} - Episode ${episode.episodeNumber} [${source?.quality}].mp4`,
          isPremium: true
        }
      });
    }

    // Free users need shortner session
    const session = await ShortnerSession.findValidSession(userId, id, 'download');
    
    if (!session) {
      return res.status(403).json({
        success: false,
        message: 'Shortener verification required for download',
        requiresShortner: true,
        episodeId: id,
        action: 'download'
      });
    }

    const source = episode.sources.find(s => s.quality === quality && !s.isPremium) 
      || episode.sources.find(s => !s.isPremium)
      || episode.sources[0];

    // Increment download count
    await episode.incrementViews();
    await Anime.findByIdAndUpdate(episode.anime, { $inc: { downloadCount: 1 } });

    res.status(200).json({
      success: true,
      data: {
        url: source?.url,
        quality: source?.quality,
        fileSize: source?.fileSize,
        fileName: `${episode.anime.title} - Episode ${episode.episodeNumber} [${source?.quality}].mp4`,
        isPremium: false,
        sessionExpiresAt: session.expireAt
      }
    });
  } catch (error) {
    console.error('Get download URL error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get download URL'
    });
  }
};

/**
 * Search episodes
 */
const searchEpisodes = async (req, res) => {
  try {
    const { animeId } = req.params;
    const { q } = req.query;

    const query = { anime: animeId, isActive: true };
    
    if (q) {
      const num = parseInt(q);
      if (!isNaN(num)) {
        query.episodeNumber = num;
      } else {
        query.title = { $regex: q, $options: 'i' };
      }
    }

    const episodes = await Episode.find(query)
      .sort({ episodeNumber: 1 })
      .select('-sources -subtitles');

    res.status(200).json({
      success: true,
      data: { episodes }
    });
  } catch (error) {
    console.error('Search episodes error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to search episodes'
    });
  }
};

module.exports = {
  getEpisodesByFolder,
  getEpisodeDetails,
  getStreamUrl,
  getDownloadUrl,
  searchEpisodes
};
