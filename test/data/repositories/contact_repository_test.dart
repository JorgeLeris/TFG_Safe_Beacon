import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:safe_beacon/data/repositories/contact_repository_impl.dart';
import 'package:safe_beacon/data/sources/firebase/alerts/alert_api.dart';
import 'package:safe_beacon/data/sources/firebase/contacts/contact_api.dart';
import 'package:safe_beacon/data/sources/firebase/contacts/dto/contact_dto.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/contacts/entities/contact.dart';

// MARK: - DUMMY DATA & MOCKS

class MockContactApi extends Mock implements ContactApi {}

class MockAlertApi extends Mock implements AlertApi {}

class FakeContactDto extends Fake implements ContactDto {}

final _dummyDto = ContactDto(
  protectedPersonUid: 'uid_alice',
  trustedContactUid: 'uid_bob',
  protectedPersonUsername: 'alice',
  trustedContactUsername: 'bob',
  createdAt: DateTime(2024),
);

final _dummyContact = Contact(
  id: 'contact_1',
  protectedPersonUid: 'uid_alice',
  trustedContactUid: 'uid_bob',
  protectedPersonUsername: 'alice',
  trustedContactUsername: 'bob',
  createdAt: DateTime(2024),
);

final _dummyApiResult = (id: 'contact_1', dto: _dummyDto);

FirebaseException _firebaseException(String code) =>
    FirebaseException(plugin: 'firestore', code: code);

// MARK: - TEST CASES

void main() {
  late MockContactApi mockApi;
  late MockAlertApi mockAlertApi;
  late ContactRepositoryImpl repository;

  setUp(() {
    mockApi = MockContactApi();
    mockAlertApi = MockAlertApi();
    repository = ContactRepositoryImpl(api: mockApi, alertApi: mockAlertApi);
    registerFallbackValue(FakeContactDto());
  });

  // ---------------------------------------------------------------------------
  // createContact
  // ---------------------------------------------------------------------------

  group('ContactRepositoryImpl.createContact', () {
    test(
      '[HAPPY PATH] - GIVEN valid uids and usernames, WHEN createContact is called, THEN should return Result.success',
      () async {
        when(() => mockApi.createContact(any())).thenAnswer((_) async {});

        final result = await repository.createContact(
          protectedPersonUid: 'uid_alice',
          protectedPersonUsername: 'alice',
          trustedContactUid: 'uid_bob',
          trustedContactUsername: 'bob',
        );

        expect(result, isA<Success<void>>());
        verify(() => mockApi.createContact(any())).called(1);
      },
    );

    test(
      '[ERROR PATH] - GIVEN a FirebaseException with permission-denied, WHEN createContact is called, THEN should return AppFailure.forbidden',
      () async {
        when(
          () => mockApi.createContact(any()),
        ).thenThrow(_firebaseException('permission-denied'));

        final result = await repository.createContact(
          protectedPersonUid: 'uid_alice',
          protectedPersonUsername: 'alice',
          trustedContactUid: 'uid_bob',
          trustedContactUsername: 'bob',
        );

        expect(result, isA<Failure<void>>());
        expect(
          (result as Failure).failure,
          equals(const AppFailure.forbidden()),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN an Exception with contact_already_exists, WHEN createContact is called, THEN should return AppFailure.conflict(contact_already_exists)',
      () async {
        when(
          () => mockApi.createContact(any()),
        ).thenThrow(Exception('contact_already_exists'));

        final result = await repository.createContact(
          protectedPersonUid: 'uid_alice',
          protectedPersonUsername: 'alice',
          trustedContactUid: 'uid_bob',
          trustedContactUsername: 'bob',
        );

        expect(result, isA<Failure<void>>());
        expect(
          (result as Failure).failure,
          equals(const AppFailure.conflict('contact_already_exists')),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN an unrecognised Exception, WHEN createContact is called, THEN should return AppFailure.unknown',
      () async {
        when(
          () => mockApi.createContact(any()),
        ).thenThrow(Exception('some_other_error'));

        final result = await repository.createContact(
          protectedPersonUid: 'uid_alice',
          protectedPersonUsername: 'alice',
          trustedContactUid: 'uid_bob',
          trustedContactUsername: 'bob',
        );

        expect(result, isA<Failure<void>>());
        expect((result as Failure).failure, equals(const AppFailure.unknown()));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // getTrustedContacts
  // ---------------------------------------------------------------------------

  group('ContactRepositoryImpl.getTrustedContacts', () {
    test(
      '[HAPPY PATH] - GIVEN valid API results, WHEN getTrustedContacts is called, THEN should return a mapped list of Contact',
      () async {
        when(
          () => mockApi.getTrustedContacts(any()),
        ).thenAnswer((_) async => [_dummyApiResult]);

        final result = await repository.getTrustedContacts('uid_alice');

        expect(result, isA<Success<List<Contact>>>());
        final contacts = (result as Success<List<Contact>>).value;
        expect(contacts.length, 1);
        expect(contacts.first, equals(_dummyContact));
      },
    );

    test(
      '[ERROR PATH] - GIVEN a FirebaseException with unavailable, WHEN getTrustedContacts is called, THEN should return AppFailure.network',
      () async {
        when(
          () => mockApi.getTrustedContacts(any()),
        ).thenThrow(_firebaseException('unavailable'));

        final result = await repository.getTrustedContacts('uid_alice');

        expect(result, isA<Failure<List<Contact>>>());
        expect((result as Failure).failure, equals(const AppFailure.network()));
      },
    );

    test(
      '[ERROR PATH] - GIVEN an unexpected error, WHEN getTrustedContacts is called, THEN should return AppFailure.unknown',
      () async {
        when(
          () => mockApi.getTrustedContacts(any()),
        ).thenThrow(Exception('unexpected'));

        final result = await repository.getTrustedContacts('uid_alice');

        expect(result, isA<Failure<List<Contact>>>());
        expect((result as Failure).failure, equals(const AppFailure.unknown()));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // getProtectedPeople
  // ---------------------------------------------------------------------------

  group('ContactRepositoryImpl.getProtectedPeople', () {
    test(
      '[HAPPY PATH] - GIVEN valid API results, WHEN getProtectedPeople is called, THEN should return a mapped list of Contact',
      () async {
        when(
          () => mockApi.getProtectedPeople(any()),
        ).thenAnswer((_) async => [_dummyApiResult]);

        final result = await repository.getProtectedPeople('uid_bob');

        expect(result, isA<Success<List<Contact>>>());
        final contacts = (result as Success<List<Contact>>).value;
        expect(contacts.length, 1);
        expect(contacts.first, equals(_dummyContact));
      },
    );

    test(
      '[ERROR PATH] - GIVEN a FirebaseException with not-found, WHEN getProtectedPeople is called, THEN should return AppFailure.notFound',
      () async {
        when(
          () => mockApi.getProtectedPeople(any()),
        ).thenThrow(_firebaseException('not-found'));

        final result = await repository.getProtectedPeople('uid_bob');

        expect(result, isA<Failure<List<Contact>>>());
        expect(
          (result as Failure).failure,
          equals(const AppFailure.notFound()),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN an unexpected error, WHEN getProtectedPeople is called, THEN should return AppFailure.unknown',
      () async {
        when(
          () => mockApi.getProtectedPeople(any()),
        ).thenThrow(Exception('unexpected'));

        final result = await repository.getProtectedPeople('uid_bob');

        expect(result, isA<Failure<List<Contact>>>());
        expect((result as Failure).failure, equals(const AppFailure.unknown()));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // deleteContact
  // ---------------------------------------------------------------------------

  group('ContactRepositoryImpl.deleteContact', () {
    test(
      '[HAPPY PATH] - GIVEN a valid contactId, WHEN deleteContact is called, THEN should return Result.success and cascade alert cleanup',
      () async {
        when(
          () => mockApi.getContactById(any()),
        ).thenAnswer((_) async => _dummyApiResult);
        when(() => mockApi.deleteContact(any())).thenAnswer((_) async {});
        when(
          () => mockAlertApi.removeContactFromAlerts(
            ownerUid: any(named: 'ownerUid'),
            trustedContactUid: any(named: 'trustedContactUid'),
          ),
        ).thenAnswer((_) async {});

        final result = await repository.deleteContact(
          contactId: 'contact_1',
          requesterUid: 'uid_alice',
        );

        expect(result, isA<Success<void>>());
        verify(() => mockApi.getContactById('contact_1')).called(1);
        verify(() => mockApi.deleteContact('contact_1')).called(1);
        verify(
          () => mockAlertApi.removeContactFromAlerts(
            ownerUid: 'uid_alice',
            trustedContactUid: 'uid_bob',
          ),
        ).called(1);
      },
    );

    test(
      '[ERROR PATH] - GIVEN getContactById returns null, WHEN deleteContact is called, THEN should return AppFailure.notFound',
      () async {
        when(() => mockApi.getContactById(any())).thenAnswer((_) async => null);

        final result = await repository.deleteContact(
          contactId: 'contact_1',
          requesterUid: 'uid_alice',
        );

        expect(result, isA<Failure<void>>());
        expect(
          (result as Failure).failure,
          equals(const AppFailure.notFound('contact')),
        );
        verifyNever(() => mockApi.deleteContact(any()));
      },
    );

    test(
      '[ERROR PATH] - GIVEN a FirebaseException with permission-denied on getContactById, WHEN deleteContact is called, THEN should return AppFailure.forbidden',
      () async {
        when(
          () => mockApi.getContactById(any()),
        ).thenThrow(_firebaseException('permission-denied'));

        final result = await repository.deleteContact(
          contactId: 'contact_1',
          requesterUid: 'uid_alice',
        );

        expect(result, isA<Failure<void>>());
        expect(
          (result as Failure).failure,
          equals(const AppFailure.forbidden()),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN a FirebaseException with permission-denied on deleteContact, WHEN deleteContact is called, THEN should return AppFailure.forbidden',
      () async {
        when(
          () => mockApi.getContactById(any()),
        ).thenAnswer((_) async => _dummyApiResult);
        when(
          () => mockApi.deleteContact(any()),
        ).thenThrow(_firebaseException('permission-denied'));

        final result = await repository.deleteContact(
          contactId: 'contact_1',
          requesterUid: 'uid_alice',
        );

        expect(result, isA<Failure<void>>());
        expect(
          (result as Failure).failure,
          equals(const AppFailure.forbidden()),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN an unexpected error, WHEN deleteContact is called, THEN should return AppFailure.unknown',
      () async {
        when(
          () => mockApi.getContactById(any()),
        ).thenAnswer((_) async => _dummyApiResult);
        when(
          () => mockApi.deleteContact(any()),
        ).thenThrow(Exception('unexpected'));

        final result = await repository.deleteContact(
          contactId: 'contact_1',
          requesterUid: 'uid_alice',
        );

        expect(result, isA<Failure<void>>());
        expect((result as Failure).failure, equals(const AppFailure.unknown()));
      },
    );
  });
}
