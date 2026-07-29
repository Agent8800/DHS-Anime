const express = require('express');
const router = express.Router();
const { authenticate, optionalAuth } = require('../middleware/auth');
const notificationController = require('../controllers/notificationController');

// Feed for the in-app bell icon (works without login for broadcasts,
// but includes read-state when a token is provided)
router.get('/', optionalAuth, notificationController.getNotifications);

// Badge count for the bell icon
router.get('/unread-count', optionalAuth, notificationController.getUnreadCount);

// Mark all as read (must come before /:id/read)
router.put('/read-all', authenticate, notificationController.markAllAsRead);

// Mark one as read
router.put('/:id/read', authenticate, notificationController.markAsRead);

module.exports = router;
