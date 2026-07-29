const Bookmark = require('../models/Bookmark');
const Anime = require('../models/Anime');

/**
 * Get all bookmarks for a user
 */
const getBookmarks = async (req, res) => {
  try {
    const userId = req.userId;
    const { page = 1, limit = 30 } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [bookmarks, total] = await Promise.all([
      Bookmark.find({ user: userId })
        .populate('anime', 'title poster rating status genres totalEpisodes')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      Bookmark.countDocuments({ user: userId })
    ]);

    res.status(200).json({
      success: true,
      data: {
        bookmarks,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit))
        }
      }
    });
  } catch (error) {
    console.error('Get bookmarks error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get bookmarks'
    });
  }
};

/**
 * Toggle bookmark (add/remove)
 */
const toggleBookmark = async (req, res) => {
  try {
    const { animeId } = req.params;
    const userId = req.userId;

    const existing = await Bookmark.findOne({ user: userId, anime: animeId });

    if (existing) {
      // Remove bookmark
      await Bookmark.findByIdAndDelete(existing._id);
      await Anime.findByIdAndUpdate(animeId, { $inc: { bookmarkCount: -1 } });

      res.status(200).json({
        success: true,
        data: { bookmarked: false },
        message: 'Bookmark removed'
      });
    } else {
      // Add bookmark
      const bookmark = new Bookmark({
        user: userId,
        anime: animeId
      });
      await bookmark.save();
      await Anime.findByIdAndUpdate(animeId, { $inc: { bookmarkCount: 1 } });

      res.status(201).json({
        success: true,
        data: { bookmarked: true },
        message: 'Bookmark added'
      });
    }
  } catch (error) {
    console.error('Toggle bookmark error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to toggle bookmark'
    });
  }
};

/**
 * Check if anime is bookmarked
 */
const checkBookmark = async (req, res) => {
  try {
    const { animeId } = req.params;
    const userId = req.userId;

    const bookmark = await Bookmark.findOne({ user: userId, anime: animeId });

    res.status(200).json({
      success: true,
      data: { bookmarked: !!bookmark }
    });
  } catch (error) {
    console.error('Check bookmark error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to check bookmark'
    });
  }
};

/**
 * Update bookmark notification settings
 */
const updateBookmarkNotification = async (req, res) => {
  try {
    const { animeId } = req.params;
    const { notificationEnabled } = req.body;
    const userId = req.userId;

    await Bookmark.findOneAndUpdate(
      { user: userId, anime: animeId },
      { notificationEnabled }
    );

    res.status(200).json({
      success: true,
      message: 'Bookmark notification updated'
    });
  } catch (error) {
    console.error('Update bookmark notification error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update bookmark notification'
    });
  }
};

module.exports = {
  getBookmarks,
  toggleBookmark,
  checkBookmark,
  updateBookmarkNotification
};
