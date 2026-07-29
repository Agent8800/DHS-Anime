const express = require('express');
const router = express.Router();
const { authenticate, optionalAuth } = require('../middleware/auth');
const { checkShortnerSession, verifyShortner } = require('../middleware/shortner');
const episodeController = require('../controllers/episodeController');

// Get episodes by folder
router.get('/folder/:folderId', optionalAuth, episodeController.getEpisodesByFolder);

// Search episodes in anime
router.get('/search/:animeId', episodeController.searchEpisodes);

// Get episode details
router.get('/:id', optionalAuth, episodeController.getEpisodeDetails);

// Get stream URL (requires auth + shortner check for free users)
router.get('/:id/stream', authenticate, checkShortnerSession('stream'), episodeController.getStreamUrl);

// Get download URL (requires auth + shortner check for free users)
router.get('/:id/download', authenticate, checkShortnerSession('download'), episodeController.getDownloadUrl);

// Verify shortner completion
router.post('/verify-shortner', authenticate, verifyShortner);

module.exports = router;
