import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  // Cache chungah data le a lakmi caan (timestamp) kan khon chih lai
  static final Map<String, Map<String, dynamic>> _cache = {};

  // Cache a nun caan (Tahchunhnak: Minute 60)
  static const int _cacheLifespanMinutes = 60;

  static Future<Map<String, dynamic>> getUserData({
    required String uid,
    required String fallbackName,
    String? fallbackPhotoUrl,
  }) async {
    final now = DateTime.now();

    // 1. Cache chungah a um cia maw le a caan a liam cang maw check nak
    if (_cache.containsKey(uid)) {
      final cachedTime = _cache[uid]!['timestamp'] as DateTime;
      final difference = now.difference(cachedTime).inMinutes;

      // Minute 60 a tlin rih lo ahcun a hlunmi te kha a hman tthan colh lai (Phaisa khamhnak)
      if (difference < _cacheLifespanMinutes) {
        return _cache[uid]!;
      }
    }

    // 2. Cache ah a um lo asiloah a caan a liam (Expire) cang ahcun Firebase ah a laak lai
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (doc.exists) {
        var data = doc.data() as Map<String, dynamic>;

        // Data thar cu Cache ah a save lai i, caan (now) kha a thun chih lai
        _cache[uid] = {
          'name': data['name'] ?? data['displayName'] ?? fallbackName,
          'photoUrl': data['photoUrl'] ?? data['profilePic'] ?? fallbackPhotoUrl,
          'timestamp': now,
        };
        return _cache[uid]!;
      }
    } catch (e) {
      print("User fetch error: $e");
    }

    // Firebase in lak a ngah lo hmanhah Fallback data a pe lai (App a crash lai lo)
    return {
      'name': fallbackName,
      'photoUrl': fallbackPhotoUrl,
      'timestamp': now,
    };
  }
}