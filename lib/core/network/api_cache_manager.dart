class ApiCacheManager {
  static final ApiCacheManager _instance = ApiCacheManager._internal();
  factory ApiCacheManager() => _instance;
  ApiCacheManager._internal();

  final Map<String, _CacheEntry> _cache = {};
  final Map<String, _InFlight> _inFlight = {};
  static const int _maxEntries = 128;

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
    _cache.remove(key);
    _cache[key] = _CacheEntry(data, DateTime.now());
    if (_cache.length > _maxEntries) {
      _cache.remove(_cache.keys.first);
    }
  }

  /// Invalidate cache keys matching [prefix]
  void invalidate(String prefix) {
    _cache.removeWhere((key, _) => key.startsWith(prefix));
    _inFlight.removeWhere((key, _) => key.startsWith(prefix));
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
    if (!forceRefresh) {
      final cached = get<T>(key, ttl: ttl);
      if (cached != null) {
        return cached;
      }
    }

    final inFlight = _inFlight[key];
    if (inFlight != null) {
      return (await inFlight.future) as T;
    }

    final token = Object();
    final request = _fetch(key, fetcher, token);
    _inFlight[key] = _InFlight(token, request);
    return request;
  }

  Future<T> _fetch<T>(
    String key,
    Future<T> Function() fetcher,
    Object token,
  ) async {
    try {
      final result = await Future<T>.sync(fetcher);
      if (identical(_inFlight[key]?.token, token)) {
        set<T>(key, result);
      }
      return result;
    } finally {
      if (identical(_inFlight[key]?.token, token)) {
        _inFlight.remove(key);
      }
    }
  }
}

class _InFlight {
  final Object token;
  final Future<dynamic> future;

  _InFlight(this.token, this.future);
}

class _CacheEntry {
  final dynamic data;
  final DateTime timestamp;

  _CacheEntry(this.data, this.timestamp);
}
