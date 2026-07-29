const Notification = require('../models/Notification');
const pushService = require('./pushService');

/**
 * Create a broadcast notification for ALL users and deliver it:
 *
 *  1. Stored as a broadcast document -> shows up in every user's
 *     in-app notification feed (the bell icon), regardless of whether
 *     they granted the system notification permission.
 *  2. Emitted over Socket.IO so open apps update the badge instantly.
 *  3. Sent via FCM push to devices that registered a token (permission
 *     granted). Users who denied the permission skip this step and only
 *     see the notification inside the app.
 */
const broadcastNotification = async (io, { title, body, type, image = '', data = {} }) => {
  const notification = new Notification({
    title,
    body,
    type,
    image,
    data,
    isBroadcast: true,
    sentVia: 'both'
  });

  await notification.save();

  // Real-time in-app delivery
  try {
    io?.emit('notification:new', {
      id: notification._id,
      title,
      body,
      type,
      image,
      data,
      createdAt: notification.createdAt
    });
  } catch (error) {
    console.error('Socket notification emit error:', error.message);
  }

  // System push delivery (fire-and-forget; never blocks the admin action)
  pushService
    .broadcastToAllUsers({ title, body }, { type, ...data })
    .then((result) => {
      if (result.sent > 0) {
        console.log(`📣 Push sent to ${result.sent} devices: "${title}"`);
      }
    })
    .catch((error) => console.error('Broadcast push error:', error.message));

  return notification;
};

/**
 * Fired when an admin adds a new episode — every user is notified.
 */
const notifyNewEpisode = async (io, episode, anime) => {
  return broadcastNotification(io, {
    title: `New Episode: ${anime.title}`,
    body: `Episode ${episode.episodeNumber} is now available — download it now!`,
    type: 'new_episode',
    image: anime.poster?.url || episode.thumbnail?.url || '',
    data: {
      animeId: anime._id,
      episodeId: episode._id,
      episodeNumber: episode.episodeNumber
    }
  });
};

/**
 * Fired when an admin adds a brand new donghua — every user is notified,
 * same flow as the new-episode notification.
 */
const notifyNewDonghua = async (io, anime) => {
  return broadcastNotification(io, {
    title: 'New Donghua Added 🎉',
    body: `${anime.title} just landed on DonghuaHub. Check it out!`,
    type: 'new_donghua',
    image: anime.poster?.url || '',
    data: {
      animeId: anime._id
    }
  });
};

module.exports = {
  broadcastNotification,
  notifyNewEpisode,
  notifyNewDonghua
};
