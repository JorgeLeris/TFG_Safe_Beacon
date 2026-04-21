import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_beacon/domain/alerts/alert_repository.dart';
import 'package:safe_beacon/domain/alerts/entities/alert.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/contacts/contact_request_repository.dart';
import 'package:safe_beacon/domain/guardian_mode/entities/guardian_session.dart';
import 'package:safe_beacon/domain/guardian_mode/guardian_session_repository.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';

part 'control_state.dart';
part 'control_cubit.freezed.dart';

class ControlCubit extends Cubit<ControlState> {
  ControlCubit({
    required String uid,
    required ContactRequestRepository contactRequestRepository,
    required AlertRepository alertRepository,
    required UserProfileRepository userProfileRepository,
    required GuardianSessionRepository guardianSessionRepository,
  }) : _uid = uid,
       _contactRequestRepository = contactRequestRepository,
       _alertRepository = alertRepository,
       _userProfileRepository = userProfileRepository,
       _guardianSessionRepository = guardianSessionRepository,
       super(const ControlState());

  final String _uid;
  final ContactRequestRepository _contactRequestRepository;
  final AlertRepository _alertRepository;
  final UserProfileRepository _userProfileRepository;
  final GuardianSessionRepository _guardianSessionRepository;

  /// Simulates a short loading state while applying alert filters.
  Future<void> applyFiltersWithLoading() async {
    emit(state.copyWith(isApplyingFilters: true));
    await Future.delayed(const Duration(milliseconds: 500));
    emit(state.copyWith(isApplyingFilters: false));
  }

  /// Loads the count of pending contact requests received by the current user.
  Future<void> loadReceivedRequestsCount() async {
    emit(state.copyWith(isLoadingCount: true, countFailure: null));

    final result = await _contactRequestRepository.getReceivedRequestsCount(
      _uid,
    );

    result.when(
      success: (count) => emit(
        state.copyWith(isLoadingCount: false, receivedRequestsCount: count),
      ),
      failure: (failure) =>
          emit(state.copyWith(isLoadingCount: false, countFailure: failure)),
    );
  }

  /// Loads guardian mode sessions where the current user is a trusted contact.
  Future<void> loadFollowUps() async {
    emit(state.copyWith(isLoadingFollowUps: true, followUpsFailure: null));

    final result = await _guardianSessionRepository.getContactsSessions(_uid);

    await result.when(
      success: (sessions) async {
        final displayNames = <String, String>{};
        final profilePhotos = <String, String>{};
        final uniqueUids = sessions.map((s) => s.ownerUid).toSet();

        await Future.wait(
          uniqueUids.map((uid) async {
            final profileResult = await _userProfileRepository.getProfile(uid);
            profileResult.when(
              success: (profile) {
                final name = profile.name;
                final surname = profile.surname ?? '';
                displayNames[uid] = '$name $surname'.trim();
                if (profile.profilePhoto != null) {
                  profilePhotos[uid] = profile.profilePhoto!;
                }
              },
              failure: (_) {},
            );
          }),
        );

        emit(
          state.copyWith(
            isLoadingFollowUps: false,
            followUps: sessions,
            followUpDisplayNames: displayNames,
            followUpProfilePhotos: profilePhotos,
          ),
        );
      },
      failure: (failure) async => emit(
        state.copyWith(isLoadingFollowUps: false, followUpsFailure: failure),
      ),
    );
  }

  /// Loads alerts from all protected people where the current user is a trusted contact.
  Future<void> loadAlerts() async {
    emit(state.copyWith(isLoadingAlerts: true, alertsFailure: null));

    final result = await _alertRepository.getContactsAlerts(_uid);

    await result.when(
      success: (alerts) async {
        // Resolve display names concurrently. Cache profiles by uid to avoid
        // redundant Firestore reads when the same owner has multiple alerts.
        final displayNames = <String, String>{};
        final profilePhotos = <String, String>{};
        final uniqueUids = alerts.map((a) => a.ownerUid).toSet();

        await Future.wait(
          uniqueUids.map((uid) async {
            final profileResult = await _userProfileRepository.getProfile(uid);
            profileResult.when(
              success: (profile) {
                final name = profile.name;
                final surname = profile.surname ?? '';
                displayNames[uid] = '$name $surname'.trim();
                if (profile.profilePhoto != null) {
                  profilePhotos[uid] = profile.profilePhoto!;
                }
              },
              failure: (_) {},
            );
          }),
        );

        // Fill missing entries with the alert's ownerUsername.
        for (final alert in alerts) {
          displayNames.putIfAbsent(alert.ownerUid, () => alert.ownerUsername);
        }

        emit(
          state.copyWith(
            isLoadingAlerts: false,
            alerts: alerts,
            alertDisplayNames: displayNames,
            alertProfilePhotos: profilePhotos,
          ),
        );
      },
      failure: (failure) async =>
          emit(state.copyWith(isLoadingAlerts: false, alertsFailure: failure)),
    );
  }
}
