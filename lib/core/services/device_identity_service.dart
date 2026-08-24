import 'dart:io';
import 'dart:math';

import 'package:android_id/android_id.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../utils/app_logger.dart';

const _tag = 'DeviceIdentity';
const _secureStorageKey = 'persistent_device_id';

/// Identifies this physical device, surviving an app uninstall/reinstall —
/// unlike Firebase Auth's anonymous uid (which Android wipes on uninstall,
/// and which iOS only happens to preserve via undocumented Keychain
/// behavior), this is a deliberately durable ID:
///
/// - Android: `Settings.Secure.ANDROID_ID`, stable across reinstall of the
///   same signed app on the same device (changes only on factory reset or
///   a different signing key).
/// - iOS (and any other platform): a random ID generated once and stored
///   in the Keychain via [FlutterSecureStorage] — Keychain entries are not
///   cleared when an app is uninstalled, only on a full device erase.
///
/// Firebase Anonymous Auth is still used underneath (Firestore security
/// rules need *some* `request.auth != null` check), but it's no longer the
/// identity itself — this service upserts a `devices/{deviceId}` Firestore
/// document linking the durable ID to whichever anonymous uid is currently
/// signed in, and everything else in the app keys off [currentDeviceId].
abstract class DeviceIdentityService {
  /// Resolves this device's durable ID (signing in anonymously first if
  /// needed) and upserts its `devices/{deviceId}` Firestore document.
  Future<String> ensureDeviceId();

  /// The current device's durable ID. Null before [ensureDeviceId] has
  /// been called at least once.
  String? get currentDeviceId;
}

class DeviceIdentityServiceImpl implements DeviceIdentityService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FlutterSecureStorage _secureStorage;
  final AndroidId _androidId;

  String? _cachedDeviceId;

  DeviceIdentityServiceImpl({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FlutterSecureStorage? secureStorage,
    AndroidId? androidId,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _androidId = androidId ?? const AndroidId();

  @override
  String? get currentDeviceId => _cachedDeviceId;

  @override
  Future<String> ensureDeviceId() async {
    final uid = await _ensureSignedIn();
    final deviceId = await _resolvePersistentId();
    _cachedDeviceId = deviceId;
    await _upsertDeviceDoc(deviceId, uid);
    return deviceId;
  }

  Future<String> _ensureSignedIn() async {
    final existing = _auth.currentUser;
    if (existing != null) {
      AppLogger.firebase(_tag, 'Already signed in: ${existing.uid}');
      return existing.uid;
    }

    AppLogger.firebase(_tag, 'No existing user — signing in anonymously...');
    try {
      final credential = await _auth.signInAnonymously();
      final uid = credential.user?.uid;
      if (uid == null) {
        AppLogger.error(_tag, 'Anonymous sign-in succeeded but returned no user');
        throw StateError('Anonymous sign-in succeeded but returned no user.');
      }
      AppLogger.firebase(_tag, 'Signed in anonymously: $uid');
      return uid;
    } catch (e, stackTrace) {
      AppLogger.error(_tag, 'Anonymous sign-in failed', e, stackTrace);
      rethrow;
    }
  }

  Future<String> _resolvePersistentId() async {
    if (Platform.isAndroid) {
      try {
        final androidId = await _androidId.getId();
        if (androidId != null && androidId.isNotEmpty) {
          AppLogger.info(_tag, 'Resolved persistent device ID from ANDROID_ID');
          return androidId;
        }
        AppLogger.error(_tag, 'ANDROID_ID unavailable — falling back to a stored random ID');
      } catch (e, stackTrace) {
        AppLogger.error(_tag, 'Could not read ANDROID_ID — falling back to a stored random ID', e,
            stackTrace);
      }
    }

    final stored = await _secureStorage.read(key: _secureStorageKey);
    if (stored != null && stored.isNotEmpty) {
      AppLogger.info(_tag, 'Resolved persistent device ID from secure storage');
      return stored;
    }

    final generated = _generateRandomId();
    await _secureStorage.write(key: _secureStorageKey, value: generated);
    AppLogger.info(_tag, 'Generated and stored a new persistent device ID');
    return generated;
  }

  String _generateRandomId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  Future<void> _upsertDeviceDoc(String deviceId, String uid) async {
    try {
      final docRef = _firestore.collection('devices').doc(deviceId);
      AppLogger.firebase(_tag, 'Upserting devices/$deviceId (currentUid=$uid)...');
      final snapshot = await docRef.get();
      await docRef.set({
        'platform': Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'other'),
        'currentUid': uid,
        'lastSeenAt': FieldValue.serverTimestamp(),
        if (!snapshot.exists) 'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      AppLogger.firebase(_tag, 'devices/$deviceId upserted');
    } catch (e, stackTrace) {
      // Non-fatal — the device can still be used locally/offline even if
      // this particular sync fails; it'll retry on the next launch.
      AppLogger.error(_tag, 'Could not upsert devices/$deviceId', e, stackTrace);
    }
  }
}
