import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_beacon/data/repositories/guardian_session_repository_impl.dart';
import 'package:safe_beacon/data/sources/firebase/guardian_mode/dto/guardian_session_dto.dart';
import 'package:safe_beacon/data/sources/firebase/guardian_mode/guardian_session_api.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/guardian_mode/entities/guardian_coordinate.dart';
import 'package:safe_beacon/domain/guardian_mode/entities/guardian_session.dart';

// MARK: - DUMMY DATA & MOCKS

class MockGuardianSessionApi extends Mock implements GuardianSessionApi {}

class FakeGuardianSessionDto extends Fake implements GuardianSessionDto {}

const _ownerUid = 'uid-123';
const _sessionId = 'session-abc';
const _contactUid = 'contact-456';

const _dummyCoordinateDto = GuardianCoordinateDto(
  latitude: 41.6488,
  longitude: -0.8891,
);

final _dummySessionDto = GuardianSessionDto(
  ownerUid: _ownerUid,
  trustedContactUids: const [_contactUid],
  status: 'active',
  secondaryStatuses: const ['route_deviation'],
  originLocation: _dummyCoordinateDto,
  currentLocation: _dummyCoordinateDto,
  estimatedDurationSeconds: 1800,
  activatedAt: DateTime(2024),
);

final _dummySessionWithId = (id: _sessionId, dto: _dummySessionDto);

final _dummySessionDtoWithDestination = GuardianSessionDto(
  ownerUid: _ownerUid,
  trustedContactUids: const [_contactUid],
  status: 'active',
  secondaryStatuses: const [],
  originLocation: const GuardianCoordinateDto(
    latitude: 41.6488,
    longitude: -0.8891,
  ),
  currentLocation: const GuardianCoordinateDto(
    latitude: 41.65,
    longitude: -0.89,
  ),
  destination: const GuardianCoordinateDto(latitude: 41.7, longitude: -0.85),
  estimatedDurationSeconds: 600,
  activatedAt: DateTime(2024),
);

final _dummySessionWithDestination = (
  id: _sessionId,
  dto: _dummySessionDtoWithDestination,
);

FirebaseException _firebaseException(String code) =>
    FirebaseException(plugin: 'cloud_firestore', code: code);

// MARK: - TEST CASES

void main() {
  late MockGuardianSessionApi mockApi;
  late GuardianSessionRepositoryImpl repository;

  setUp(() {
    mockApi = MockGuardianSessionApi();
    repository = GuardianSessionRepositoryImpl(api: mockApi);
    registerFallbackValue(FakeGuardianSessionDto());
  });

  // ---------------------------------------------------------------------------
  // createSession
  // ---------------------------------------------------------------------------

  group('GuardianSessionRepositoryImpl.createSession', () {
    test(
      '[HAPPY PATH] - GIVEN valid parameters, '
      'WHEN createSession is called, '
      'THEN should call api.createSession once and return Result.success',
      () async {
        // Arrange.
        when(() => mockApi.createSession(any())).thenAnswer((_) async {});

        // Act.
        final result = await repository.createSession(
          ownerUid: _ownerUid,
          estimatedDuration: const Duration(minutes: 30),
          initialLocation: const GuardianCoordinate(
            latitude: 41.6488,
            longitude: -0.8891,
          ),
        );

        // Assert.
        expect(result.isSuccess, isTrue);
        verify(() => mockApi.createSession(any())).called(1);
      },
    );

    test('[HAPPY PATH] - GIVEN valid parameters with a destination, '
        'WHEN createSession is called, '
        'THEN should pass the destination coordinate to the API', () async {
      // Arrange.
      when(() => mockApi.createSession(any())).thenAnswer((_) async {});

      // Act.
      final result = await repository.createSession(
        ownerUid: _ownerUid,
        estimatedDuration: const Duration(minutes: 30),
        initialLocation: const GuardianCoordinate(
          latitude: 41.6488,
          longitude: -0.8891,
        ),
        destination: const GuardianCoordinate(latitude: 41.7, longitude: -0.85),
      );

      // Assert.
      expect(result.isSuccess, isTrue);
      verify(() => mockApi.createSession(any())).called(1);
    });

    test(
      '[ERROR PATH] - GIVEN the user already has an active session, '
      'WHEN createSession is called, '
      'THEN should return Result.failure with AppFailure.conflict()',
      () async {
        // Arrange.
        when(
          () => mockApi.createSession(any()),
        ).thenThrow(Exception('session_already_active'));

        // Act.
        final result = await repository.createSession(
          ownerUid: _ownerUid,
          estimatedDuration: const Duration(minutes: 30),
          initialLocation: const GuardianCoordinate(
            latitude: 41.6488,
            longitude: -0.8891,
          ),
        );

        // Assert.
        expect(
          result,
          equals(
            const Result<void>.failure(
              AppFailure.conflict('session_already_active'),
            ),
          ),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN the user has no trusted contacts, '
      'WHEN createSession is called, '
      'THEN should return Result.failure with AppFailure.business()',
      () async {
        // Arrange.
        when(
          () => mockApi.createSession(any()),
        ).thenThrow(Exception('no_trusted_contacts'));

        // Act.
        final result = await repository.createSession(
          ownerUid: _ownerUid,
          estimatedDuration: const Duration(minutes: 30),
          initialLocation: const GuardianCoordinate(
            latitude: 41.6488,
            longitude: -0.8891,
          ),
        );

        // Assert.
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
      '[ERROR PATH] - GIVEN a Firebase permission-denied error, '
      'WHEN createSession is called, '
      'THEN should return Result.failure with AppFailure.forbidden()',
      () async {
        // Arrange.
        when(
          () => mockApi.createSession(any()),
        ).thenThrow(_firebaseException('permission-denied'));

        // Act.
        final result = await repository.createSession(
          ownerUid: _ownerUid,
          estimatedDuration: const Duration(minutes: 30),
          initialLocation: const GuardianCoordinate(
            latitude: 41.6488,
            longitude: -0.8891,
          ),
        );

        // Assert.
        expect(
          result,
          equals(const Result<void>.failure(AppFailure.forbidden())),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN an unknown Firebase error, '
      'WHEN createSession is called, '
      'THEN should return Result.failure with AppFailure.unknown()',
      () async {
        // Arrange.
        when(
          () => mockApi.createSession(any()),
        ).thenThrow(_firebaseException('internal'));

        // Act.
        final result = await repository.createSession(
          ownerUid: _ownerUid,
          estimatedDuration: const Duration(minutes: 30),
          initialLocation: const GuardianCoordinate(
            latitude: 41.6488,
            longitude: -0.8891,
          ),
        );

        // Assert.
        expect(
          result,
          equals(const Result<void>.failure(AppFailure.unknown())),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // completeSession
  // ---------------------------------------------------------------------------

  group('GuardianSessionRepositoryImpl.completeSession', () {
    test('[HAPPY PATH] - GIVEN valid parameters, '
        'WHEN completeSession is called, '
        'THEN should return Result.success', () async {
      // Arrange.
      when(
        () => mockApi.completeSession(
          ownerUid: any(named: 'ownerUid'),
          completionStatus: any(named: 'completionStatus'),
          completionJustification: any(named: 'completionJustification'),
        ),
      ).thenAnswer((_) async {});

      // Act.
      final result = await repository.completeSession(
        ownerUid: _ownerUid,
        completionStatus:
            GuardianSessionSecondaryStatus.completedByCancellation,
      );

      // Assert.
      expect(result.isSuccess, isTrue);
    });

    test(
      '[ERROR PATH] - GIVEN no active session exists for the owner, '
      'WHEN completeSession is called, '
      'THEN should return Result.failure with AppFailure.notFound()',
      () async {
        // Arrange.
        when(
          () => mockApi.completeSession(
            ownerUid: any(named: 'ownerUid'),
            completionStatus: any(named: 'completionStatus'),
            completionJustification: any(named: 'completionJustification'),
          ),
        ).thenThrow(Exception('no_active_session'));

        // Act.
        final result = await repository.completeSession(
          ownerUid: _ownerUid,
          completionStatus:
              GuardianSessionSecondaryStatus.completedByCancellation,
        );

        // Assert.
        expect(
          result,
          equals(
            const Result<void>.failure(AppFailure.notFound('guardian_session')),
          ),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN a Firebase permission-denied error, '
      'WHEN completeSession is called, '
      'THEN should return Result.failure with AppFailure.forbidden()',
      () async {
        // Arrange.
        when(
          () => mockApi.completeSession(
            ownerUid: any(named: 'ownerUid'),
            completionStatus: any(named: 'completionStatus'),
            completionJustification: any(named: 'completionJustification'),
          ),
        ).thenThrow(_firebaseException('permission-denied'));

        // Act.
        final result = await repository.completeSession(
          ownerUid: _ownerUid,
          completionStatus:
              GuardianSessionSecondaryStatus.completedByCancellation,
        );

        // Assert.
        expect(
          result,
          equals(const Result<void>.failure(AppFailure.forbidden())),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // updateSession
  // ---------------------------------------------------------------------------

  group('GuardianSessionRepositoryImpl.updateSession', () {
    test(
      '[HAPPY PATH] - GIVEN valid parameters, '
      'WHEN updateSession is called, '
      'THEN should call api.updateSession once and return Result.success',
      () async {
        // Arrange.
        when(
          () => mockApi.updateSession(
            sessionId: any(named: 'sessionId'),
            newLocation: any(named: 'newLocation'),
            newSecondaryStatuses: any(named: 'newSecondaryStatuses'),
          ),
        ).thenAnswer((_) async {});

        // Act.
        final result = await repository.updateSession(
          sessionId: _sessionId,
          newLocation: const GuardianCoordinate(
            latitude: 41.65,
            longitude: -0.89,
          ),
        );

        // Assert.
        expect(result.isSuccess, isTrue);
        verify(
          () => mockApi.updateSession(
            sessionId: _sessionId,
            newLocation: any(named: 'newLocation'),
            newSecondaryStatuses: any(named: 'newSecondaryStatuses'),
          ),
        ).called(1);
      },
    );

    test('[HAPPY PATH] - GIVEN new secondary statuses, '
        'WHEN updateSession is called, '
        'THEN should forward the mapped status ids to the API', () async {
      // Arrange.
      when(
        () => mockApi.updateSession(
          sessionId: any(named: 'sessionId'),
          newLocation: any(named: 'newLocation'),
          newSecondaryStatuses: any(named: 'newSecondaryStatuses'),
        ),
      ).thenAnswer((_) async {});

      // Act.
      final result = await repository.updateSession(
        sessionId: _sessionId,
        newLocation: const GuardianCoordinate(
          latitude: 41.65,
          longitude: -0.89,
        ),
        newSecondaryStatuses: [
          GuardianSessionSecondaryStatus.estimatedTimeExceeded,
        ],
      );

      // Assert.
      expect(result.isSuccess, isTrue);
    });

    test(
      '[ERROR PATH] - GIVEN a Firebase error, '
      'WHEN updateSession is called, '
      'THEN should return Result.failure with AppFailure.unknown()',
      () async {
        // Arrange.
        when(
          () => mockApi.updateSession(
            sessionId: any(named: 'sessionId'),
            newLocation: any(named: 'newLocation'),
            newSecondaryStatuses: any(named: 'newSecondaryStatuses'),
          ),
        ).thenThrow(_firebaseException('unavailable'));

        // Act.
        final result = await repository.updateSession(
          sessionId: _sessionId,
          newLocation: const GuardianCoordinate(
            latitude: 41.65,
            longitude: -0.89,
          ),
        );

        // Assert.
        expect(result.isFailure, isTrue);
      },
    );
  });

  // ---------------------------------------------------------------------------
  // getContactsSessions
  // ---------------------------------------------------------------------------

  group('GuardianSessionRepositoryImpl.getContactsSessions', () {
    test('[HAPPY PATH] - GIVEN the API returns a list of session DTOs, '
        'WHEN getContactsSessions is called, '
        'THEN should map DTOs to GuardianSession entities correctly', () async {
      // Arrange.
      when(
        () => mockApi.getContactsSessions(_contactUid),
      ).thenAnswer((_) async => [_dummySessionWithId]);

      // Act.
      final result = await repository.getContactsSessions(_contactUid);

      // Assert.
      expect(result.isSuccess, isTrue);
      final sessions = result.valueOrNull!;
      expect(sessions.length, 1);

      final session = sessions.first;
      expect(session.id, _sessionId);
      expect(session.ownerUid, _ownerUid);
      expect(session.status, GuardianSessionStatus.active);
      expect(session.secondaryStatuses, [
        GuardianSessionSecondaryStatus.routeDeviation,
      ]);
      expect(session.originLocation.latitude, 41.6488);
      expect(session.estimatedDuration, const Duration(seconds: 1800));
    });

    test('[HAPPY PATH] - GIVEN a session DTO with a destination, '
        'WHEN getContactsSessions is called, '
        'THEN should map the destination coordinate correctly', () async {
      // Arrange.
      when(
        () => mockApi.getContactsSessions(_contactUid),
      ).thenAnswer((_) async => [_dummySessionWithDestination]);

      // Act.
      final result = await repository.getContactsSessions(_contactUid);

      // Assert.
      expect(result.isSuccess, isTrue);
      final session = result.valueOrNull!.first;
      expect(session.destination, isNotNull);
      expect(session.destination!.latitude, 41.7);
      expect(session.destination!.longitude, -0.85);
    });

    test('[HAPPY PATH] - GIVEN the API returns an empty list, '
        'WHEN getContactsSessions is called, '
        'THEN should return an empty list', () async {
      // Arrange.
      when(
        () => mockApi.getContactsSessions(_contactUid),
      ).thenAnswer((_) async => []);

      // Act.
      final result = await repository.getContactsSessions(_contactUid);

      // Assert.
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test(
      '[ERROR PATH] - GIVEN a Firebase unavailable error, '
      'WHEN getContactsSessions is called, '
      'THEN should return Result.failure with AppFailure.network()',
      () async {
        // Arrange.
        when(
          () => mockApi.getContactsSessions(_contactUid),
        ).thenThrow(_firebaseException('unavailable'));

        // Act.
        final result = await repository.getContactsSessions(_contactUid);

        // Assert.
        expect(
          result,
          equals(
            const Result<List<GuardianSession>>.failure(AppFailure.network()),
          ),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // getSessionDetails
  // ---------------------------------------------------------------------------

  group('GuardianSessionRepositoryImpl.getSessionDetails', () {
    test('[HAPPY PATH] - GIVEN the session exists, '
        'WHEN getSessionDetails is called, '
        'THEN should return the mapped GuardianSession entity', () async {
      // Arrange.
      when(
        () => mockApi.getSessionDetails(_sessionId),
      ).thenAnswer((_) async => _dummySessionWithId);

      // Act.
      final result = await repository.getSessionDetails(_sessionId);

      // Assert.
      expect(result.isSuccess, isTrue);
      final session = result.valueOrNull!;
      expect(session.id, _sessionId);
      expect(session.ownerUid, _ownerUid);
      expect(session.trustedContactUids, [_contactUid]);
    });

    test(
      '[EDGE CASE] - GIVEN the session does not exist, '
      'WHEN getSessionDetails is called, '
      'THEN should return Result.failure with AppFailure.notFound()',
      () async {
        // Arrange.
        when(
          () => mockApi.getSessionDetails(_sessionId),
        ).thenAnswer((_) async => null);

        // Act.
        final result = await repository.getSessionDetails(_sessionId);

        // Assert.
        expect(
          result,
          equals(
            const Result<GuardianSession>.failure(
              AppFailure.notFound('guardian_session'),
            ),
          ),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // getActiveSession
  // ---------------------------------------------------------------------------

  group('GuardianSessionRepositoryImpl.getActiveSession', () {
    test('[HAPPY PATH] - GIVEN the owner has an active session, '
        'WHEN getActiveSession is called, '
        'THEN should return the mapped GuardianSession entity', () async {
      // Arrange.
      when(
        () => mockApi.getActiveSession(_ownerUid),
      ).thenAnswer((_) async => _dummySessionWithId);

      // Act.
      final result = await repository.getActiveSession(_ownerUid);

      // Assert.
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNotNull);
      expect(result.valueOrNull!.id, _sessionId);
      expect(result.valueOrNull!.status, GuardianSessionStatus.active);
    });

    test('[EDGE CASE] - GIVEN the owner has no active session, '
        'WHEN getActiveSession is called, '
        'THEN should return Result.success with null', () async {
      // Arrange.
      when(
        () => mockApi.getActiveSession(_ownerUid),
      ).thenAnswer((_) async => null);

      // Act.
      final result = await repository.getActiveSession(_ownerUid);

      // Assert.
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test(
      '[ERROR PATH] - GIVEN a Firebase permission-denied error, '
      'WHEN getActiveSession is called, '
      'THEN should return Result.failure with AppFailure.forbidden()',
      () async {
        // Arrange.
        when(
          () => mockApi.getActiveSession(_ownerUid),
        ).thenThrow(_firebaseException('permission-denied'));

        // Act.
        final result = await repository.getActiveSession(_ownerUid);

        // Assert.
        expect(
          result,
          equals(
            const Result<GuardianSession?>.failure(AppFailure.forbidden()),
          ),
        );
      },
    );
  });
}
