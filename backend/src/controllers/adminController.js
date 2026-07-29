const Anime = require('../models/Anime');
const Episode = require('../models/Episode');
const Folder = require('../models/Folder');
const User = require('../models/User');
const Premium = require('../models/Premium');
const Announcement = require('../models/Announcement');
const Report = require('../models/Report');
const WatchHistory = require('../models/WatchHistory');
const Download = require('../models/Download');
const AppSettings = require('../models/AppSettings');
const notificationService = require('../services/notificationService');
const axios = require('axios');

/**
 * Get admin dashboard statistics
 */
const getDashboard = async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const [
      totalUsers,
      premiumUsers,
      totalAnime,
      totalEpisodes,
      todayViews,
      totalDownloads,
      recentUsers,
      pendingReports
    ] = await Promise.all([
      User.countDocuments({ isActive: true }),
      User.countDocuments({ isPremium: true, isActive: true }),
      Anime.countDocuments({ isActive: true }),
      Episode.countDocuments({ isActive: true }),
      WatchHistory.countDocuments({ createdAt: { $gte: today } }),
      Download.countDocuments(),
      User.find().sort({ createdAt: -1 }).limit(10).select('name email avatar createdAt'),
      Report.countDocuments({ status: 'pending' })
    ]);

    // Weekly views data (last 7 days)
    const weeklyViews = [];
    for (let i = 6; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      date.setHours(0, 0, 0, 0);
      
      const nextDate = new Date(date);
      nextDate.setDate(nextDate.getDate() + 1);
      
      const count = await WatchHistory.countDocuments({
        createdAt: { $gte: date, $lt: nextDate }
      });
      
      weeklyViews.push({
        date: date.toISOString().split('T')[0],
        views: count
      });
    }

    // Daily users (last 7 days)
    const dailyUsers = [];
    for (let i = 6; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      date.setHours(0, 0, 0, 0);
      
      const nextDate = new Date(date);
      nextDate.setDate(nextDate.getDate() + 1);
      
      const count = await User.countDocuments({
        createdAt: { $gte: date, $lt: nextDate }
      });
      
      dailyUsers.push({
        date: date.toISOString().split('T')[0],
        users: count
      });
    }

    res.status(200).json({
      success: true,
      data: {
        stats: {
          totalUsers,
          premiumUsers,
          totalAnime,
          totalEpisodes,
          todayViews,
          totalDownloads,
          pendingReports
        },
        charts: {
          weeklyViews,
          dailyUsers
        },
        recentUsers
      }
    });
  } catch (error) {
    console.error('Get dashboard error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get dashboard data'
    });
  }
};

/**
 * Fetch anime metadata from AniList API
 */
const fetchMetadata = async (req, res) => {
  try {
    const { search, anilistId } = req.body;

    let animeData;

    if (anilistId) {
      animeData = await fetchFromAniList(anilistId);
    } else if (search) {
      animeData = await searchAniList(search);
    } else {
      return res.status(400).json({
        success: false,
        message: 'Search query or AniList ID required'
      });
    }

    res.status(200).json({
      success: true,
      data: { anime: animeData }
    });
  } catch (error) {
    console.error('Fetch metadata error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to fetch metadata'
    });
  }
};

/**
 * Fetch from AniList GraphQL API
 */
const fetchFromAniList = async (anilistId) => {
  const query = `
    query ($id: Int) {
      Media(id: $id, type: ANIME) {
        id
        idMal
        title {
          romaji
          english
          native
        }
        description
        coverImage {
          large
          medium
        }
        bannerImage
        genres
        studios {
          nodes {
            name
          }
        }
        status
        meanScore
        startDate {
          year
          month
          day
        }
        episodes
        characters(sort: ROLE, perPage: 10) {
          nodes {
            name {
              full
            }
            image {
              large
            }
          }
        }
        trailer {
          id
          site
          thumbnail
        }
        relations {
          edges {
            relationType
            node {
              id
              title {
                romaji
                english
              }
              coverImage {
                large
              }
              meanScore
              status
            }
          }
        }
      }
    }
  `;

  const response = await axios.post('https://graphql.anilist.co', {
    query,
    variables: { id: parseInt(anilistId) }
  });

  const media = response.data.data.Media;
  return formatAniListData(media);
};

/**
 * Search AniList
 */
const searchAniList = async (search) => {
  const query = `
    query ($search: String) {
      Media(search: $search, type: ANIME) {
        id
        idMal
        title {
          romaji
          english
          native
        }
        description
        coverImage {
          large
          medium
        }
        bannerImage
        genres
        studios {
          nodes {
            name
          }
        }
        status
        meanScore
        startDate {
          year
          month
          day
        }
        episodes
        characters(sort: ROLE, perPage: 10) {
          nodes {
            name {
              full
            }
            image {
              large
            }
          }
        }
        trailer {
          id
          site
          thumbnail
        }
      }
    }
  `;

  const response = await axios.post('https://graphql.anilist.co', {
    query,
    variables: { search }
  });

  const media = response.data.data.Media;
  return formatAniListData(media);
};

/**
 * Format AniList data
 */
const formatAniListData = (media) => {
  const statusMap = {
      'RELEASING': 'ongoing',
      'FINISHED': 'completed',
      'NOT_YET_RELEASED': 'upcoming',
      'HIATUS': 'hiatus',
      'CANCELLED': 'completed'
  };

  const alternativeTitles = [];
  if (media.title.romaji) alternativeTitles.push(media.title.romaji);
  if (media.title.english) alternativeTitles.push(media.title.english);
  if (media.title.native) alternativeTitles.push(media.title.native);

  return {
    anilistId: media.id,
    malId: media.idMal,
    title: media.title.english || media.title.romaji || media.title.native,
    alternativeTitles: [...new Set(alternativeTitles)],
    description: media.description?.replace(/<[^>]*>/g, '') || '',
    genres: media.genres || [],
    studios: media.studios?.nodes?.map(s => s.name) || [],
    status: statusMap[media.status] || 'ongoing',
    rating: media.meanScore ? (media.meanScore / 10).toFixed(1) : 0,
    releaseDate: media.startDate ? new Date(media.startDate.year, (media.startDate.month || 1) - 1, media.startDate.day || 1) : null,
    releaseYear: media.startDate?.year,
    totalEpisodes: media.episodes || 0,
    poster: {
      url: media.coverImage?.large || media.coverImage?.medium
    },
    banner: {
      url: media.bannerImage
    },
    characters: media.characters?.nodes?.map(c => ({
      name: c.name?.full,
      image: c.image?.large
    })) || [],
    trailer: media.trailer ? {
      url: `https://www.youtube.com/watch?v=${media.trailer.id}`,
      site: media.trailer.site,
      thumbnail: media.trailer.thumbnail
    } : null
  };
};

/**
 * Create anime
 */
const createAnime = async (req, res) => {
  try {
    const animeData = req.body;
    
    const anime = new Anime({
      ...animeData,
      metaFetched: !!animeData.anilistId,
      metaSource: animeData.anilistId ? 'anilist' : 'manual'
    });

    await anime.save();

    // Notify every user about the new donghua (push + in-app bell icon).
    // Fire-and-forget: never blocks or fails the admin response.
    notificationService
      .notifyNewDonghua(req.app.get('io'), anime)
      .catch((err) => console.error('New donghua notification error:', err));

    res.status(201).json({
      success: true,
      data: { anime },
      message: 'Anime created successfully'
    });
  } catch (error) {
    console.error('Create anime error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create anime'
    });
  }
};

/**
 * Update anime
 */
const updateAnime = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const anime = await Anime.findByIdAndUpdate(id, updateData, { new: true });

    if (!anime) {
      return res.status(404).json({
        success: false,
        message: 'Anime not found'
      });
    }

    res.status(200).json({
      success: true,
      data: { anime },
      message: 'Anime updated successfully'
    });
  } catch (error) {
    console.error('Update anime error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update anime'
    });
  }
};

/**
 * Delete anime (soft delete)
 */
const deleteAnime = async (req, res) => {
  try {
    const { id } = req.params;

    await Anime.findByIdAndUpdate(id, { isActive: false });

    res.status(200).json({
      success: true,
      message: 'Anime deleted successfully'
    });
  } catch (error) {
    console.error('Delete anime error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete anime'
    });
  }
};

/**
 * Create folder
 */
const createFolder = async (req, res) => {
  try {
    const { animeId, name, episodeRange, gridLayout, isPremium } = req.body;

    const anime = await Anime.findById(animeId);
    if (!anime) {
      return res.status(404).json({
        success: false,
        message: 'Anime not found'
      });
    }

    const folderCount = await Folder.countDocuments({ anime: animeId });

    const folder = new Folder({
      anime: animeId,
      name,
      episodeRange,
      gridLayout: gridLayout || '4x4',
      isPremium: isPremium || false,
      order: folderCount
    });

    await folder.save();

    res.status(201).json({
      success: true,
      data: { folder },
      message: 'Folder created successfully'
    });
  } catch (error) {
    console.error('Create folder error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create folder'
    });
  }
};

/**
 * Update folder
 */
const updateFolder = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const folder = await Folder.findByIdAndUpdate(id, updateData, { new: true });

    if (!folder) {
      return res.status(404).json({
        success: false,
        message: 'Folder not found'
      });
    }

    res.status(200).json({
      success: true,
      data: { folder },
      message: 'Folder updated successfully'
    });
  } catch (error) {
    console.error('Update folder error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update folder'
    });
  }
};

/**
 * Delete folder
 */
const deleteFolder = async (req, res) => {
  try {
    const { id } = req.params;

    // Check if folder has episodes
    const episodeCount = await Episode.countDocuments({ folder: id });
    if (episodeCount > 0) {
      return res.status(400).json({
        success: false,
        message: 'Cannot delete folder with episodes. Move or delete episodes first.'
      });
    }

    await Folder.findByIdAndDelete(id);

    res.status(200).json({
      success: true,
      message: 'Folder deleted successfully'
    });
  } catch (error) {
    console.error('Delete folder error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete folder'
    });
  }
};

/**
 * Get all episodes of an anime WITH download links.
 * Used by the admin mirror-link editor (never exposed publicly).
 */
const getEpisodesByAnime = async (req, res) => {
  try {
    const { animeId } = req.params;

    const anime = await Anime.findById(animeId).select('title poster status totalEpisodes');
    if (!anime) {
      return res.status(404).json({ success: false, message: 'Anime not found' });
    }

    const episodes = await Episode.find({ anime: animeId })
      .sort({ episodeNumber: 1 })
      .select('episodeNumber title folder language duration isActive downloadLinks downloadCount viewCount');

    // Folders too, so the panel can assign new episodes to one
    const folders = await Folder.find({ anime: animeId })
      .sort({ order: 1 })
      .select('name episodeRange order');

    res.status(200).json({
      success: true,
      data: { anime, episodes, folders }
    });
  } catch (error) {
    console.error('Get episodes by anime error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get episodes'
    });
  }
};

/**
 * Create episode
 */
const createEpisode = async (req, res) => {
  try {
    const {
      animeId,
      folderId,
      episodeNumber,
      title,
      description,
      thumbnail,
      sources,
      downloadLinks,
      subtitles,
      language,
      duration,
      isPremium
    } = req.body;

    const [anime, folder] = await Promise.all([
      Anime.findById(animeId),
      Folder.findById(folderId)
    ]);

    if (!anime) {
      return res.status(404).json({ success: false, message: 'Anime not found' });
    }
    if (!folder) {
      return res.status(404).json({ success: false, message: 'Folder not found' });
    }

    const episode = new Episode({
      anime: animeId,
      folder: folderId,
      episodeNumber,
      title: title || `Episode ${episodeNumber}`,
      description,
      thumbnail,
      sources,
      downloadLinks: downloadLinks || [],
      subtitles,
      language: language || 'Hindi',
      duration,
      isPremium: isPremium || false
    });

    await episode.save();

    // Update folder episode count
    await folder.updateEpisodeCount();

    // Update anime total episodes
    const totalEpisodes = await Episode.countDocuments({ anime: animeId, isActive: true });
    await Anime.findByIdAndUpdate(animeId, { totalEpisodes });

    // Notify every user about the new episode (push + in-app bell icon).
    // Fire-and-forget: never blocks or fails the admin response.
    notificationService
      .notifyNewEpisode(req.app.get('io'), episode, anime)
      .catch((err) => console.error('New episode notification error:', err));

    res.status(201).json({
      success: true,
      data: { episode },
      message: 'Episode created successfully'
    });
  } catch (error) {
    console.error('Create episode error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create episode'
    });
  }
};

/**
 * Update episode
 */
const updateEpisode = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;

    const episode = await Episode.findByIdAndUpdate(id, updateData, { new: true });

    if (!episode) {
      return res.status(404).json({
        success: false,
        message: 'Episode not found'
      });
    }

    res.status(200).json({
      success: true,
      data: { episode },
      message: 'Episode updated successfully'
    });
  } catch (error) {
    console.error('Update episode error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update episode'
    });
  }
};

/**
 * Delete episode (soft delete)
 */
const deleteEpisode = async (req, res) => {
  try {
    const { id } = req.params;

    const episode = await Episode.findByIdAndUpdate(id, { isActive: false });

    if (!episode) {
      return res.status(404).json({
        success: false,
        message: 'Episode not found'
      });
    }

    // Update folder and anime counts
    const folder = await Folder.findById(episode.folder);
    if (folder) await folder.updateEpisodeCount();

    const totalEpisodes = await Episode.countDocuments({ anime: episode.anime, isActive: true });
    await Anime.findByIdAndUpdate(episode.anime, { totalEpisodes });

    res.status(200).json({
      success: true,
      message: 'Episode deleted successfully'
    });
  } catch (error) {
    console.error('Delete episode error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete episode'
    });
  }
};

/**
 * Move episodes between folders
 */
const moveEpisodes = async (req, res) => {
  try {
    const { episodeIds, targetFolderId } = req.body;

    await Episode.updateMany(
      { _id: { $in: episodeIds } },
      { folder: targetFolderId }
    );

    res.status(200).json({
      success: true,
      message: 'Episodes moved successfully'
    });
  } catch (error) {
    console.error('Move episodes error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to move episodes'
    });
  }
};

/**
 * Manage premium users
 */
const managePremium = async (req, res) => {
  try {
    const { userId, type, duration, notes } = req.body;

    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    let expiryDate = null;
    if (type === 'monthly') {
      expiryDate = new Date();
      expiryDate.setMonth(expiryDate.getMonth() + (duration || 1));
    }

    // Update user
    user.isPremium = true;
    user.premiumType = type;
    user.premiumExpiry = expiryDate;
    await user.save();

    // Create premium record
    const premium = new Premium({
      user: userId,
      type,
      expiryDate,
      grantedBy: req.user.name || 'Admin',
      notes
    });
    await premium.save();

    res.status(200).json({
      success: true,
      data: { user, premium },
      message: 'Premium granted successfully'
    });
  } catch (error) {
    console.error('Manage premium error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to manage premium'
    });
  }
};

/**
 * Revoke premium
 */
const revokePremium = async (req, res) => {
  try {
    const { userId } = req.params;

    const user = await User.findByIdAndUpdate(userId, {
      isPremium: false,
      premiumType: 'none',
      premiumExpiry: null
    }, { new: true });

    await Premium.updateMany({ user: userId, isActive: true }, { isActive: false });

    res.status(200).json({
      success: true,
      data: { user },
      message: 'Premium revoked successfully'
    });
  } catch (error) {
    console.error('Revoke premium error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to revoke premium'
    });
  }
};

/**
 * Create announcement
 */
const createAnnouncement = async (req, res) => {
  try {
    const announcement = new Announcement(req.body);
    await announcement.save();

    res.status(201).json({
      success: true,
      data: { announcement },
      message: 'Announcement created'
    });
  } catch (error) {
    console.error('Create announcement error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to create announcement'
    });
  }
};

/**
 * Get all announcements
 */
const getAnnouncements = async (req, res) => {
  try {
    const announcements = await Announcement.find()
      .sort({ priority: -1, createdAt: -1 });

    res.status(200).json({
      success: true,
      data: { announcements }
    });
  } catch (error) {
    console.error('Get announcements error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get announcements'
    });
  }
};

/**
 * Update announcement
 */
const updateAnnouncement = async (req, res) => {
  try {
    const { id } = req.params;

    const announcement = await Announcement.findByIdAndUpdate(id, req.body, { new: true });

    res.status(200).json({
      success: true,
      data: { announcement },
      message: 'Announcement updated'
    });
  } catch (error) {
    console.error('Update announcement error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update announcement'
    });
  }
};

/**
 * Delete announcement
 */
const deleteAnnouncement = async (req, res) => {
  try {
    const { id } = req.params;
    await Announcement.findByIdAndDelete(id);

    res.status(200).json({
      success: true,
      message: 'Announcement deleted'
    });
  } catch (error) {
    console.error('Delete announcement error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to delete announcement'
    });
  }
};

/**
 * Get reports
 */
const getReports = async (req, res) => {
  try {
    const { status, priority, page = 1, limit = 30 } = req.query;

    const query = {};
    if (status) query.status = status;
    if (priority) query.priority = priority;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [reports, total] = await Promise.all([
      Report.find(query)
        .populate('user', 'name email avatar')
        .populate('anime', 'title poster')
        .populate('episode', 'episodeNumber title')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      Report.countDocuments(query)
    ]);

    res.status(200).json({
      success: true,
      data: {
        reports,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit))
        }
      }
    });
  } catch (error) {
    console.error('Get reports error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get reports'
    });
  }
};

/**
 * Update report status
 */
const updateReport = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, priority, adminNotes } = req.body;

    const update = {};
    if (status) {
      update.status = status;
      if (status === 'resolved') {
        update.resolvedBy = req.user.name;
        update.resolvedAt = new Date();
      }
    }
    if (priority) update.priority = priority;
    if (adminNotes) update.adminNotes = adminNotes;

    const report = await Report.findByIdAndUpdate(id, update, { new: true });

    res.status(200).json({
      success: true,
      data: { report },
      message: 'Report updated'
    });
  } catch (error) {
    console.error('Update report error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update report'
    });
  }
};

/**
 * Get all users
 */
const getUsers = async (req, res) => {
  try {
    const { page = 1, limit = 30, search, role, premium } = req.query;

    const query = {};
    if (search) {
      query.$or = [
        { name: { $regex: search, $options: 'i' } },
        { email: { $regex: search, $options: 'i' } }
      ];
    }
    if (role) query.role = role;
    if (premium === 'true') query.isPremium = true;
    if (premium === 'false') query.isPremium = false;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const [users, total] = await Promise.all([
      User.find(query)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit))
        .select('-__v'),
      User.countDocuments(query)
    ]);

    res.status(200).json({
      success: true,
      data: {
        users,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit))
        }
      }
    });
  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get users'
    });
  }
};

/**
 * Update app settings
 */
const updateSettings = async (req, res) => {
  try {
    const { settings } = req.body;

    for (const [key, value] of Object.entries(settings)) {
      await AppSettings.findOneAndUpdate(
        { key },
        { key, value },
        { upsert: true, new: true }
      );
    }

    res.status(200).json({
      success: true,
      message: 'Settings updated'
    });
  } catch (error) {
    console.error('Update settings error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update settings'
    });
  }
};

/**
 * Get app settings
 */
const getSettings = async (req, res) => {
  try {
    const settings = await AppSettings.find();
    
    const settingsMap = {};
    settings.forEach(s => {
      settingsMap[s.key] = s.value;
    });

    res.status(200).json({
      success: true,
      data: { settings: settingsMap }
    });
  } catch (error) {
    console.error('Get settings error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get settings'
    });
  }
};

module.exports = {
  getDashboard,
  fetchMetadata,
  createAnime,
  updateAnime,
  deleteAnime,
  createFolder,
  updateFolder,
  deleteFolder,
  createEpisode,
  getEpisodesByAnime,
  updateEpisode,
  deleteEpisode,
  moveEpisodes,
  managePremium,
  revokePremium,
  createAnnouncement,
  getAnnouncements,
  updateAnnouncement,
  deleteAnnouncement,
  getReports,
  updateReport,
  getUsers,
  updateSettings,
  getSettings
};
