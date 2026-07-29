class ApiConfig {
  // Base URLs
  static const String baseUrl = 'http://10.0.2.2:5000/api'; // Android emulator
  static const String iosBaseUrl = 'http://localhost:5000/api'; // iOS simulator
  static const String webBaseUrl = 'http://localhost:5000/api'; // Web

  // API Endpoints
  static const String auth = '/auth';
  static const String anime = '/anime';
  static const String episodes = '/episodes';
  static const String watchHistory = '/watch-history';
  static const String bookmarks = '/bookmarks';
  static const String admin = '/admin';
  static const String settings = '/settings';

  // Timeouts
  static const int connectTimeout = 30000;
  static const int receiveTimeout = 30000;
  static const int sendTimeout = 30000;

  // Pagination
  static const int defaultPageSize = 20;

  // Cache Duration
  static const int cacheDurationMinutes = 30;
}
