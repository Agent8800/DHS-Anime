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

    const episodeObj = episode.toObject();

    // Streaming has been removed — never expose direct video sources.
    delete episodeObj.sources;

    // Expose third-party download link metadata (host, quality, size)
    // but keep the actual URLs behind the gated download-links endpoint.
    episodeObj.downloadLinks = (episode.downloadLinks || [])
      .filter((l) => l.isActive)
      .map((l) => ({
        _id: l._id,
        host: l.host,
        label: l.label,
        quality: l.quality,
        fileSize: l.fileSize,
        language: l.language
      }));

    res.status(200).json({
      success: true,
      data: {
        episode: episodeObj,
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
 * Get third-party download links for an episode.
 * In-app streaming was removed: episodes are downloaded from these
 * external hosts (Mega, GDrive, Terabox, Telegram, ...) onto the device
 * and played with the built-in offline player.
 * Requires auth + shortner check for free users (monetization gate).
 */
const getDownloadLinks = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.userId;

    const episode = await Episode.findById(id).populate('anime', 'title status');
    if (!episode || !episode.isActive) {
      return res.status(404).json({
        success: false,
        message: 'Episode not found'
      });
    }

    const user = await User.findById(userId);
    const isPremium = user?.isPremiumActive || false;

    // Free users need a valid shortner session
    if (!isPremium) {
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
      res.locals.sessionExpiresAt = session.expireAt;
    }

    const activeLinks = (episode.downloadLinks || []).filter((l) => l.isActive);

    if (activeLinks.length === 0) {
      return res.status(404).json({
        success: false,
        message: 'No download links available for this episode yet'
      });
    }

    // Increment download count + log the download request
    await Episode.findByIdAndUpdate(id, { $inc: { downloadCount: 1 } });
    await Anime.findByIdAndUpdate(episode.anime._id, { $inc: { downloadCount: 1 } });

    const Download = require('../models/Download');
    await Download.create({
      user: userId,
      anime: episode.anime._id,
      episode: episode._id,
      quality: req.query.quality || activeLinks[0].quality,
      fileName: `${episode.anime.title} - E${episode.episodeNumber}.mp4`,
      status: 'pending'
    }).catch(() => {}); // logging only, never fail the request

    res.status(200).json({
      success: true,
      data: {
        episodeId: episode._id,
        episodeNumber: episode.episodeNumber,
        animeTitle: episode.anime.title,
        fileName: `${episode.anime.title} - E${episode.episodeNumber}`,
        isPremium,
        links: activeLinks.map((l) => ({
          _id: l._id,
          host: l.host,
          label: l.label,
          url: l.url,
          quality: l.quality,
          fileSize: l.fileSize,
          language: l.language
        })),
        sessionExpiresAt: res.locals.sessionExpiresAt
      }
    });
  } catch (error) {
    console.error('Get download links error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get download links'
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
  getDownloadLinks,
  searchEpisodes
};
