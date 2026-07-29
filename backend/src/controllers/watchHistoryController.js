const WatchHistory = require('../models/WatchHistory');
const Download = require('../models/Download');

/**
 * Update watch progress
 */
const updateProgress = async (req, res) => {
  try {
    const { animeId, episodeId, currentTime, duration } = req.body;
    const userId = req.userId;

    if (!animeId || !episodeId || currentTime === undefined || !duration) {
      return res.status(400).json({
        success: false,
        message: 'Anime ID, Episode ID, currentTime, and duration are required'
      });
    }

    const progress = duration > 0 ? Math.round((currentTime / duration) * 100) : 0;
    const completed = progress >= 90;

    let history = await WatchHistory.findOne({
      user: userId,
      anime: animeId,
      episode: episodeId
    });

    if (history) {
      // Only update if new progress is greater (prevent rewind issues)
      if (currentTime > history.currentTime || completed) {
        history.currentTime = currentTime;
        history.duration = duration;
        history.progress = progress;
        history.completed = completed;
        history.quality = req.body.quality || history.quality;
        history.lastUpdated = new Date();
        await history.save();
      }
    } else {
      history = new WatchHistory({
        user: userId,
        anime: animeId,
        episode: episodeId,
        currentTime,
        duration,
        progress,
        completed,
        quality: req.body.quality || '1080p',
        lastUpdated: new Date()
      });
      await history.save();
    }

    res.status(200).json({
      success: true,
      data: {
        progress: history.progress,
        currentTime: history.currentTime,
        completed: history.completed
      }
    });
  } catch (error) {
    console.error('Update progress error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update progress'
    });
  }
};

/**
 * Get continue watching list
 */
const getContinueWatching = async (req, res) => {
  try {
    const userId = req.userId;
    const { limit = 20 } = req.query;

    const history = await WatchHistory.find({
      user: userId,
      completed: false,
      progress: { $gt: 0, $lt: 90 }
    })
      .populate('anime', 'title poster rating status genres')
      .populate('episode', 'episodeNumber title thumbnail duration')
      .sort({ updatedAt: -1 })
      .limit(parseInt(limit));

    res.status(200).json({
      success: true,
      data: { history }
    });
  } catch (error) {
    console.error('Get continue watching error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get continue watching'
    });
  }
};

/**
 * Get full watch history
 */
const getHistory = async (req, res) => {
  try {
    const userId = req.userId;
    const { page = 1, limit = 30 } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [history, total] = await Promise.all([
      WatchHistory.find({ user: userId })
        .populate('anime', 'title poster rating status genres')
        .populate('episode', 'episodeNumber title thumbnail duration')
        .sort({ updatedAt: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      WatchHistory.countDocuments({ user: userId })
    ]);

    res.status(200).json({
      success: true,
      data: {
        history,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit))
        }
      }
    });
  } catch (error) {
    console.error('Get history error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get watch history'
    });
  }
};

/**
 * Delete history entry
 */
const deleteHistory = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.userId;

    await WatchHistory.findOneAndDelete({ _id: id, user: userId });

    res.status(200).json({
      success: true,
      message: 'History entry deleted'
    });
  } catch (error) {
    console.error('Delete history error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete history'
    });
  }
};

/**
 * Clear all history
 */
const clearHistory = async (req, res) => {
  try {
    const userId = req.userId;

    await WatchHistory.deleteMany({ user: userId });

    res.status(200).json({
      success: true,
      message: 'Watch history cleared'
    });
  } catch (error) {
    console.error('Clear history error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to clear history'
    });
  }
};

/**
 * Get download list
 */
const getDownloads = async (req, res) => {
  try {
    const userId = req.userId;
    const { status } = req.query;

    const query = { user: userId };
    if (status) query.status = status;

    const downloads = await Download.find(query)
      .populate('anime', 'title poster')
      .populate('episode', 'episodeNumber title thumbnail')
      .sort({ createdAt: -1 });

    res.status(200).json({
      success: true,
      data: { downloads }
    });
  } catch (error) {
    console.error('Get downloads error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get downloads'
    });
  }
};

/**
 * Create download entry
 */
const createDownload = async (req, res) => {
  try {
    const { animeId, episodeId, quality = '1080p' } = req.body;
    const userId = req.userId;

    // Check if already downloading
    const existing = await Download.findOne({
      user: userId,
      episode: episodeId,
      status: { $in: ['pending', 'downloading', 'completed'] }
    });

    if (existing) {
      return res.status(400).json({
        success: false,
        message: 'Download already exists',
        data: { download: existing }
      });
    }

    const download = new Download({
      user: userId,
      anime: animeId,
      episode: episodeId,
      quality,
      status: 'pending'
    });

    await download.save();

    res.status(201).json({
      success: true,
      data: { download }
    });
  } catch (error) {
    console.error('Create download error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create download'
    });
  }
};

/**
 * Update download progress
 */
const updateDownloadProgress = async (req, res) => {
  try {
    const { id } = req.params;
    const { downloadedBytes, totalBytes, speed } = req.body;
    const userId = req.userId;

    const download = await Download.findOne({ _id: id, user: userId });
    if (!download) {
      return res.status(404).json({
        success: false,
        message: 'Download not found'
      });
    }

    await download.updateProgress(downloadedBytes, totalBytes, speed);

    res.status(200).json({
      success: true,
      data: {
        progress: download.progress,
        status: download.status,
        remainingTime: download.remainingTime
      }
    });
  } catch (error) {
    console.error('Update download progress error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update download progress'
    });
  }
};

/**
 * Delete download
 */
const deleteDownload = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.userId;

    await Download.findOneAndDelete({ _id: id, user: userId });

    res.status(200).json({
      success: true,
      message: 'Download deleted'
    });
  } catch (error) {
    console.error('Delete download error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete download'
    });
  }
};

module.exports = {
  updateProgress,
  getContinueWatching,
  getHistory,
  deleteHistory,
  clearHistory,
  getDownloads,
  createDownload,
  updateDownloadProgress,
  deleteDownload
};
