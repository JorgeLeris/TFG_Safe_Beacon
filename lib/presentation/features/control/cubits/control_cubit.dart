import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/contacts/contact_request_repository.dart';

part 'control_state.dart';
part 'control_cubit.freezed.dart';

class ControlCubit extends Cubit<ControlState> {
  ControlCubit({
    required String uid,
    required ContactRequestRepository contactRequestRepository,
  }) : _uid = uid,
       _contactRequestRepository = contactRequestRepository,
       super(const ControlState());

  final String _uid;
  final ContactRequestRepository _contactRequestRepository;

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
}
