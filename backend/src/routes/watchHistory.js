const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/auth');
const watchHistoryController = require('../controllers/watchHistoryController');

// Update watch progress
router.post('/progress', authenticate, watchHistoryController.updateProgress);

// Get continue watching
router.get('/continue', authenticate, watchHistoryController.getContinueWatching);

// Get full history
router.get('/', authenticate, watchHistoryController.getHistory);

// Delete history entry
router.delete('/:id', authenticate, watchHistoryController.deleteHistory);

// Clear all history
router.delete('/', authenticate, watchHistoryController.clearHistory);

// Downloads
router.get('/downloads', authenticate, watchHistoryController.getDownloads);
router.post('/downloads', authenticate, watchHistoryController.createDownload);
router.put('/downloads/:id', authenticate, watchHistoryController.updateDownloadProgress);
router.delete('/downloads/:id', authenticate, watchHistoryController.deleteDownload);

module.exports = router;
