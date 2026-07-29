class AppConstants {
  // App Info
  static const String appName = 'DonghuaHub';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Your ultimate Donghua streaming destination';

  // Hive Boxes
  static const String settingsBox = 'settings';
  static const String cacheBox = 'cache';
  static const String downloadsBox = 'downloads';
  static const String historyBox = 'history';

  // Hive Keys
  static const String tokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userNameKey = 'user_name';
  static const String userEmailKey = 'user_email';
  static const String userAvatarKey = 'user_avatar';
  static const String themeKey = 'theme_mode';
  static const String primaryColorKey = 'primary_color';
  static const String amoledModeKey = 'amoled_mode';
  static const String defaultQualityKey = 'default_quality';
  static const String defaultLanguageKey = 'default_language';
  static const String subtitleSizeKey = 'subtitle_size';
  static const String autoPlayKey = 'auto_play';
  static const String firstLaunchKey = 'first_launch';

  // Video Qualities
  static const List<String> videoQualities = ['360p', '480p', '720p', '1080p', '4K'];
  static const String defaultQuality = '1080p';

  // Languages
  static const List<String> languages = ['Hindi', 'English', 'Japanese', 'Chinese'];
  static const String defaultLanguage = 'Hindi';

  // Subtitle Sizes
  static const List<String> subtitleSizes = ['small', 'medium', 'large'];
  static const String defaultSubtitleSize = 'medium';

  // Shortner Session Duration
  static const int shortnerSessionHours = 4;

  // Pagination
  static const int pageSize = 20;

  // Grid Layouts
  static const List<String> gridLayouts = ['2x2', '4x4', '5x5', '6x6', '8x8'];
  static const String defaultGridLayout = '4x4';

  // Skip Intro Duration
  static const int skipIntroSeconds = 90;

  // Auto Resume Threshold
  static const double autoResumeThreshold = 0.9; // 90%

  // Max Retries
  static const int maxRetries = 3;

  // Cache Duration
  static const Duration cacheDuration = Duration(hours: 24);
  static const Duration imageCacheDuration = Duration(days: 7);

  // Animation Durations
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // Genres
  static const List<String> genres = [
    'Action',
    'Adventure',
    'Comedy',
    'Drama',
    'Fantasy',
    'Historical',
    'Horror',
    'Martial Arts',
    'Mecha',
    'Military',
    'Music',
    'Mystery',
    'Psychological',
    'Romance',
    'School',
    'Sci-Fi',
    'Seinen',
    'Shoujo',
    'Shounen',
    'Slice of Life',
    'Sports',
    'Supernatural',
    'Thriller',
    'Xianxia',
    'Xuanhuan',
    'Cultivation',
  ];

  // Status
  static const List<String> animeStatuses = ['ongoing', 'completed', 'upcoming', 'hiatus'];

  // Error Messages
  static const String networkError = 'Please check your internet connection';
  static const String serverError = 'Server error. Please try again later';
  static const String authError = 'Please login to continue';
  static const String unknownError = 'Something went wrong';
  static const String sessionExpired = 'Session expired. Please login again';
}
