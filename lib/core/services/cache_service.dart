import 'package:shared_preferences/shared_preferences.dart';

/// A service to handle persistent caching of city background images.
class LocalCacheService {
  static const String _imagePrefix = 'city_image_';
  static const String _timePrefix = 'city_time_';

  /// Saves the image URL for a city with the current timestamp.
  Future<void> saveCityImage(String cityName, String imageUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;

    await prefs.setString('$_imagePrefix$cityName', imageUrl);
    await prefs.setInt('$_timePrefix$cityName', now);
  }

  /// Retrieves the cached image URL if it's less than 24 hours old.
  Future<String?> getCachedCityImage(String cityName) async {
    final prefs = await SharedPreferences.getInstance();

    final imageUrl = prefs.getString('$_imagePrefix$cityName');
    final timestamp = prefs.getInt('$_timePrefix$cityName');

    if (imageUrl == null || timestamp == null) return null;

    final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(cachedTime);

    // Check if 24 hours have passed
    if (difference.inHours < 24) {
      return imageUrl;
    }

    return null;
  }
}
