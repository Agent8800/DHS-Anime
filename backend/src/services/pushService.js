const User = require('../models/User');

/**
 * Firebase Cloud Messaging push delivery.
 *
 * Push is best-effort and silently degrades when firebase-admin is not
 * configured: notifications are always stored in MongoDB so they still
 * appear inside the app under the notification bell icon. A user only
 * has an fcmToken if they granted the notification permission on their
 * device — users who denied the permission therefore receive no system
 * push and only see the update inside the app, exactly as intended.
 *
 * Configure with ONE of:
 *   FIREBASE_SERVICE_ACCOUNT_JSON  – full service-account JSON as a string
 *   FCM_SERVICE_ACCOUNT_PATH       – path to the service-account JSON file
 */

let admin = null;
let messaging = null;
let initialized = false;

function init() {
  if (initialized) return;
  initialized = true;

  try {
    // Optional dependency — require lazily so the server runs without it
    admin = require('firebase-admin');

    if (admin.apps.length === 0) {
      const serviceAccountJson = process.env.FIREBASE_SERVICE_ACCOUNT_JSON;
      const serviceAccountPath = process.env.FCM_SERVICE_ACCOUNT_PATH;

      if (serviceAccountJson) {
        admin.initializeApp({
          credential: admin.credential.cert(JSON.parse(serviceAccountJson))
        });
      } else if (serviceAccountPath) {
        // eslint-disable-next-line global-require, import/no-dynamic-require
        admin.initializeApp({
          credential: admin.credential.cert(require(serviceAccountPath))
        });
      } else {
        console.warn(
          '⚠️  FCM not configured (set FIREBASE_SERVICE_ACCOUNT_JSON or ' +
          'FCM_SERVICE_ACCOUNT_PATH). System push notifications are disabled; ' +
          'in-app notifications still work.'
        );
        return;
      }
    }

    messaging = admin.messaging();
    console.log('✅ Firebase Cloud Messaging initialized');
  } catch (error) {
    console.warn(`⚠️  firebase-admin unavailable: ${error.message}. Push disabled, in-app notifications still work.`);
  }
}

/**
 * FCM data payloads must only contain string values
 */
const stringifyData = (data) => {
  const out = {};
  Object.entries(data || {}).forEach(([key, value]) => {
    if (value === null || value === undefined) return;
    out[key] = typeof value === 'object' ? JSON.stringify(value) : String(value);
  });
  return out;
};

/**
 * Send a notification to a list of device tokens (chunks of 500, FCM limit).
 * Invalid tokens are pruned from the database.
 */
const sendToTokens = async (tokens, notification, data = {}) => {
  init();
  if (!messaging || !tokens || tokens.length === 0) return { sent: 0 };

  const uniqueTokens = [...new Set(tokens.filter(Boolean))];
  const invalidTokens = [];
  let sent = 0;

  for (let i = 0; i < uniqueTokens.length; i += 500) {
    const chunk = uniqueTokens.slice(i, i + 500);
    try {
      const response = await messaging.sendEachForMulticast({
        tokens: chunk,
        notification,
        data: stringifyData(data),
        android: {
          priority: 'high',
          notification: {
            channelId: 'dhs_anime_updates',
            clickAction: 'FLUTTER_NOTIFICATION_CLICK'
          }
        },
        apns: { payload: { aps: { sound: 'default' } } }
      });

      sent += response.successCount;

      response.responses.forEach((r, idx) => {
        if (!r.success) {
          const code = r.error?.code || '';
          if (
            code.includes('registration-token-not-registered') ||
            code.includes('invalid-registration-token')
          ) {
            invalidTokens.push(chunk[idx]);
          }
        }
      });
    } catch (error) {
      console.error('FCM multicast error:', error.message);
    }
  }

  // Clean up dead tokens
  if (invalidTokens.length > 0) {
    await User.updateMany(
      { fcmToken: { $in: invalidTokens } },
      { $set: { fcmToken: '' } }
    ).catch(() => {});
  }

  return { sent };
};

/**
 * Broadcast a push to every active user that granted notification
 * permission (i.e. registered a device token).
 */
const broadcastToAllUsers = async (notification, data = {}) => {
  const users = await User.find({
    isActive: true,
    fcmToken: { $exists: true, $ne: '' }
  }).select('fcmToken');

  const tokens = users.map((u) => u.fcmToken).filter(Boolean);
  return sendToTokens(tokens, notification, data);
};

module.exports = {
  sendToTokens,
  broadcastToAllUsers
};
