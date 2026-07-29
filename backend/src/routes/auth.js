const express = require('express');
const router = express.Router();
const { authenticate, requireAdmin } = require('../middleware/auth');
const { clerkWebhookHandler } = require('../middleware/clerkWebhook');
const authController = require('../controllers/authController');

// Clerk webhook
router.post('/webhook', clerkWebhookHandler);

// Sync user from Clerk
router.post('/sync', authController.syncUser);

// Get profile (authenticated)
router.get('/profile', authenticate, authController.getProfile);

// Update preferences
router.put('/preferences', authenticate, authController.updatePreferences);

// Device management
router.post('/device', authenticate, authController.registerDevice);
router.get('/devices', authenticate, authController.getDevices);
router.delete('/device/:deviceId', authenticate, authController.removeDevice);

// FCM token
router.put('/fcm-token', authenticate, authController.updateFCMToken);

module.exports = router;
