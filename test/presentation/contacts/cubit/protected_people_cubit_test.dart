import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/contacts/contact_repository.dart';
import 'package:safe_beacon/domain/contacts/contact_request_repository.dart';
import 'package:safe_beacon/domain/contacts/entities/contact.dart';
import 'package:safe_beacon/domain/contacts/entities/contact_request.dart';
import 'package:safe_beacon/domain/contacts/entities/contact_request_item.dart';
import 'package:safe_beacon/domain/profile/entities/user_profile.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';
import 'package:safe_beacon/presentation/features/contacts/cubits/protected_people_cubit.dart';

// MARK: - DUMMY DATA

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockContactRequestRepository extends Mock
    implements ContactRequestRepository {}

class MockContactRepository extends Mock implements ContactRepository {}

const _uid = 'uid_alice';
const _dummyFailure = AppFailure.unknown();

const _dummyProfile = UserProfile(
  uid: 'uid_bob',
  username: 'bob',
  name: 'Bob',
  surname: 'Smith',
  profilePhoto: 'https://photo.url',
);

const _dummyCurrentProfile = UserProfile(
  uid: _uid,
  username: 'alice',
  name: 'Alice',
  surname: 'Wonder',
);

final _dummyContact = Contact(
  id: 'contact_1',
  protectedPersonUid: 'uid_bob',
  trustedContactUid: _uid,
  protectedPersonUsername: 'bob',
  trustedContactUsername: 'alice',
  createdAt: DateTime(2024),
);

final _dummyContactRequest = ContactRequest(
  id: 'req_1',
  senderUid: 'uid_bob',
  receiverUid: _uid,
  senderUsername: 'bob',
  receiverUsername: 'alice',
  createdAt: DateTime(2024),
);

const _dummyContactRequestItem = ContactRequestItem(
  requestId: 'req_1',
  direction: ContactRequestDirection.received,
  peerUid: 'uid_bob',
  peerUsername: 'Bob Smith',
  peerPhoto: 'https://photo.url',
);

const _dummyProtectedPeopleItem = ContactRequestItem(
  requestId: 'contact_1',
  direction: ContactRequestDirection.received,
  peerUid: 'uid_bob',
  peerUsername: 'Bob Smith',
  peerPhoto: 'https://photo.url',
);

// MARK: - TEST CASES

void main() {
  late MockUserProfileRepository mockUserProfileRepository;
  late MockContactRequestRepository mockContactRequestRepository;
  late MockContactRepository mockContactRepository;

  ProtectedPeopleCubit buildCubit() => ProtectedPeopleCubit(
    uid: _uid,
    userProfileRepository: mockUserProfileRepository,
    contactRequestRepository: mockContactRequestRepository,
    contactRepository: mockContactRepository,
  );

  setUp(() {
    mockUserProfileRepository = MockUserProfileRepository();
    mockContactRequestRepository = MockContactRequestRepository();
    mockContactRepository = MockContactRepository();
  });

  // ---------------------------------------------------------------------------
  // loadUserCode
  // ---------------------------------------------------------------------------

  group('ProtectedPeopleCubit.loadUserCode', () {
    blocTest<ProtectedPeopleCubit, ProtectedPeopleState>(
      '[HAPPY PATH] - GIVEN a valid profile, WHEN loadUserCode is called, THEN should emit [isLoading: true, isLoading: false + username]',
      build: () {
        when(
          () => mockUserProfileRepository.getProfile(_uid),
        ).thenAnswer((_) async => const Result.success(_dummyCurrentProfile));
        return buildCubit();
      },
      act: (cubit) => cubit.loadUserCode(),
      expect: () => [
        const ProtectedPeopleState(isLoading: true),
        const ProtectedPeopleState(username: 'alice'),
      ],
      verify: (_) {
        verify(() => mockUserProfileRepository.getProfile(_uid)).called(1);
      },
    );

    blocTest<ProtectedPeopleCubit, ProtectedPeopleState>(
      '[ERROR PATH] - GIVEN a repository failure, WHEN loadUserCode is called, THEN should emit [isLoading: true, isLoading: false + failure]',
      build: () {
        when(
          () => mockUserProfileRepository.getProfile(_uid),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return buildCubit();
      },
      act: (cubit) => cubit.loadUserCode(),
      expect: () => [
        const ProtectedPeopleState(isLoading: true),
        const ProtectedPeopleState(failure: _dummyFailure),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // loadProtectedPeople
  // ---------------------------------------------------------------------------

  group('ProtectedPeopleCubit.loadProtectedPeople', () {
    blocTest<ProtectedPeopleCubit, ProtectedPeopleState>(
      '[HAPPY PATH] - GIVEN contacts and resolvable profiles, WHEN loadProtectedPeople is called, THEN should emit [loading, items with resolved name and photo]',
      build: () {
        when(
          () => mockContactRepository.getProtectedPeople(_uid),
        ).thenAnswer((_) async => Result.success([_dummyContact]));
        when(
          () => mockUserProfileRepository.getProfile(
            _dummyContact.protectedPersonUid,
          ),
        ).thenAnswer((_) async => const Result.success(_dummyProfile));
        return buildCubit();
      },
      act: (cubit) => cubit.loadProtectedPeople(),
      expect: () => [
        const ProtectedPeopleState(isLoadingProtectedPeople: true),
        const ProtectedPeopleState(
          protectedPeople: [_dummyProtectedPeopleItem],
        ),
      ],
    );

    blocTest<ProtectedPeopleCubit, ProtectedPeopleState>(
      '[EDGE CASE] - GIVEN contacts but profile fetch fails, WHEN loadProtectedPeople is called, THEN should emit items falling back to username from contact',
      build: () {
        when(
          () => mockContactRepository.getProtectedPeople(_uid),
        ).thenAnswer((_) async => Result.success([_dummyContact]));
        when(
          () => mockUserProfileRepository.getProfile(
            _dummyContact.protectedPersonUid,
          ),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return buildCubit();
      },
      act: (cubit) => cubit.loadProtectedPeople(),
      expect: () => [
        const ProtectedPeopleState(isLoadingProtectedPeople: true),
        ProtectedPeopleState(
          protectedPeople: [
            ContactRequestItem(
              requestId: 'contact_1',
              direction: ContactRequestDirection.received,
              peerUid: 'uid_bob',
              peerUsername: _dummyContact.protectedPersonUsername,
            ),
          ],
        ),
      ],
    );

    blocTest<ProtectedPeopleCubit, ProtectedPeopleState>(
      '[ERROR PATH] - GIVEN a repository failure, WHEN loadProtectedPeople is called, THEN should emit [loading, failure]',
      build: () {
        when(
          () => mockContactRepository.getProtectedPeople(_uid),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return buildCubit();
      },
      act: (cubit) => cubit.loadProtectedPeople(),
      expect: () => [
        const ProtectedPeopleState(isLoadingProtectedPeople: true),
        const ProtectedPeopleState(protectedPeopleFailure: _dummyFailure),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // deleteContact
  // ---------------------------------------------------------------------------

  group('ProtectedPeopleCubit.deleteContact', () {
    blocTest<ProtectedPeopleCubit, ProtectedPeopleState>(
      '[HAPPY PATH] - GIVEN the contact exists in local list, WHEN deleteContact is called, THEN should emit [deleting, item removed from list]',
      build: () {
        when(
          () => mockContactRepository.deleteContact(
            contactId: 'contact_1',
            requesterUid: _uid,
          ),
        ).thenAnswer((_) async => const Result.success(null));
        return buildCubit();
      },
      seed: () => const ProtectedPeopleState(
        protectedPeople: [_dummyProtectedPeopleItem],
      ),
      act: (cubit) => cubit.deleteContact('contact_1'),
      expect: () => [
        const ProtectedPeopleState(
          isDeletingContact: true,
          protectedPeople: [_dummyProtectedPeopleItem],
        ),
        const ProtectedPeopleState(),
      ],
    );

    blocTest<ProtectedPeopleCubit, ProtectedPeopleState>(
      '[ERROR PATH] - GIVEN a repository failure, WHEN deleteContact is called, THEN should emit [deleting, failure]',
      build: () {
        when(
          () => mockContactRepository.deleteContact(
            contactId: 'contact_1',
            requesterUid: _uid,
          ),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return buildCubit();
      },
      act: (cubit) => cubit.deleteContact('contact_1'),
      expect: () => [
        const ProtectedPeopleState(isDeletingContact: true),
        const ProtectedPeopleState(deleteContactFailure: _dummyFailure),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // loadReceivedRequests
  // ---------------------------------------------------------------------------

  group('ProtectedPeopleCubit.loadReceivedRequests', () {
    blocTest<ProtectedPeopleCubit, ProtectedPeopleState>(
      '[HAPPY PATH] - GIVEN requests and resolvable profiles, WHEN loadReceivedRequests is called, THEN should emit [loading, items with resolved name and photo]',
      build: () {
        when(
          () => mockContactRequestRepository.getReceivedRequests(_uid),
        ).thenAnswer((_) async => Result.success([_dummyContactRequest]));
        when(
          () => mockUserProfileRepository.getProfile(
            _dummyContactRequest.senderUid,
          ),
        ).thenAnswer((_) async => const Result.success(_dummyProfile));
        return buildCubit();
      },
      act: (cubit) => cubit.loadReceivedRequests(),
      expect: () => [
        const ProtectedPeopleState(isLoadingReceivedRequests: true),
        const ProtectedPeopleState(
          receivedRequests: [_dummyContactRequestItem],
        ),
      ],
    );

    blocTest<ProtectedPeopleCubit, ProtectedPeopleState>(
      '[EDGE CASE] - GIVEN requests but profile fetch fails, WHEN loadReceivedRequests is called, THEN should emit items falling back to username from request',
      build: () {
        when(
          () => mockContactRequestRepository.getReceivedRequests(_uid),
        ).thenAnswer((_) async => Result.success([_dummyContactRequest]));
        when(
          () => mockUserProfileRepository.getProfile(
            _dummyContactRequest.senderUid,
          ),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return buildCubit();
      },
      act: (cubit) => cubit.loadReceivedRequests(),
      expect: () => [
        const ProtectedPeopleState(isLoadingReceivedRequests: true),
        ProtectedPeopleState(
          receivedRequests: [
            ContactRequestItem(
              requestId: 'req_1',
              direction: ContactRequestDirection.received,
              peerUid: 'uid_bob',
              peerUsername: _dummyContactRequest.senderUsername,
            ),
          ],
        ),
      ],
    );

    blocTest<ProtectedPeopleCubit, ProtectedPeopleState>(
      '[ERROR PATH] - GIVEN a repository failure, WHEN loadReceivedRequests is called, THEN should emit [loading, failure]',
      build: () {
        when(
          () => mockContactRequestRepository.getReceivedRequests(_uid),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return buildCubit();
      },
      act: (cubit) => cubit.loadReceivedRequests(),
      expect: () => [
        const ProtectedPeopleState(isLoadingReceivedRequests: true),
        const ProtectedPeopleState(receivedRequestsFailure: _dummyFailure),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // acceptRequest
  // ---------------------------------------------------------------------------

  group('ProtectedPeopleCubit.acceptRequest', () {
    blocTest<ProtectedPeopleCubit, ProtectedPeopleState>(
      '[HAPPY PATH] - GIVEN username loaded, createContact and deleteRequest succeed, WHEN acceptRequest is called, THEN should remove request from list and reload protected people',
      build: () {
        when(
          () => mockContactRepository.createContact(
            protectedPersonUid: any(named: 'protectedPersonUid'),
            protectedPersonUsername: any(named: 'protectedPersonUsername'),
            trustedContactUid: any(named: 'trustedContactUid'),
            trustedContactUsername: any(named: 'trustedContactUsername'),
          ),
        ).thenAnswer((_) async => const Result.success(null));
        when(
          () => mockContactRequestRepository.deleteRequest(
            requestId: any(named: 'requestId'),
            requesterUid: any(named: 'requesterUid'),
          ),
        ).thenAnswer((_) async => const Result.success(null));
        // loadProtectedPeople call triggered at the end of acceptRequest
        when(
          () => mockContactRepository.getProtectedPeople(_uid),
        ).thenAnswer((_) async => const Result.success([]));
        return buildCubit();
      },
      seed: () => const ProtectedPeopleState(
        username: 'alice',
        receivedRequests: [_dummyContactRequestItem],
      ),
      act: (cubit) => cubit.acceptRequest(_dummyContactRequestItem),
      expect: () => [
        const ProtectedPeopleState(
          isAcceptingRequest: true,
          username: 'alice',
          receivedRequests: [_dummyContactRequestItem],
        ),
        const ProtectedPeopleState(username: 'alice'),
        // loadProtectedPeople emissions
        const ProtectedPeopleState(
          isLoadingProtectedPeople: true,
          username: 'alice',
        ),
        const ProtectedPeopleState(username: 'alice'),
      ],
    );

    blocTest<ProtectedPeopleCubit, ProtectedPeopleState>(
      '[EDGE CASE] - GIVEN username is null, WHEN acceptRequest is called, THEN should emit failure without calling repositories',
      build: () => buildCubit(),
      act: (cubit) => cubit.acceptRequest(_dummyContactRequestItem),
      expect: () => [
        const ProtectedPeopleState(isAcceptingRequest: true),
        const ProtectedPeopleState(acceptRequestFailure: _dummyFailure),
      ],
      verify: (_) {
        verifyNever(
          () => mockContactRepository.createContact(
            protectedPersonUid: any(named: 'protectedPersonUid'),
            protectedPersonUsername: any(named: 'protectedPersonUsername'),
            trustedContactUid: any(named: 'trustedContactUid'),
            trustedContactUsername: any(named: 'trustedContactUsername'),
          ),
        );
      },
    );

    blocTest<ProtectedPeopleCubit, ProtectedPeopleState>(
      '[ERROR PATH] - GIVEN createContact fails, WHEN acceptRequest is called, THEN should emit failure and not call deleteRequest',
      build: () {
        when(
          () => mockContactRepository.createContact(
            protectedPersonUid: any(named: 'protectedPersonUid'),
            protectedPersonUsername: any(named: 'protectedPersonUsername'),
            trustedContactUid: any(named: 'trustedContactUid'),
            trustedContactUsername: any(named: 'trustedContactUsername'),
          ),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return buildCubit();
      },
      seed: () => const ProtectedPeopleState(username: 'alice'),
      act: (cubit) => cubit.acceptRequest(_dummyContactRequestItem),
      expect: () => [
        const ProtectedPeopleState(isAcceptingRequest: true, username: 'alice'),
        const ProtectedPeopleState(
          username: 'alice',
          acceptRequestFailure: _dummyFailure,
        ),
      ],
      verify: (_) {
        verifyNever(
          () => mockContactRequestRepository.deleteRequest(
            requestId: any(named: 'requestId'),
            requesterUid: any(named: 'requesterUid'),
          ),
        );
      },
    );

    blocTest<ProtectedPeopleCubit, ProtectedPeopleState>(
      '[ERROR PATH] - GIVEN createContact succeeds but deleteRequest fails, WHEN acceptRequest is called, THEN should emit failure',
      build: () {
        when(
          () => mockContactRepository.createContact(
            protectedPersonUid: any(named: 'protectedPersonUid'),
            protectedPersonUsername: any(named: 'protectedPersonUsername'),
            trustedContactUid: any(named: 'trustedContactUid'),
            trustedContactUsername: any(named: 'trustedContactUsername'),
          ),
        ).thenAnswer((_) async => const Result.success(null));
        when(
          () => mockContactRequestRepository.deleteRequest(
            requestId: any(named: 'requestId'),
            requesterUid: any(named: 'requesterUid'),
          ),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return buildCubit();
      },
      seed: () => const ProtectedPeopleState(username: 'alice'),
      act: (cubit) => cubit.acceptRequest(_dummyContactRequestItem),
      expect: () => [
        const ProtectedPeopleState(isAcceptingRequest: true, username: 'alice'),
        const ProtectedPeopleState(
          username: 'alice',
          acceptRequestFailure: _dummyFailure,
        ),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // deleteReceivedRequest
  // ---------------------------------------------------------------------------

  group('ProtectedPeopleCubit.deleteReceivedRequest', () {
    blocTest<ProtectedPeopleCubit, ProtectedPeopleState>(
      '[HAPPY PATH] - GIVEN the request exists in local list, WHEN deleteReceivedRequest is called, THEN should emit [deleting, item removed from list]',
      build: () {
        when(
          () => mockContactRequestRepository.deleteRequest(
            requestId: 'req_1',
            requesterUid: _uid,
          ),
        ).thenAnswer((_) async => const Result.success(null));
        return buildCubit();
      },
      seed: () => const ProtectedPeopleState(
        receivedRequests: [_dummyContactRequestItem],
      ),
      act: (cubit) => cubit.deleteReceivedRequest('req_1'),
      expect: () => [
        const ProtectedPeopleState(
          isDeletingRequest: true,
          receivedRequests: [_dummyContactRequestItem],
        ),
        const ProtectedPeopleState(),
      ],
    );

    blocTest<ProtectedPeopleCubit, ProtectedPeopleState>(
      '[ERROR PATH] - GIVEN a repository failure, WHEN deleteReceivedRequest is called, THEN should emit [deleting, failure]',
      build: () {
        when(
          () => mockContactRequestRepository.deleteRequest(
            requestId: 'req_1',
            requesterUid: _uid,
          ),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return buildCubit();
      },
      act: (cubit) => cubit.deleteReceivedRequest('req_1'),
      expect: () => [
        const ProtectedPeopleState(isDeletingRequest: true),
        const ProtectedPeopleState(deleteRequestFailure: _dummyFailure),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // clear actions
  // ---------------------------------------------------------------------------

  group('ProtectedPeopleCubit.clearActions', () {
    blocTest<ProtectedPeopleCubit, ProtectedPeopleState>(
      '[RESET ACTION] - GIVEN a deleteRequestFailure in state, WHEN clearDeleteRequestFailure is called, THEN should emit state with failure cleared',
      build: () => buildCubit(),
      seed: () =>
          const ProtectedPeopleState(deleteRequestFailure: _dummyFailure),
      act: (cubit) => cubit.clearDeleteRequestFailure(),
      expect: () => [const ProtectedPeopleState()],
    );

    blocTest<ProtectedPeopleCubit, ProtectedPeopleState>(
      '[RESET ACTION] - GIVEN an acceptRequestFailure in state, WHEN clearAcceptRequestFailure is called, THEN should emit state with failure cleared',
      build: () => buildCubit(),
      seed: () =>
          const ProtectedPeopleState(acceptRequestFailure: _dummyFailure),
      act: (cubit) => cubit.clearAcceptRequestFailure(),
      expect: () => [const ProtectedPeopleState()],
    );

    blocTest<ProtectedPeopleCubit, ProtectedPeopleState>(
      '[RESET ACTION] - GIVEN a deleteContactFailure in state, WHEN clearDeleteContactFailure is called, THEN should emit state with failure cleared',
      build: () => buildCubit(),
      seed: () =>
          const ProtectedPeopleState(deleteContactFailure: _dummyFailure),
      act: (cubit) => cubit.clearDeleteContactFailure(),
      expect: () => [const ProtectedPeopleState()],
    );
  });
}
