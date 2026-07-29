const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const bookmarkController = require('../controllers/bookmarkController');

// Get all bookmarks
router.get('/', authenticate, bookmarkController.getBookmarks);

// Toggle bookmark
router.post('/:animeId', authenticate, bookmarkController.toggleBookmark);

// Check if bookmarked
router.get('/:animeId/check', authenticate, bookmarkController.checkBookmark);

// Update notification settings
router.put('/:animeId/notification', authenticate, bookmarkController.updateBookmarkNotification);

module.exports = router;
