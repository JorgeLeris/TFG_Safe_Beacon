import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:safe_beacon/domain/alerts/alert_repository.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/contacts/contact_request_repository.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';
import 'package:safe_beacon/presentation/features/control/cubits/control_cubit.dart';

// MARK: - DUMMY DATA

class MockContactRequestRepository extends Mock
    implements ContactRequestRepository {}

class MockAlertRepository extends Mock implements AlertRepository {}

class MockUserProfileRepository extends Mock
    implements UserProfileRepository {}

const _uid = 'uid_test';
const _dummyFailure = AppFailure.unknown();

// MARK: - TEST CASES

void main() {
  late MockContactRequestRepository mockContactRequestRepository;
  late MockAlertRepository mockAlertRepository;
  late MockUserProfileRepository mockUserProfileRepository;
  late ControlCubit controlCubit;

  setUp(() {
    mockContactRequestRepository = MockContactRequestRepository();
    mockAlertRepository = MockAlertRepository();
    mockUserProfileRepository = MockUserProfileRepository();
    controlCubit = ControlCubit(
      uid: _uid,
      contactRequestRepository: mockContactRequestRepository,
      alertRepository: mockAlertRepository,
      userProfileRepository: mockUserProfileRepository,
    );
  });

  tearDown(() {
    controlCubit.close();
  });

  group('ControlCubit.loadReceivedRequestsCount', () {
    blocTest<ControlCubit, ControlState>(
      '[HAPPY PATH] - GIVEN the repository returns a count, WHEN loadReceivedRequestsCount is called, THEN should emit [isLoadingCount: true, isLoadingCount: false with count]',
      build: () {
        when(
          () => mockContactRequestRepository.getReceivedRequestsCount(_uid),
        ).thenAnswer((_) async => const Result.success(3));
        return controlCubit;
      },
      act: (cubit) => cubit.loadReceivedRequestsCount(),
      expect: () => [
        const ControlState(isLoadingCount: true),
        const ControlState(receivedRequestsCount: 3),
      ],
      verify: (_) {
        verify(
          () => mockContactRequestRepository.getReceivedRequestsCount(_uid),
        ).called(1);
      },
    );

    blocTest<ControlCubit, ControlState>(
      '[ERROR PATH] - GIVEN the repository returns a failure, WHEN loadReceivedRequestsCount is called, THEN should emit [isLoadingCount: true, isLoadingCount: false with countFailure]',
      build: () {
        when(
          () => mockContactRequestRepository.getReceivedRequestsCount(_uid),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return controlCubit;
      },
      act: (cubit) => cubit.loadReceivedRequestsCount(),
      expect: () => [
        const ControlState(isLoadingCount: true),
        const ControlState(countFailure: _dummyFailure),
      ],
      verify: (_) {
        verify(
          () => mockContactRequestRepository.getReceivedRequestsCount(_uid),
        ).called(1);
      },
    );
  });
}
