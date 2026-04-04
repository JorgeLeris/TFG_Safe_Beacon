import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_beacon/app/monitoring/logging.dart';
import 'package:safe_beacon/data/sources/firebase/profile/dto/user_profile_dto.dart';
import 'package:safe_beacon/data/sources/firebase/profile/user_profile_api.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/profile/entities/user_profile.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';

/// Repository for managing [UserProfile] entities in Firestore.
class UserProfileRepositoryImpl implements UserProfileRepository {
  /// Creates an instance of [UserProfileRepositoryImpl] using the given
  /// [UserProfileApi].
  ///
  /// The [_api] parameter is required.
  UserProfileRepositoryImpl({required UserProfileApi api}) : _api = api;

  /// The Firestore API used for CRUD operations.
  final UserProfileApi _api;

  /// Creates a new [UserProfile] in Firestore.
  ///
  /// The [profile] uid is used as the Firestore document ID and must
  /// correspond to the currently authenticated user. The [createdAt] timestamp
  /// is set server-side by Firestore and is not taken from [profile].
  /// The username is generated automatically from [email] and guaranteed
  /// to be unique via an atomic Firestore transaction.
  /// Returns a [Result] containing `null` on success or an [AppFailure] if an error occurs.
  @override
  Future<Result<void>> createProfile(UserProfile profile, String email) async {
    appLogger.fine('Creating UserProfile for uid: ${profile.uid}');
    try {
      String? username;

      username = await _resolveUsername(email);
      try {
        await _api.createProfileWithUsername(
          profile.uid,
          UserProfileDto(
            name: profile.name,
            surname: profile.surname,
            gender: profile.gender,
            birthDate: profile.birthDate,
            description: profile.description,
            profilePhoto: profile.profilePhoto,
            username: username,
            createdAt: DateTime.now(),
          ),
          username,
        );
      } on Exception catch (e) {
        if (e.toString().contains('username_taken')) {
          appLogger.warning(
            'Username race condition detected for "$username", retrying...',
          );
        }
        rethrow;
      }

      appLogger.info(
        'UserProfile created successfully for uid: ${profile.uid} '
        'with username: $username',
      );
      return const Result.success(null);
    } on FirebaseException catch (e, st) {
      appLogger.warning(
        'Firebase error creating UserProfile (code: ${e.code})',
      );
      appLogger.severe('Exception while creating UserProfile', e, st);
      return Result.failure(_mapFirebaseError(e));
    } catch (e, st) {
      appLogger.severe('Unexpected error creating UserProfile', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  /// Retrieves the [UserProfile] identified by [uid].
  ///
  /// Returns a [Result] containing the [UserProfile] on success,
  /// or an [AppFailure] if no document is found or an error occurs.
  @override
  Future<Result<UserProfile>> getProfile(String uid) async {
    appLogger.fine('Fetching UserProfile for uid: $uid');
    try {
      final dto = await _api.getProfile(uid);
      final profile = UserProfile(
        uid: uid,
        name: dto.name,
        surname: dto.surname,
        gender: dto.gender,
        birthDate: dto.birthDate,
        description: dto.description,
        profilePhoto: dto.profilePhoto,
        username: dto.username,
      );
      appLogger.info('UserProfile fetched successfully for uid: $uid');
      return Result.success(profile);
    } on FirebaseException catch (e, st) {
      appLogger.warning(
        'Firebase error fetching UserProfile (code: ${e.code})',
      );
      appLogger.severe('Exception while fetching UserProfile', e, st);
      return Result.failure(_mapFirebaseError(e));
    } on StateError catch (e, st) {
      appLogger.warning('UserProfile not found for uid: $uid');
      appLogger.severe('StateError while fetching UserProfile', e, st);
      return const Result.failure(AppFailure.notFound());
    } catch (e, st) {
      appLogger.severe('Unexpected error fetching UserProfile', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  /// Updates the authenticated user's own [UserProfile] in Firestore.
  ///
  /// All mutable fields from [profile] are written to the document identified
  /// by [profile] uid. The [createdAt] field is never overwritten.
  /// The caller must be the authenticated user who owns the profile;
  /// Returns a [Result] containing `null` on success or an [AppFailure]
  /// if an error occurs.
  @override
  Future<Result<void>> updateProfile(UserProfile profile) async {
    appLogger.fine('Updating UserProfile for uid: ${profile.uid}');
    try {
      await _api.updateProfile(profile.uid, profile.toUpdateMap());
      appLogger.info(
        'UserProfile updated successfully for uid: ${profile.uid}',
      );
      return const Result.success(null);
    } on FirebaseException catch (e, st) {
      appLogger.warning(
        'Firebase error updating UserProfile (code: ${e.code})',
      );
      appLogger.severe('Exception while updating UserProfile', e, st);
      return Result.failure(_mapFirebaseError(e));
    } catch (e, st) {
      appLogger.severe('Unexpected error updating UserProfile', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  /// Maps a [FirebaseException] to an [AppFailure].
  ///
  /// This is used internally to convert Firestore-specific errors
  /// into the app's generic failure type.
  AppFailure _mapFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const AppFailure.forbidden();
      case 'unavailable':
        return const AppFailure.network();
      case 'not-found':
        return const AppFailure.notFound();
      default:
        return const AppFailure.unknown();
    }
  }

  /// Stores [token] as the single FCM token for the user identified by [uid].
  @override
  Future<Result<void>> saveFcmToken(String uid, String token) async {
    appLogger.fine('Saving FCM token for uid: $uid');
    try {
      await _api.saveFcmToken(uid, token);
      appLogger.info('FCM token saved for uid: $uid');
      return const Result.success(null);
    } on FirebaseException catch (e, st) {
      appLogger.severe('Firebase error saving FCM token', e, st);
      return Result.failure(_mapFirebaseError(e));
    } catch (e, st) {
      appLogger.severe('Unexpected error saving FCM token', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  /// Removes the FCM token field from the user identified by [uid].
  @override
  Future<Result<void>> clearFcmToken(String uid, String token) async {
    appLogger.fine('Clearing FCM token for uid: $uid');
    try {
      await _api.clearFcmToken(uid, token);
      appLogger.info('FCM token cleared for uid: $uid');
      return const Result.success(null);
    } on FirebaseException catch (e, st) {
      appLogger.severe('Firebase error clearing FCM token', e, st);
      return Result.failure(_mapFirebaseError(e));
    } catch (e, st) {
      appLogger.severe('Unexpected error clearing FCM token', e, st);
      return const Result.failure(AppFailure.unknown());
    }
  }

  Future<String> _resolveUsername(String email) async {
    final base = UsernameGenerator.fromEmail(email);

    // First try the base username without suffix.
    if (!await _api.usernameExists(base)) return base;

    // Try up to 5 times with random suffixes to resolve collisions.
    for (var i = 0; i < 5; i++) {
      final candidate = UsernameGenerator.withSuffix(base);
      if (!await _api.usernameExists(candidate)) return candidate;
    }

    // Fallback almost impossible: timestamp
    return '${base}_${DateTime.now().millisecondsSinceEpoch}';
  }
}

class UsernameGenerator {
  /// Derives a sanitized base username from an email address.
  static String fromEmail(String email) {
    final local = email.split('@').first;
    final noTag = local.split('+').first;
    final lower = noTag.toLowerCase();
    final ascii = _removeDiacritics(lower);
    final clean = ascii.replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return clean;
  }

  /// Appends a random 4-digit suffix to resolve collisions.
  static String withSuffix(String base) {
    final suffix = (1000 + Random().nextInt(9000)).toString();
    return '${base}_$suffix';
  }

  static String _removeDiacritics(String s) {
    const accents = 'áàäâãåéèëêíìïîóòöôõúùüûñç';
    const base = 'aaaaaaeeeeiiiioooooouuuunc';
    var result = s;
    for (var i = 0; i < accents.length; i++) {
      result = result.replaceAll(accents[i], base[i]);
    }
    return result;
  }
}
