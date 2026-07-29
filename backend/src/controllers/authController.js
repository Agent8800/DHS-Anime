const User = require('../models/User');
const Premium = require('../models/Premium');
const PremiumCode = require('../models/PremiumCode');
const { generateToken } = require('../middleware/auth');

/**
 * Register or login user via Clerk
 * Called after Clerk authentication
 */
const syncUser = async (req, res) => {
  try {
    const { clerkId, email, name, avatar } = req.body;

    if (!clerkId || !email) {
      return res.status(400).json({
        success: false,
        message: 'Clerk ID and email are required'
      });
    }

    let user = await User.findOne({ clerkId });

    if (!user) {
      // Create new user
      user = new User({
        clerkId,
        email: email.toLowerCase(),
        name: name || 'User',
        avatar: avatar || '',
        role: 'user'
      });
      await user.save();
    } else {
      // Update existing user
      user.email = email.toLowerCase();
      if (name) user.name = name;
      if (avatar) user.avatar = avatar;
      await user.updateLastLogin();
    }

    // Generate JWT
    const token = generateToken(user._id, user.role);

    res.status(200).json({
      success: true,
      data: {
        user: {
          id: user._id,
          clerkId: user.clerkId,
          email: user.email,
          name: user.name,
          avatar: user.avatar,
          role: user.role,
          isPremium: user.isPremiumActive,
          premiumType: user.premiumType,
          premiumExpiry: user.premiumExpiry,
          preferences: user.preferences
        },
        token
      }
    });
  } catch (error) {
    console.error('Sync user error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to sync user'
    });
  }
};

/**
 * Get current user profile
 */
const getProfile = async (req, res) => {
  try {
    const user = await User.findById(req.userId).select('-__v');
    
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    res.status(200).json({
      success: true,
      data: {
        id: user._id,
        clerkId: user.clerkId,
        email: user.email,
        name: user.name,
        avatar: user.avatar,
        role: user.role,
        isPremium: user.isPremiumActive,
        premiumType: user.premiumType,
        premiumExpiry: user.premiumExpiry,
        preferences: user.preferences,
        devices: user.devices,
        createdAt: user.createdAt,
        lastLogin: user.lastLogin
      }
    });
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get profile'
    });
  }
};

/**
 * Update user preferences
 */
const updatePreferences = async (req, res) => {
  try {
    const { preferences } = req.body;
    
    const user = await User.findById(req.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    user.preferences = { ...user.preferences, ...preferences };
    await user.save();

    res.status(200).json({
      success: true,
      data: { preferences: user.preferences }
    });
  } catch (error) {
    console.error('Update preferences error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update preferences'
    });
  }
};

/**
 * Register device
 */
const registerDevice = async (req, res) => {
  try {
    const { deviceId, deviceName, platform } = req.body;
    
    const user = await User.findById(req.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    await user.addDevice({
      deviceId,
      deviceName,
      platform,
      ip: req.ip
    });

    res.status(200).json({
      success: true,
      message: 'Device registered successfully'
    });
  } catch (error) {
    console.error('Register device error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to register device'
    });
  }
};

/**
 * Get user devices
 */
const getDevices = async (req, res) => {
  try {
    const user = await User.findById(req.userId).select('devices');
    
    res.status(200).json({
      success: true,
      data: { devices: user.devices }
    });
  } catch (error) {
    console.error('Get devices error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get devices'
    });
  }
};

/**
 * Remove device
 */
const removeDevice = async (req, res) => {
  try {
    const { deviceId } = req.params;
    
    await User.findByIdAndUpdate(req.userId, {
      $pull: { devices: { deviceId } }
    });

    res.status(200).json({
      success: true,
      message: 'Device removed successfully'
    });
  } catch (error) {
    console.error('Remove device error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to remove device'
    });
  }
};

/**
 * Update FCM token for push notifications
 */
const updateFCMToken = async (req, res) => {
  try {
    const { fcmToken } = req.body;
    
    await User.findByIdAndUpdate(req.userId, { fcmToken });

    res.status(200).json({
      success: true,
      message: 'FCM token updated'
    });
  } catch (error) {
    console.error('Update FCM token error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to update FCM token'
    });
  }
};

/**
 * Redeem a premium activation code.
 * Free users must solve the shortener before every download; redeeming a
 * code upgrades the account so downloads are served instantly. Codes are
 * single-use and stack with an existing active premium period.
 */
const redeemPremiumCode = async (req, res) => {
  try {
    const raw = (req.body.code || '').toString().trim().toUpperCase();
    if (!raw) {
      return res.status(400).json({
        success: false,
        message: 'Activation code is required'
      });
    }

    const code = await PremiumCode.findOne({ code: raw });
    if (!code) {
      return res.status(404).json({
        success: false,
        message: 'Invalid activation code'
      });
    }
    if (code.isUsed) {
      return res.status(400).json({
        success: false,
        message: 'This code has already been redeemed'
      });
    }

    const user = await User.findById(req.userId);
    if (!user) {
      return res.status(404).json({
        success: false,
        message: 'User not found'
      });
    }

    // Stack on top of the current period when premium is still active
    const now = new Date();
    const stillActive = user.premiumType !== 'none' &&
      user.premiumExpiry &&
      user.premiumExpiry > now;
    const base = stillActive ? user.premiumExpiry : now;
    const newExpiry = new Date(base.getTime() + code.durationDays * 24 * 60 * 60 * 1000);

    user.premiumType = 'monthly';
    user.premiumExpiry = newExpiry;
    user.isPremium = true;
    await user.save();

    code.isUsed = true;
    code.usedBy = user._id;
    code.usedAt = now;
    await code.save();

    // Audit record alongside admin-granted premium entries
    await Premium.create({
      user: user._id,
      type: 'monthly',
      startDate: now,
      expiryDate: newExpiry,
      isActive: true,
      paymentMethod: 'manual',
      amount: 0,
      grantedBy: 'redeem-code',
      notes: `Code ${code.code} (${code.durationDays} days)`
    });

    res.status(200).json({
      success: true,
      message: `Premium activated for ${code.durationDays} days`,
      data: {
        isPremium: true,
        premiumType: user.premiumType,
        premiumExpiry: user.premiumExpiry
      }
    });
  } catch (error) {
    console.error('Redeem premium code error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to redeem code'
    });
  }
};

module.exports = {
  syncUser,
  getProfile,
  updatePreferences,
  registerDevice,
  getDevices,
  removeDevice,
  updateFCMToken,
  redeemPremiumCode
};
