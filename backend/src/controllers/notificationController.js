const Notification = require('../models/Notification');

/**
 * Build the query for notifications visible to a user:
 * their personal notifications + every broadcast notification.
 */
const visibleToQuery = (userId) => ({
  $or: [
    { user: userId },
    { isBroadcast: true }
  ]
});

/**
 * Annotate a notification document with a per-user read flag.
 */
const withReadFlag = (notification, userId) => {
  const obj = notification.toObject ? notification.toObject() : { ...notification };
  if (notification.isBroadcast) {
    obj.isRead = userId
      ? (notification.readBy || []).some((id) => id.toString() === userId.toString())
      : false;
  }
  delete obj.readBy; // never leak the reader list
  return obj;
};

/**
 * GET /api/notifications
 * Every notification addressed to the user (personal + broadcasts),
 * newest first, annotated with that user's read state.
 */
const getNotifications = async (req, res) => {
  try {
    const userId = req.userId; // optionalAuth — may be undefined
    const { page = 1, limit = 30 } = req.query;

    const skip = (parseInt(page) - 1) * parseInt(limit);

    const query = userId
      ? visibleToQuery(userId)
      : { isBroadcast: true };

    const [notifications, total] = await Promise.all([
      Notification.find(query)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(parseInt(limit)),
      Notification.countDocuments(query)
    ]);

    res.status(200).json({
      success: true,
      data: {
        notifications: notifications.map((n) => withReadFlag(n, userId)),
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / parseInt(limit))
        }
      }
    });
  } catch (error) {
    console.error('Get notifications error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get notifications'
    });
  }
};

/**
 * GET /api/notifications/unread-count
 * Badge count for the bell icon.
 */
const getUnreadCount = async (req, res) => {
  try {
    const userId = req.userId;

    if (!userId) {
      const total = await Notification.countDocuments({ isBroadcast: true });
      return res.status(200).json({ success: true, data: { unread: total } });
    }

    const [personalUnread, broadcastUnread] = await Promise.all([
      Notification.countDocuments({ user: userId, isRead: false }),
      Notification.countDocuments({
        isBroadcast: true,
        readBy: { $ne: userId }
      })
    ]);

    res.status(200).json({
      success: true,
      data: { unread: personalUnread + broadcastUnread }
    });
  } catch (error) {
    console.error('Unread count error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to get unread count'
    });
  }
};

/**
 * PUT /api/notifications/:id/read
 */
const markAsRead = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.userId;

    const notification = await Notification.findById(id);
    if (!notification) {
      return res.status(404).json({
        success: false,
        message: 'Notification not found'
      });
    }

    if (notification.isBroadcast) {
      await Notification.findByIdAndUpdate(id, {
        $addToSet: { readBy: userId }
      });
    } else {
      // Personal notifications can only be read by their owner
      if (notification.user?.toString() !== userId.toString()) {
        return res.status(403).json({
          success: false,
          message: 'Not allowed'
        });
      }
      notification.isRead = true;
      await notification.save();
    }

    res.status(200).json({ success: true, message: 'Marked as read' });
  } catch (error) {
    console.error('Mark as read error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to mark notification as read'
    });
  }
};

/**
 * PUT /api/notifications/read-all
 */
const markAllAsRead = async (req, res) => {
  try {
    const userId = req.userId;

    await Promise.all([
      Notification.updateMany(
        { user: userId, isRead: false },
        { isRead: true }
      ),
      Notification.updateMany(
        { isBroadcast: true, readBy: { $ne: userId } },
        { $addToSet: { readBy: userId } }
      )
    ]);

    res.status(200).json({ success: true, message: 'All notifications marked as read' });
  } catch (error) {
    console.error('Mark all as read error:', error);
    res.status(500).json({
      success: false,
      message: 'Failed to mark all notifications as read'
    });
  }
};

module.exports = {
  getNotifications,
  getUnreadCount,
  markAsRead,
  markAllAsRead
};
