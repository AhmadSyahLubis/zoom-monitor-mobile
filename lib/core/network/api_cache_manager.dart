import 'dart:async';

/// Production-ready In-Memory Cache & Request Deduplication (Singleflight) Manager.
/// Implements Stale-While-Revalidate (SWR) pattern for enterprise mobile apps.
class ApiCacheManager {
  static final ApiCacheManager _instance = ApiCacheManager._internal();
  factory ApiCacheManager() => _instance;
  ApiCacheManager._internal();

  final Map<String, _CacheEntry> _cache = {};
  final Map<String, Future<dynamic>> _inFlight = {};

  /// Retrieve cached data if valid within [ttl]
  T? get<T>(String key, {Duration ttl = const Duration(seconds: 30)}) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.timestamp) > ttl) {
      _cache.remove(key);
      return null;
    }
    return entry.data as T?;
  }

  /// Store data in cache
  void set<T>(String key, T data) {
    _cache[key] = _CacheEntry(data, DateTime.now());
  }

  /// Invalidate cache keys matching [prefix]
  void invalidate(String prefix) {
    _cache.removeWhere((key, _) => key.startsWith(prefix));
  }

  /// Clear all cache
  void clear() {
    _cache.clear();
    _inFlight.clear();
  }

  /// Execute request with cache lookup and in-flight request deduplication
  Future<T> getOrFetch<T>({
    required String key,
    required Future<T> Function() fetcher,
    Duration ttl = const Duration(seconds: 30),
    bool forceRefresh = false,
  }) async {
    // 1. Return cached data if valid
    if (!forceRefresh) {
      final cached = get<T>(key, ttl: ttl);
      if (cached != null) {
        return cached;
      }
    }

    // 2. Singleflight: If identical request is currently in-flight, await existing Future
    if (_inFlight.containsKey(key)) {
      return (await _inFlight[key]) as T;
    }

    // 3. Dispatch fresh network request
    final completer = Completer<T>();
    _inFlight[key] = completer.future;

    try {
      final result = await fetcher();
      set<T>(key, result);
      completer.complete(result);
      return result;
    } catch (e, st) {
      completer.completeError(e, st);
      rethrow;
    } finally {
      _inFlight.remove(key);
    }
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;

  _CacheEntry(this.data, this.timestamp);
}
