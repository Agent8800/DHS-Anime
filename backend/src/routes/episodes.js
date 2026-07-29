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

// In-app streaming was removed — episodes are downloaded via
// third-party links and played offline with the built-in player.

// Get third-party download links (requires auth + shortner check for free users)
router.get('/:id/download-links', authenticate, checkShortnerSession('download'), episodeController.getDownloadLinks);

// Verify shortner completion
router.post('/verify-shortner', authenticate, verifyShortner);

module.exports = router;
