const express = require('express');
const router = express.Router();
const { authenticate, optionalAuth } = require('../middleware/auth');
const animeController = require('../controllers/animeController');

// Home data
router.get('/home', optionalAuth, animeController.getHomeData);

// Search
router.get('/search', animeController.searchAnime);

// Trending
router.get('/trending', animeController.getTrending);

// By genre
router.get('/genre/:genre', animeController.getByGenre);

// Get all anime (with filters)
router.get('/', animeController.getAnimeList);

// Get anime by ID
router.get('/:id', optionalAuth, animeController.getAnimeById);

// Increment view
router.post('/:id/view', animeController.incrementView);

module.exports = router;
