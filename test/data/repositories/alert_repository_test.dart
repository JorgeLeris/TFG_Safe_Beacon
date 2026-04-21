import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_beacon/data/repositories/alert_repository_impl.dart';
import 'package:safe_beacon/data/sources/firebase/alerts/alert_api.dart';
import 'package:safe_beacon/data/sources/firebase/alerts/dto/alert_dto.dart';
import 'package:safe_beacon/domain/alerts/entities/alert.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';

// MARK: - DUMMY DATA & MOCKS

class MockAlertApi extends Mock implements AlertApi {}

class FakeAlertDto extends Fake implements AlertDto {}

const dummyOwnerUid = 'uid-123';
const dummyOwnerUsername = 'john_doe';
const dummyAlertId = 'alert-abc';

final dummyAlertDto = AlertDto(
  ownerUid: dummyOwnerUid,
  ownerUsername: dummyOwnerUsername,
  alertType: AlertType.panic.name,
  latitude: 41.6488,
  longitude: -0.8891,
  batteryLevel: 80,
  status: AlertStatus.active.name,
  trustedContactUids: ['contact-1', 'contact-2'],
  activatedAt: DateTime(2024),
);

final dummyAlertWithId = (id: dummyAlertId, dto: dummyAlertDto);

/// Creates a [FirebaseException] with the given [code].
FirebaseException _firebaseException(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code);

// MARK: - TEST CASES

void main() {
  late MockAlertApi mockApi;
  late AlertRepositoryImpl repository;

  setUp(() {
    mockApi = MockAlertApi();
    repository = AlertRepositoryImpl(api: mockApi);
    registerFallbackValue(FakeAlertDto());
  });

  // ---------------------------------------------------------------------------
  // createAlert
  // ---------------------------------------------------------------------------

  group('AlertRepositoryImpl.createAlert', () {
    test(
      '[HAPPY PATH] - GIVEN valid alert parameters, '
      'WHEN createAlert is called, '
      'THEN should call api.createAlert once and return Result.success',
      () async {
        // Arrange.
        when(() => mockApi.createAlert(any())).thenAnswer((_) async {});

        // Act.
        final result = await repository.createAlert(
          ownerUid: dummyOwnerUid,
          ownerUsername: dummyOwnerUsername,
          alertType: AlertType.panic,
          latitude: 41.6488,
          longitude: -0.8891,
          batteryLevel: 80,
        );

        // Assert.
        expect(result.isSuccess, isTrue);
        verify(() => mockApi.createAlert(any())).called(1);
      },
    );

    test(
      '[ERROR PATH] - GIVEN the user already has an active alert, '
      'WHEN createAlert is called, '
      'THEN should return Result.failure with AppFailure.conflict()',
      () async {
        // Arrange.
        when(
          () => mockApi.createAlert(any()),
        ).thenThrow(Exception('alert_already_active'));

        // Act.
        final result = await repository.createAlert(
          ownerUid: dummyOwnerUid,
          ownerUsername: dummyOwnerUsername,
          alertType: AlertType.panic,
          latitude: 41.6488,
          longitude: -0.8891,
          batteryLevel: 80,
        );

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(
            const Result<void>.failure(
              AppFailure.conflict('alert_already_active'),
            ),
          ),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN the user has no trusted contacts, '
      'WHEN createAlert is called, '
      'THEN should return Result.failure with AppFailure.business()',
      () async {
        // Arrange.
        when(
          () => mockApi.createAlert(any()),
        ).thenThrow(Exception('no_trusted_contacts'));

        // Act.
        final result = await repository.createAlert(
          ownerUid: dummyOwnerUid,
          ownerUsername: dummyOwnerUsername,
          alertType: AlertType.panic,
          latitude: 41.6488,
          longitude: -0.8891,
          batteryLevel: 80,
        );

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(
            const Result<void>.failure(
              AppFailure.business('no_trusted_contacts'),
            ),
          ),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN a permission-denied FirebaseException, '
      'WHEN createAlert is called, '
      'THEN should return Result.failure with AppFailure.forbidden()',
      () async {
        // Arrange.
        when(
          () => mockApi.createAlert(any()),
        ).thenThrow(_firebaseException('permission-denied'));

        // Act.
        final result = await repository.createAlert(
          ownerUid: dummyOwnerUid,
          ownerUsername: dummyOwnerUsername,
          alertType: AlertType.panic,
          latitude: 41.6488,
          longitude: -0.8891,
          batteryLevel: 80,
        );

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<void>.failure(AppFailure.forbidden())),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN an unavailable FirebaseException, '
      'WHEN createAlert is called, '
      'THEN should return Result.failure with AppFailure.network()',
      () async {
        // Arrange.
        when(
          () => mockApi.createAlert(any()),
        ).thenThrow(_firebaseException('unavailable'));

        // Act.
        final result = await repository.createAlert(
          ownerUid: dummyOwnerUid,
          ownerUsername: dummyOwnerUsername,
          alertType: AlertType.panic,
          latitude: 41.6488,
          longitude: -0.8891,
          batteryLevel: 80,
        );

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<void>.failure(AppFailure.network())),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // deactivateAlert
  // ---------------------------------------------------------------------------

  group('AlertRepositoryImpl.deactivateAlert', () {
    test(
      '[HAPPY PATH] - GIVEN a user with an active alert, '
      'WHEN deactivateAlert is called, '
      'THEN should call api.deactivateAlert once and return Result.success',
      () async {
        // Arrange.
        when(
          () => mockApi.deactivateAlert(
            ownerUid: dummyOwnerUid,
            cancellationReason: any(named: 'cancellationReason'),
          ),
        ).thenAnswer((_) async {});

        // Act.
        final result = await repository.deactivateAlert(
          ownerUid: dummyOwnerUid,
        );

        // Assert.
        expect(result.isSuccess, isTrue);
        verify(
          () => mockApi.deactivateAlert(
            ownerUid: dummyOwnerUid,
            cancellationReason: any(named: 'cancellationReason'),
          ),
        ).called(1);
      },
    );

    test(
      '[ERROR PATH] - GIVEN no active alert exists for the user, '
      'WHEN deactivateAlert is called, '
      'THEN should return Result.failure with AppFailure.notFound()',
      () async {
        // Arrange.
        when(
          () => mockApi.deactivateAlert(
            ownerUid: any(named: 'ownerUid'),
            cancellationReason: any(named: 'cancellationReason'),
          ),
        ).thenThrow(Exception('no_active_alert'));

        // Act.
        final result = await repository.deactivateAlert(
          ownerUid: dummyOwnerUid,
        );

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<void>.failure(AppFailure.notFound('alert'))),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN a permission-denied FirebaseException, '
      'WHEN deactivateAlert is called, '
      'THEN should return Result.failure with AppFailure.forbidden()',
      () async {
        // Arrange.
        when(
          () => mockApi.deactivateAlert(
            ownerUid: any(named: 'ownerUid'),
            cancellationReason: any(named: 'cancellationReason'),
          ),
        ).thenThrow(_firebaseException('permission-denied'));

        // Act.
        final result = await repository.deactivateAlert(
          ownerUid: dummyOwnerUid,
        );

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<void>.failure(AppFailure.forbidden())),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN an unavailable FirebaseException, '
      'WHEN deactivateAlert is called, '
      'THEN should return Result.failure with AppFailure.network()',
      () async {
        // Arrange.
        when(
          () => mockApi.deactivateAlert(
            ownerUid: any(named: 'ownerUid'),
            cancellationReason: any(named: 'cancellationReason'),
          ),
        ).thenThrow(_firebaseException('unavailable'));

        // Act.
        final result = await repository.deactivateAlert(
          ownerUid: dummyOwnerUid,
        );

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<void>.failure(AppFailure.network())),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // getActiveAlert
  // ---------------------------------------------------------------------------

  group('AlertRepositoryImpl.getActiveAlert', () {
    test('[HAPPY PATH] - GIVEN a user with an active alert, '
        'WHEN getActiveAlert is called, '
        'THEN should return Result.success with the mapped Alert', () async {
      // Arrange.
      when(
        () => mockApi.getActiveAlert(dummyOwnerUid),
      ).thenAnswer((_) async => dummyAlertWithId);

      // Act.
      final result = await repository.getActiveAlert(dummyOwnerUid);

      // Assert.
      expect(result.isSuccess, isTrue);
      final alert = result.valueOrNull!;
      expect(alert.id, equals(dummyAlertId));
      expect(alert.ownerUid, equals(dummyOwnerUid));
      expect(alert.status, equals(AlertStatus.active));
      verify(() => mockApi.getActiveAlert(dummyOwnerUid)).called(1);
    });

    test('[HAPPY PATH] - GIVEN a user with no active alert, '
        'WHEN getActiveAlert is called, '
        'THEN should return Result.success with null', () async {
      // Arrange.
      when(
        () => mockApi.getActiveAlert(dummyOwnerUid),
      ).thenAnswer((_) async => null);

      // Act.
      final result = await repository.getActiveAlert(dummyOwnerUid);

      // Assert.
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test(
      '[ERROR PATH] - GIVEN a permission-denied FirebaseException, '
      'WHEN getActiveAlert is called, '
      'THEN should return Result.failure with AppFailure.forbidden()',
      () async {
        // Arrange.
        when(
          () => mockApi.getActiveAlert(any()),
        ).thenThrow(_firebaseException('permission-denied'));

        // Act.
        final result = await repository.getActiveAlert(dummyOwnerUid);

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<Alert?>.failure(AppFailure.forbidden())),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN an unavailable FirebaseException, '
      'WHEN getActiveAlert is called, '
      'THEN should return Result.failure with AppFailure.network()',
      () async {
        // Arrange.
        when(
          () => mockApi.getActiveAlert(any()),
        ).thenThrow(_firebaseException('unavailable'));

        // Act.
        final result = await repository.getActiveAlert(dummyOwnerUid);

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<Alert?>.failure(AppFailure.network())),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // getAlertDetails
  // ---------------------------------------------------------------------------

  group('AlertRepositoryImpl.getAlertDetails', () {
    test('[HAPPY PATH] - GIVEN an existing alert ID, '
        'WHEN getAlertDetails is called, '
        'THEN should return Result.success with the mapped Alert', () async {
      // Arrange.
      when(
        () => mockApi.getAlertDetails(dummyAlertId),
      ).thenAnswer((_) async => dummyAlertWithId);

      // Act.
      final result = await repository.getAlertDetails(dummyAlertId);

      // Assert.
      expect(result.isSuccess, isTrue);
      final alert = result.valueOrNull!;
      expect(alert.id, equals(dummyAlertId));
      expect(alert.ownerUid, equals(dummyOwnerUid));
      verify(() => mockApi.getAlertDetails(dummyAlertId)).called(1);
    });

    test(
      '[ERROR PATH] - GIVEN a non-existent alert ID, '
      'WHEN getAlertDetails is called, '
      'THEN should return Result.failure with AppFailure.notFound()',
      () async {
        // Arrange.
        when(
          () => mockApi.getAlertDetails(any()),
        ).thenAnswer((_) async => null);

        // Act.
        final result = await repository.getAlertDetails('non-existent-id');

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<Alert>.failure(AppFailure.notFound('alert'))),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN a permission-denied FirebaseException, '
      'WHEN getAlertDetails is called, '
      'THEN should return Result.failure with AppFailure.forbidden()',
      () async {
        // Arrange.
        when(
          () => mockApi.getAlertDetails(any()),
        ).thenThrow(_firebaseException('permission-denied'));

        // Act.
        final result = await repository.getAlertDetails(dummyAlertId);

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<Alert>.failure(AppFailure.forbidden())),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN an unavailable FirebaseException, '
      'WHEN getAlertDetails is called, '
      'THEN should return Result.failure with AppFailure.network()',
      () async {
        // Arrange.
        when(
          () => mockApi.getAlertDetails(any()),
        ).thenThrow(_firebaseException('unavailable'));

        // Act.
        final result = await repository.getAlertDetails(dummyAlertId);

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<Alert>.failure(AppFailure.network())),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // getContactsAlerts
  // ---------------------------------------------------------------------------

  group('AlertRepositoryImpl.getContactsAlerts', () {
    test(
      '[HAPPY PATH] - GIVEN a trusted contact with alerts from protected people, '
      'WHEN getContactsAlerts is called, '
      'THEN should return Result.success with the mapped list of Alerts',
      () async {
        // Arrange.
        when(
          () => mockApi.getContactsAlerts(dummyOwnerUid),
        ).thenAnswer((_) async => [dummyAlertWithId]);

        // Act.
        final result = await repository.getContactsAlerts(dummyOwnerUid);

        // Assert.
        expect(result.isSuccess, isTrue);
        final alerts = result.valueOrNull!;
        expect(alerts.length, equals(1));
        expect(alerts.first.id, equals(dummyAlertId));
        verify(() => mockApi.getContactsAlerts(dummyOwnerUid)).called(1);
      },
    );

    test('[HAPPY PATH] - GIVEN a trusted contact with no alerts, '
        'WHEN getContactsAlerts is called, '
        'THEN should return Result.success with an empty list', () async {
      // Arrange.
      when(() => mockApi.getContactsAlerts(any())).thenAnswer((_) async => []);

      // Act.
      final result = await repository.getContactsAlerts(dummyOwnerUid);

      // Assert.
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test(
      '[ERROR PATH] - GIVEN a permission-denied FirebaseException, '
      'WHEN getContactsAlerts is called, '
      'THEN should return Result.failure with AppFailure.forbidden()',
      () async {
        // Arrange.
        when(
          () => mockApi.getContactsAlerts(any()),
        ).thenThrow(_firebaseException('permission-denied'));

        // Act.
        final result = await repository.getContactsAlerts(dummyOwnerUid);

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<List<Alert>>.failure(AppFailure.forbidden())),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN an unavailable FirebaseException, '
      'WHEN getContactsAlerts is called, '
      'THEN should return Result.failure with AppFailure.network()',
      () async {
        // Arrange.
        when(
          () => mockApi.getContactsAlerts(any()),
        ).thenThrow(_firebaseException('unavailable'));

        // Act.
        final result = await repository.getContactsAlerts(dummyOwnerUid);

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<List<Alert>>.failure(AppFailure.network())),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // deactivateAlertByGuardianSession
  // ---------------------------------------------------------------------------

  const dummyGuardianSessionId = 'session-xyz';

  group('AlertRepositoryImpl.deactivateAlertByGuardianSession', () {
    test(
      '[HAPPY PATH] - GIVEN an active alert linked to a guardian session, '
      'WHEN deactivateAlertByGuardianSession is called, '
      'THEN should call api.deactivateAlertByGuardianSession once and return Result.success',
      () async {
        // Arrange.
        when(
          () => mockApi.deactivateAlertByGuardianSession(
            guardianSessionId: dummyGuardianSessionId,
            cancellationReason: any(named: 'cancellationReason'),
          ),
        ).thenAnswer((_) async {});

        // Act.
        final result = await repository.deactivateAlertByGuardianSession(
          guardianSessionId: dummyGuardianSessionId,
        );

        // Assert.
        expect(result.isSuccess, isTrue);
        verify(
          () => mockApi.deactivateAlertByGuardianSession(
            guardianSessionId: dummyGuardianSessionId,
            cancellationReason: any(named: 'cancellationReason'),
          ),
        ).called(1);
      },
    );

    test(
      '[ERROR PATH] - GIVEN no active alert is linked to the guardian session, '
      'WHEN deactivateAlertByGuardianSession is called, '
      'THEN should return Result.failure with AppFailure.notFound()',
      () async {
        // Arrange.
        when(
          () => mockApi.deactivateAlertByGuardianSession(
            guardianSessionId: any(named: 'guardianSessionId'),
            cancellationReason: any(named: 'cancellationReason'),
          ),
        ).thenThrow(Exception('no_active_alert'));

        // Act.
        final result = await repository.deactivateAlertByGuardianSession(
          guardianSessionId: dummyGuardianSessionId,
        );

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<void>.failure(AppFailure.notFound('alert'))),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN a permission-denied FirebaseException, '
      'WHEN deactivateAlertByGuardianSession is called, '
      'THEN should return Result.failure with AppFailure.forbidden()',
      () async {
        // Arrange.
        when(
          () => mockApi.deactivateAlertByGuardianSession(
            guardianSessionId: any(named: 'guardianSessionId'),
            cancellationReason: any(named: 'cancellationReason'),
          ),
        ).thenThrow(_firebaseException('permission-denied'));

        // Act.
        final result = await repository.deactivateAlertByGuardianSession(
          guardianSessionId: dummyGuardianSessionId,
        );

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<void>.failure(AppFailure.forbidden())),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN an unavailable FirebaseException, '
      'WHEN deactivateAlertByGuardianSession is called, '
      'THEN should return Result.failure with AppFailure.network()',
      () async {
        // Arrange.
        when(
          () => mockApi.deactivateAlertByGuardianSession(
            guardianSessionId: any(named: 'guardianSessionId'),
            cancellationReason: any(named: 'cancellationReason'),
          ),
        ).thenThrow(_firebaseException('unavailable'));

        // Act.
        final result = await repository.deactivateAlertByGuardianSession(
          guardianSessionId: dummyGuardianSessionId,
        );

        // Assert.
        expect(result.isFailure, isTrue);
        expect(
          result,
          equals(const Result<void>.failure(AppFailure.network())),
        );
      },
    );
  });
}
