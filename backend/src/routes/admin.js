const express = require('express');
const router = express.Router();
const { authenticate, requireAdmin } = require('../middleware/auth');
const adminController = require('../controllers/adminController');

// All admin routes require authentication + admin role
router.use(authenticate, requireAdmin);

// Dashboard
router.get('/dashboard', adminController.getDashboard);

// Anime management
router.post('/anime', adminController.createAnime);
router.put('/anime/:id', adminController.updateAnime);
router.delete('/anime/:id', adminController.deleteAnime);

// Fetch metadata
router.post('/fetch-metadata', adminController.fetchMetadata);

// Folder management
router.post('/folders', adminController.createFolder);
router.put('/folders/:id', adminController.updateFolder);
router.delete('/folders/:id', adminController.deleteFolder);

// Episode management
router.post('/episodes', adminController.createEpisode);
router.get('/anime/:animeId/episodes', adminController.getEpisodesByAnime);
router.put('/episodes/:id', adminController.updateEpisode);
router.delete('/episodes/:id', adminController.deleteEpisode);
router.post('/episodes/move', adminController.moveEpisodes);

// Premium management
router.post('/premium/grant', adminController.managePremium);
router.put('/premium/revoke/:userId', adminController.revokePremium);

// Premium activation codes (dev generates → users redeem in-app)
router.get('/premium-codes', adminController.listPremiumCodes);
router.post('/premium-codes/generate', adminController.generatePremiumCodes);
router.delete('/premium-codes/:id', adminController.deletePremiumCode);

// Announcements
router.get('/announcements', adminController.getAnnouncements);
router.post('/announcements', adminController.createAnnouncement);
router.put('/announcements/:id', adminController.updateAnnouncement);
router.delete('/announcements/:id', adminController.deleteAnnouncement);

// Reports
router.get('/reports', adminController.getReports);
router.put('/reports/:id', adminController.updateReport);

// Users
router.get('/users', adminController.getUsers);

// Settings
router.get('/settings', adminController.getSettings);
router.put('/settings', adminController.updateSettings);

module.exports = router;
