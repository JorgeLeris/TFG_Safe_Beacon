import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:safe_beacon/data/repositories/contact_request_repository_impl.dart';
import 'package:safe_beacon/data/sources/firebase/contacts/contact_request_api.dart';
import 'package:safe_beacon/data/sources/firebase/contacts/dto/contact_request_dto.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/contacts/entities/contact_request.dart';

// MARK: - DUMMY DATA & MOCKS

class MockContactRequestApi extends Mock implements ContactRequestApi {}

class FakeContactRequestDto extends Fake implements ContactRequestDto {}

final _dummyDto = ContactRequestDto(
  senderUid: 'uid_alice',
  receiverUid: 'uid_bob',
  senderUsername: 'alice',
  receiverUsername: 'bob',
  createdAt: DateTime(2024),
);

final _dummyRequest = ContactRequest(
  id: 'req_1',
  senderUid: 'uid_alice',
  receiverUid: 'uid_bob',
  senderUsername: 'alice',
  receiverUsername: 'bob',
  createdAt: DateTime(2024),
);

final _dummyApiResult = (id: 'req_1', dto: _dummyDto);

FirebaseException _firebaseException(String code) =>
    FirebaseException(plugin: 'firestore', code: code);

// MARK: - TEST CASES

void main() {
  late MockContactRequestApi mockApi;
  late ContactRequestRepositoryImpl repository;

  setUp(() {
    mockApi = MockContactRequestApi();
    repository = ContactRequestRepositoryImpl(api: mockApi);
    registerFallbackValue(FakeContactRequestDto());
  });

  // ---------------------------------------------------------------------------
  // createRequest
  // ---------------------------------------------------------------------------

  group('ContactRequestRepositoryImpl.createRequest', () {
    test(
      '[HAPPY PATH] - GIVEN a valid sender and receiver, WHEN createRequest is called, THEN should return Result.success',
      () async {
        when(() => mockApi.createRequest(any())).thenAnswer((_) async {});

        final result = await repository.createRequest(
          senderUid: 'uid_alice',
          senderUsername: 'alice',
          receiverUsername: 'bob',
        );

        expect(result, isA<Success<void>>());
        verify(() => mockApi.createRequest(any())).called(1);
      },
    );

    test(
      '[ERROR PATH] - GIVEN a FirebaseException with permission-denied, WHEN createRequest is called, THEN should return AppFailure.forbidden',
      () async {
        when(
          () => mockApi.createRequest(any()),
        ).thenThrow(_firebaseException('permission-denied'));

        final result = await repository.createRequest(
          senderUid: 'uid_alice',
          senderUsername: 'alice',
          receiverUsername: 'bob',
        );

        expect(result, isA<Failure<void>>());
        expect(
          (result as Failure).failure,
          equals(const AppFailure.forbidden()),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN an Exception with username_not_found, WHEN createRequest is called, THEN should return AppFailure.notFound',
      () async {
        when(
          () => mockApi.createRequest(any()),
        ).thenThrow(Exception('username_not_found'));

        final result = await repository.createRequest(
          senderUid: 'uid_alice',
          senderUsername: 'alice',
          receiverUsername: 'unknown',
        );

        expect(result, isA<Failure<void>>());
        expect(
          (result as Failure).failure,
          equals(const AppFailure.notFound()),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN an Exception with self_request, WHEN createRequest is called, THEN should return AppFailure.business(self_request)',
      () async {
        when(
          () => mockApi.createRequest(any()),
        ).thenThrow(Exception('self_request'));

        final result = await repository.createRequest(
          senderUid: 'uid_alice',
          senderUsername: 'alice',
          receiverUsername: 'alice',
        );

        expect(result, isA<Failure<void>>());
        expect(
          (result as Failure).failure,
          equals(const AppFailure.business('self_request')),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN an Exception with request_already_exists, WHEN createRequest is called, THEN should return AppFailure.conflict(request_already_exists)',
      () async {
        when(
          () => mockApi.createRequest(any()),
        ).thenThrow(Exception('request_already_exists'));

        final result = await repository.createRequest(
          senderUid: 'uid_alice',
          senderUsername: 'alice',
          receiverUsername: 'bob',
        );

        expect(result, isA<Failure<void>>());
        expect(
          (result as Failure).failure,
          equals(const AppFailure.conflict('request_already_exists')),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN an Exception with contact_already_exists, WHEN createRequest is called, THEN should return AppFailure.conflict(contact_already_exists)',
      () async {
        when(
          () => mockApi.createRequest(any()),
        ).thenThrow(Exception('contact_already_exists'));

        final result = await repository.createRequest(
          senderUid: 'uid_alice',
          senderUsername: 'alice',
          receiverUsername: 'bob',
        );

        expect(result, isA<Failure<void>>());
        expect(
          (result as Failure).failure,
          equals(const AppFailure.conflict('contact_already_exists')),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN an unrecognised Exception, WHEN createRequest is called, THEN should return AppFailure.unknown',
      () async {
        when(
          () => mockApi.createRequest(any()),
        ).thenThrow(Exception('some_other_error'));

        final result = await repository.createRequest(
          senderUid: 'uid_alice',
          senderUsername: 'alice',
          receiverUsername: 'bob',
        );

        expect(result, isA<Failure<void>>());
        expect((result as Failure).failure, equals(const AppFailure.unknown()));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // getReceivedRequests
  // ---------------------------------------------------------------------------

  group('ContactRequestRepositoryImpl.getReceivedRequests', () {
    test(
      '[HAPPY PATH] - GIVEN valid API results, WHEN getReceivedRequests is called, THEN should return a mapped list of ContactRequest',
      () async {
        when(
          () => mockApi.getReceivedRequests(any()),
        ).thenAnswer((_) async => [_dummyApiResult]);

        final result = await repository.getReceivedRequests('uid_bob');

        expect(result, isA<Success<List<ContactRequest>>>());
        final requests = (result as Success<List<ContactRequest>>).value;
        expect(requests.length, 1);
        expect(requests.first, equals(_dummyRequest));
      },
    );

    test(
      '[ERROR PATH] - GIVEN a FirebaseException, WHEN getReceivedRequests is called, THEN should return a mapped AppFailure',
      () async {
        when(
          () => mockApi.getReceivedRequests(any()),
        ).thenThrow(_firebaseException('unavailable'));

        final result = await repository.getReceivedRequests('uid_bob');

        expect(result, isA<Failure<List<ContactRequest>>>());
        expect((result as Failure).failure, equals(const AppFailure.network()));
      },
    );

    test(
      '[ERROR PATH] - GIVEN an unexpected error, WHEN getReceivedRequests is called, THEN should return AppFailure.unknown',
      () async {
        when(
          () => mockApi.getReceivedRequests(any()),
        ).thenThrow(Exception('unexpected'));

        final result = await repository.getReceivedRequests('uid_bob');

        expect(result, isA<Failure<List<ContactRequest>>>());
        expect((result as Failure).failure, equals(const AppFailure.unknown()));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // getSentRequests
  // ---------------------------------------------------------------------------

  group('ContactRequestRepositoryImpl.getSentRequests', () {
    test(
      '[HAPPY PATH] - GIVEN valid API results, WHEN getSentRequests is called, THEN should return a mapped list of ContactRequest',
      () async {
        when(
          () => mockApi.getSentRequests(any()),
        ).thenAnswer((_) async => [_dummyApiResult]);

        final result = await repository.getSentRequests('uid_alice');

        expect(result, isA<Success<List<ContactRequest>>>());
        final requests = (result as Success<List<ContactRequest>>).value;
        expect(requests.length, 1);
        expect(requests.first, equals(_dummyRequest));
      },
    );

    test(
      '[ERROR PATH] - GIVEN a FirebaseException, WHEN getSentRequests is called, THEN should return a mapped AppFailure',
      () async {
        when(
          () => mockApi.getSentRequests(any()),
        ).thenThrow(_firebaseException('not-found'));

        final result = await repository.getSentRequests('uid_alice');

        expect(result, isA<Failure<List<ContactRequest>>>());
        expect(
          (result as Failure).failure,
          equals(const AppFailure.notFound()),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN an unexpected error, WHEN getSentRequests is called, THEN should return AppFailure.unknown',
      () async {
        when(
          () => mockApi.getSentRequests(any()),
        ).thenThrow(Exception('unexpected'));

        final result = await repository.getSentRequests('uid_alice');

        expect(result, isA<Failure<List<ContactRequest>>>());
        expect((result as Failure).failure, equals(const AppFailure.unknown()));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // getReceivedRequestsCount
  // ---------------------------------------------------------------------------

  group('ContactRequestRepositoryImpl.getReceivedRequestsCount', () {
    test(
      '[HAPPY PATH] - GIVEN a valid API response, WHEN getReceivedRequestsCount is called, THEN should return the correct count',
      () async {
        when(
          () => mockApi.getReceivedRequestsCount(any()),
        ).thenAnswer((_) async => 3);

        final result = await repository.getReceivedRequestsCount('uid_bob');

        expect(result, isA<Success<int>>());
        expect((result as Success<int>).value, 3);
      },
    );

    test(
      '[ERROR PATH] - GIVEN a FirebaseException, WHEN getReceivedRequestsCount is called, THEN should return a mapped AppFailure',
      () async {
        when(
          () => mockApi.getReceivedRequestsCount(any()),
        ).thenThrow(_firebaseException('permission-denied'));

        final result = await repository.getReceivedRequestsCount('uid_bob');

        expect(result, isA<Failure<int>>());
        expect(
          (result as Failure).failure,
          equals(const AppFailure.forbidden()),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN an unexpected error, WHEN getReceivedRequestsCount is called, THEN should return AppFailure.unknown',
      () async {
        when(
          () => mockApi.getReceivedRequestsCount(any()),
        ).thenThrow(Exception('unexpected'));

        final result = await repository.getReceivedRequestsCount('uid_bob');

        expect(result, isA<Failure<int>>());
        expect((result as Failure).failure, equals(const AppFailure.unknown()));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // deleteRequest
  // ---------------------------------------------------------------------------

  group('ContactRequestRepositoryImpl.deleteRequest', () {
    test(
      '[HAPPY PATH] - GIVEN a valid requestId, WHEN deleteRequest is called, THEN should return Result.success',
      () async {
        when(() => mockApi.deleteRequest(any())).thenAnswer((_) async {});

        final result = await repository.deleteRequest(
          requestId: 'req_1',
          requesterUid: 'uid_alice',
        );

        expect(result, isA<Success<void>>());
        verify(() => mockApi.deleteRequest('req_1')).called(1);
      },
    );

    test(
      '[ERROR PATH] - GIVEN a FirebaseException, WHEN deleteRequest is called, THEN should return a mapped AppFailure',
      () async {
        when(
          () => mockApi.deleteRequest(any()),
        ).thenThrow(_firebaseException('unavailable'));

        final result = await repository.deleteRequest(
          requestId: 'req_1',
          requesterUid: 'uid_alice',
        );

        expect(result, isA<Failure<void>>());
        expect((result as Failure).failure, equals(const AppFailure.network()));
      },
    );

    test(
      '[ERROR PATH] - GIVEN an unexpected error, WHEN deleteRequest is called, THEN should return AppFailure.unknown',
      () async {
        when(
          () => mockApi.deleteRequest(any()),
        ).thenThrow(Exception('unexpected'));

        final result = await repository.deleteRequest(
          requestId: 'req_1',
          requesterUid: 'uid_alice',
        );

        expect(result, isA<Failure<void>>());
        expect((result as Failure).failure, equals(const AppFailure.unknown()));
      },
    );
  });
}
