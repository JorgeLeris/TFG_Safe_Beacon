import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/profile/entities/user_profile.dart';

/// Contract for UserProfile repository.
///
/// Defines the operations available for UserProfile entities.
abstract class UserProfileRepository {
  /// Creates a new user profile for the authenticated user.
  ///
  /// The [profile] uid must match the authenticated user's UID,
  /// as it is used as the Firestore document ID.
  Future<Result<void>> createProfile(UserProfile profile);

  /// Retrieves a single [UserProfile] by its [uid].
  Future<Result<UserProfile>> getProfile(String uid);

  /// Updates the authenticated user's own profile.
  ///
  /// The [profile] uid identifies the document to update. The caller must be
  /// the authenticated user who owns the profile.
  Future<Result<void>> updateProfile(UserProfile profile);
}
