const ShortnerSession = require('../models/ShortnerSession');
const User = require('../models/User');

/**
 * Middleware to check if user has solved shortener for the given action
 * Premium users bypass shortener
 */
const checkShortnerSession = (action = 'stream') => {
  return async (req, res, next) => {
    try {
      const userId = req.userId;
      const { episodeId } = req.params;

      if (!userId) {
        return res.status(401).json({
          success: false,
          message: 'Authentication required'
        });
      }

      // Check if user is premium
      const user = await User.findById(userId);
      if (user && user.isPremiumActive) {
        req.isPremium = true;
        return next(); // Premium users bypass shortener
      }

      // Check for valid shortner session
      const session = await ShortnerSession.findValidSession(userId, episodeId, action);

      if (session) {
        req.shortnerSession = session;
        req.hasValidSession = true;
        return next();
      }

      // No valid session, need to solve shortener
      req.hasValidSession = false;
      
      // Get shortner settings from app settings
      const AppSettings = require('../models/AppSettings');
      const shortnerUrlSetting = await AppSettings.findOne({ key: 'shortner_url' });
      const shortnerProviderSetting = await AppSettings.findOne({ key: 'shortner_provider' });

      req.shortnerUrl = shortnerUrlSetting?.value || '';
      req.shortnerProvider = shortnerProviderSetting?.value || 'generic';

      next();
    } catch (error) {
      console.error('Shortner middleware error:', error);
      next();
    }
  };
};

/**
 * Verify shortner completion and create session
 */
const verifyShortner = async (req, res, next) => {
  try {
    const userId = req.userId;
    const { episodeId, action = 'stream' } = req.body;

    if (!userId || !episodeId) {
      return res.status(400).json({
        success: false,
        message: 'User ID and Episode ID required'
      });
    }

    // Create new session (4 hours)
    const SESSION_DURATION = 4 * 60 * 60 * 1000; // 4 hours in ms
    
    // Invalidate any existing sessions for this user/episode/action
    await ShortnerSession.updateMany(
      { user: userId, episode: episodeId, action, isExpired: false },
      { isExpired: true }
    );

    const session = new ShortnerSession({
      user: userId,
      episode: episodeId,
      action,
      solvedAt: new Date(),
      expireAt: new Date(Date.now() + SESSION_DURATION),
      shortnerProvider: req.shortnerProvider || 'generic'
    });

    await session.save();

    res.status(200).json({
      success: true,
      message: 'Shortner verified successfully',
      data: {
        sessionId: session._id,
        expiresAt: session.expireAt,
        validFor: '4 hours'
      }
    });
  } catch (error) {
    console.error('Verify shortner error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to verify shortner'
    });
  }
};

module.exports = {
  checkShortnerSession,
  verifyShortner
};
