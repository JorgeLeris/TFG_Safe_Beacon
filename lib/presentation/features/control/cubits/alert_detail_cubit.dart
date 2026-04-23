import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_beacon/domain/alerts/alert_repository.dart';
import 'package:safe_beacon/domain/alerts/entities/alert.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';

part 'alert_detail_state.dart';
part 'alert_detail_cubit.freezed.dart';

class AlertDetailCubit extends Cubit<AlertDetailState> {
  AlertDetailCubit({
    required String alertId,
    required AlertRepository alertRepository,
    required UserProfileRepository userProfileRepository,
  }) : _alertId = alertId,
       _alertRepository = alertRepository,
       _userProfileRepository = userProfileRepository,
       super(const AlertDetailState());

  final String _alertId;
  final AlertRepository _alertRepository;
  final UserProfileRepository _userProfileRepository;

  /// Loads the alert details and resolves the owner's display name.
  Future<void> loadAlertDetail() async {
    emit(state.copyWith(isLoading: true, failure: null));

    final result = await _alertRepository.getAlertDetails(_alertId);

    await result.when(
      success: (alert) async {
        // Resolve owner profile for display name.
        String displayName = alert.ownerUsername;
        String? displayProfilePhoto;

        final profileResult = await _userProfileRepository.getProfile(
          alert.ownerUid,
        );
        profileResult.when(
          success: (profile) {
            final name = profile.name;
            final surname = profile.surname ?? '';
            displayName = '$name $surname'.trim();
            displayProfilePhoto = profile.profilePhoto;
          },
          failure: (_) {},
        );

        emit(
          state.copyWith(
            isLoading: false,
            alert: alert,
            displayName: displayName,
            displayProfilePhoto: displayProfilePhoto,
          ),
        );
      },
      failure: (failure) async =>
          emit(state.copyWith(isLoading: false, failure: failure)),
    );
  }
}
