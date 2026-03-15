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
  /// Returns a [Result] containing `null` on success or an [AppFailure] if an error occurs.
  @override
  Future<Result<void>> createProfile(UserProfile profile) async {
    appLogger.fine('Creating UserProfile for uid: ${profile.uid}');
    try {
      await _api.createProfile(
        profile.uid,
        UserProfileDto(
          name: profile.name,
          surname: profile.surname,
          gender: profile.gender,
          birthDate: profile.birthDate,
          description: profile.description,
          profilePhoto: profile.profilePhoto,
          createdAt: DateTime.now(),
        ),
      );
      appLogger.info(
        'UserProfile created successfully for uid: ${profile.uid}',
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
}
