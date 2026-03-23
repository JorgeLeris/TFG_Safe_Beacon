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
import 'package:safe_beacon/presentation/features/contacts/cubits/trusted_contacts_cubit.dart';

// MARK: - DUMMY DATA

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

class MockContactRequestRepository extends Mock
    implements ContactRequestRepository {}

class MockContactRepository extends Mock implements ContactRepository {}

const _uid = 'uid_alice';
const _dummyFailure = AppFailure.unknown();

const _dummyCurrentProfile = UserProfile(
  uid: _uid,
  username: 'alice',
  name: 'Alice',
  surname: 'Wonder',
);

const _dummyPeerProfile = UserProfile(
  uid: 'uid_bob',
  username: 'bob',
  name: 'Bob',
  surname: 'Smith',
  profilePhoto: 'https://photo.url',
);

final _dummyContact = Contact(
  id: 'contact_1',
  protectedPersonUid: _uid,
  trustedContactUid: 'uid_bob',
  protectedPersonUsername: 'alice',
  trustedContactUsername: 'bob',
  createdAt: DateTime(2024),
);

final _dummyContactRequest = ContactRequest(
  id: 'req_1',
  senderUid: _uid,
  receiverUid: 'uid_bob',
  senderUsername: 'alice',
  receiverUsername: 'bob',
  createdAt: DateTime(2024),
);

const _dummyTrustedContactItem = ContactRequestItem(
  requestId: 'contact_1',
  direction: ContactRequestDirection.sent,
  peerUid: 'uid_bob',
  peerUsername: 'Bob Smith',
  peerPhoto: 'https://photo.url',
);

const _dummySentRequestItem = ContactRequestItem(
  requestId: 'req_1',
  direction: ContactRequestDirection.sent,
  peerUid: 'uid_bob',
  peerUsername: 'Bob Smith',
  peerPhoto: 'https://photo.url',
);

// MARK: - TEST CASES

void main() {
  late MockUserProfileRepository mockUserProfileRepository;
  late MockContactRequestRepository mockContactRequestRepository;
  late MockContactRepository mockContactRepository;

  TrustedContactsCubit buildCubit() => TrustedContactsCubit(
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

  group('TrustedContactsCubit.loadUserCode', () {
    blocTest<TrustedContactsCubit, TrustedContactsState>(
      '[HAPPY PATH] - GIVEN a valid profile, WHEN loadUserCode is called, THEN should emit [isLoading: true, isLoading: false + username]',
      build: () {
        when(
          () => mockUserProfileRepository.getProfile(_uid),
        ).thenAnswer((_) async => const Result.success(_dummyCurrentProfile));
        return buildCubit();
      },
      act: (cubit) => cubit.loadUserCode(),
      expect: () => [
        const TrustedContactsState(isLoading: true),
        const TrustedContactsState(username: 'alice'),
      ],
      verify: (_) {
        verify(() => mockUserProfileRepository.getProfile(_uid)).called(1);
      },
    );

    blocTest<TrustedContactsCubit, TrustedContactsState>(
      '[ERROR PATH] - GIVEN a repository failure, WHEN loadUserCode is called, THEN should emit [isLoading: true, isLoading: false + failure]',
      build: () {
        when(
          () => mockUserProfileRepository.getProfile(_uid),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return buildCubit();
      },
      act: (cubit) => cubit.loadUserCode(),
      expect: () => [
        const TrustedContactsState(isLoading: true),
        const TrustedContactsState(failure: _dummyFailure),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // loadTrustedContacts
  // ---------------------------------------------------------------------------

  group('TrustedContactsCubit.loadTrustedContacts', () {
    blocTest<TrustedContactsCubit, TrustedContactsState>(
      '[HAPPY PATH] - GIVEN contacts and resolvable profiles, WHEN loadTrustedContacts is called, THEN should emit [loading, items with resolved name and photo]',
      build: () {
        when(
          () => mockContactRepository.getTrustedContacts(_uid),
        ).thenAnswer((_) async => Result.success([_dummyContact]));
        when(
          () => mockUserProfileRepository.getProfile(
            _dummyContact.trustedContactUid,
          ),
        ).thenAnswer((_) async => const Result.success(_dummyPeerProfile));
        return buildCubit();
      },
      act: (cubit) => cubit.loadTrustedContacts(),
      expect: () => [
        const TrustedContactsState(isLoadingTrustedContacts: true),
        const TrustedContactsState(trustedContacts: [_dummyTrustedContactItem]),
      ],
    );

    blocTest<TrustedContactsCubit, TrustedContactsState>(
      '[EDGE CASE] - GIVEN contacts but profile fetch fails, WHEN loadTrustedContacts is called, THEN should emit items falling back to username from contact',
      build: () {
        when(
          () => mockContactRepository.getTrustedContacts(_uid),
        ).thenAnswer((_) async => Result.success([_dummyContact]));
        when(
          () => mockUserProfileRepository.getProfile(
            _dummyContact.trustedContactUid,
          ),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return buildCubit();
      },
      act: (cubit) => cubit.loadTrustedContacts(),
      expect: () => [
        const TrustedContactsState(isLoadingTrustedContacts: true),
        TrustedContactsState(
          trustedContacts: [
            ContactRequestItem(
              requestId: 'contact_1',
              direction: ContactRequestDirection.sent,
              peerUid: 'uid_bob',
              peerUsername: _dummyContact.trustedContactUsername,
            ),
          ],
        ),
      ],
    );

    blocTest<TrustedContactsCubit, TrustedContactsState>(
      '[ERROR PATH] - GIVEN a repository failure, WHEN loadTrustedContacts is called, THEN should emit [loading, failure]',
      build: () {
        when(
          () => mockContactRepository.getTrustedContacts(_uid),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return buildCubit();
      },
      act: (cubit) => cubit.loadTrustedContacts(),
      expect: () => [
        const TrustedContactsState(isLoadingTrustedContacts: true),
        const TrustedContactsState(trustedContactsFailure: _dummyFailure),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // deleteContact
  // ---------------------------------------------------------------------------

  group('TrustedContactsCubit.deleteContact', () {
    blocTest<TrustedContactsCubit, TrustedContactsState>(
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
      seed: () => const TrustedContactsState(
        trustedContacts: [_dummyTrustedContactItem],
      ),
      act: (cubit) => cubit.deleteContact('contact_1'),
      expect: () => [
        const TrustedContactsState(
          isDeletingContact: true,
          trustedContacts: [_dummyTrustedContactItem],
        ),
        const TrustedContactsState(),
      ],
    );

    blocTest<TrustedContactsCubit, TrustedContactsState>(
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
        const TrustedContactsState(isDeletingContact: true),
        const TrustedContactsState(deleteContactFailure: _dummyFailure),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // loadSentRequests
  // ---------------------------------------------------------------------------

  group('TrustedContactsCubit.loadSentRequests', () {
    blocTest<TrustedContactsCubit, TrustedContactsState>(
      '[HAPPY PATH] - GIVEN requests and resolvable profiles, WHEN loadSentRequests is called, THEN should emit [loading, items with resolved name and photo]',
      build: () {
        when(
          () => mockContactRequestRepository.getSentRequests(_uid),
        ).thenAnswer((_) async => Result.success([_dummyContactRequest]));
        when(
          () => mockUserProfileRepository.getProfile(
            _dummyContactRequest.receiverUid,
          ),
        ).thenAnswer((_) async => const Result.success(_dummyPeerProfile));
        return buildCubit();
      },
      act: (cubit) => cubit.loadSentRequests(),
      expect: () => [
        const TrustedContactsState(isLoadingSentRequests: true),
        const TrustedContactsState(sentRequests: [_dummySentRequestItem]),
      ],
    );

    blocTest<TrustedContactsCubit, TrustedContactsState>(
      '[EDGE CASE] - GIVEN requests but profile fetch fails, WHEN loadSentRequests is called, THEN should emit items falling back to username from request',
      build: () {
        when(
          () => mockContactRequestRepository.getSentRequests(_uid),
        ).thenAnswer((_) async => Result.success([_dummyContactRequest]));
        when(
          () => mockUserProfileRepository.getProfile(
            _dummyContactRequest.receiverUid,
          ),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return buildCubit();
      },
      act: (cubit) => cubit.loadSentRequests(),
      expect: () => [
        const TrustedContactsState(isLoadingSentRequests: true),
        TrustedContactsState(
          sentRequests: [
            ContactRequestItem(
              requestId: 'req_1',
              direction: ContactRequestDirection.sent,
              peerUid: 'uid_bob',
              peerUsername: _dummyContactRequest.receiverUsername,
            ),
          ],
        ),
      ],
    );

    blocTest<TrustedContactsCubit, TrustedContactsState>(
      '[ERROR PATH] - GIVEN a repository failure, WHEN loadSentRequests is called, THEN should emit [loading, failure]',
      build: () {
        when(
          () => mockContactRequestRepository.getSentRequests(_uid),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return buildCubit();
      },
      act: (cubit) => cubit.loadSentRequests(),
      expect: () => [
        const TrustedContactsState(isLoadingSentRequests: true),
        const TrustedContactsState(sentRequestsFailure: _dummyFailure),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // sendRequest
  // ---------------------------------------------------------------------------

  group('TrustedContactsCubit.sendRequest', () {
    blocTest<TrustedContactsCubit, TrustedContactsState>(
      '[HAPPY PATH] - GIVEN username loaded and createRequest succeeds, WHEN sendRequest is called, THEN should emit [sending, success + requestSentSuccess] and trigger loadSentRequests',
      build: () {
        when(
          () => mockContactRequestRepository.createRequest(
            senderUid: _uid,
            senderUsername: 'alice',
            receiverUsername: 'bob',
          ),
        ).thenAnswer((_) async => const Result.success(null));
        when(
          () => mockContactRequestRepository.getSentRequests(_uid),
        ).thenAnswer((_) async => const Result.success([]));
        return buildCubit();
      },
      seed: () => const TrustedContactsState(username: 'alice'),
      act: (cubit) async {
        await cubit.sendRequest('bob');
        // Allow the fire-and-forget loadSentRequests to complete.
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        const TrustedContactsState(isSendingRequest: true, username: 'alice'),
        const TrustedContactsState(username: 'alice', requestSentSuccess: true),
        const TrustedContactsState(
          username: 'alice',
          requestSentSuccess: true,
          isLoadingSentRequests: true,
        ),
        const TrustedContactsState(username: 'alice', requestSentSuccess: true),
      ],
    );

    blocTest<TrustedContactsCubit, TrustedContactsState>(
      '[EDGE CASE] - GIVEN username is null, WHEN sendRequest is called, THEN should emit nothing and not call the repository',
      build: () => buildCubit(),
      act: (cubit) => cubit.sendRequest('bob'),
      expect: () => [],
      verify: (_) {
        verifyNever(
          () => mockContactRequestRepository.createRequest(
            senderUid: any(named: 'senderUid'),
            senderUsername: any(named: 'senderUsername'),
            receiverUsername: any(named: 'receiverUsername'),
          ),
        );
      },
    );

    blocTest<TrustedContactsCubit, TrustedContactsState>(
      '[ERROR PATH] - GIVEN a repository failure, WHEN sendRequest is called, THEN should emit [sending, failure] and not trigger loadSentRequests',
      build: () {
        when(
          () => mockContactRequestRepository.createRequest(
            senderUid: _uid,
            senderUsername: 'alice',
            receiverUsername: 'bob',
          ),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return buildCubit();
      },
      seed: () => const TrustedContactsState(username: 'alice'),
      act: (cubit) => cubit.sendRequest('bob'),
      expect: () => [
        const TrustedContactsState(isSendingRequest: true, username: 'alice'),
        const TrustedContactsState(
          username: 'alice',
          sendRequestFailure: _dummyFailure,
        ),
      ],
      verify: (_) {
        verifyNever(() => mockContactRequestRepository.getSentRequests(any()));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // deleteSentRequest
  // ---------------------------------------------------------------------------

  group('TrustedContactsCubit.deleteSentRequest', () {
    blocTest<TrustedContactsCubit, TrustedContactsState>(
      '[HAPPY PATH] - GIVEN the request exists in local list, WHEN deleteSentRequest is called, THEN should emit [deleting, item removed from list]',
      build: () {
        when(
          () => mockContactRequestRepository.deleteRequest(
            requestId: 'req_1',
            requesterUid: _uid,
          ),
        ).thenAnswer((_) async => const Result.success(null));
        return buildCubit();
      },
      seed: () =>
          const TrustedContactsState(sentRequests: [_dummySentRequestItem]),
      act: (cubit) => cubit.deleteSentRequest('req_1'),
      expect: () => [
        const TrustedContactsState(
          isDeletingRequest: true,
          sentRequests: [_dummySentRequestItem],
        ),
        const TrustedContactsState(),
      ],
    );

    blocTest<TrustedContactsCubit, TrustedContactsState>(
      '[ERROR PATH] - GIVEN a repository failure, WHEN deleteSentRequest is called, THEN should emit [deleting, failure]',
      build: () {
        when(
          () => mockContactRequestRepository.deleteRequest(
            requestId: 'req_1',
            requesterUid: _uid,
          ),
        ).thenAnswer((_) async => const Result.failure(_dummyFailure));
        return buildCubit();
      },
      act: (cubit) => cubit.deleteSentRequest('req_1'),
      expect: () => [
        const TrustedContactsState(isDeletingRequest: true),
        const TrustedContactsState(deleteRequestFailure: _dummyFailure),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // clear actions
  // ---------------------------------------------------------------------------

  group('TrustedContactsCubit.clearActions', () {
    blocTest<TrustedContactsCubit, TrustedContactsState>(
      '[RESET ACTION] - GIVEN a sendRequestFailure in state, WHEN clearSendRequestFailure is called, THEN should emit state with failure cleared',
      build: () => buildCubit(),
      seed: () => const TrustedContactsState(sendRequestFailure: _dummyFailure),
      act: (cubit) => cubit.clearSendRequestFailure(),
      expect: () => [const TrustedContactsState()],
    );

    blocTest<TrustedContactsCubit, TrustedContactsState>(
      '[RESET ACTION] - GIVEN requestSentSuccess is true, WHEN clearRequestSentSuccess is called, THEN should emit state with flag cleared',
      build: () => buildCubit(),
      seed: () => const TrustedContactsState(requestSentSuccess: true),
      act: (cubit) => cubit.clearRequestSentSuccess(),
      expect: () => [const TrustedContactsState()],
    );

    blocTest<TrustedContactsCubit, TrustedContactsState>(
      '[RESET ACTION] - GIVEN a deleteRequestFailure in state, WHEN clearDeleteRequestFailure is called, THEN should emit state with failure cleared',
      build: () => buildCubit(),
      seed: () =>
          const TrustedContactsState(deleteRequestFailure: _dummyFailure),
      act: (cubit) => cubit.clearDeleteRequestFailure(),
      expect: () => [const TrustedContactsState()],
    );

    blocTest<TrustedContactsCubit, TrustedContactsState>(
      '[RESET ACTION] - GIVEN a deleteContactFailure in state, WHEN clearDeleteContactFailure is called, THEN should emit state with failure cleared',
      build: () => buildCubit(),
      seed: () =>
          const TrustedContactsState(deleteContactFailure: _dummyFailure),
      act: (cubit) => cubit.clearDeleteContactFailure(),
      expect: () => [const TrustedContactsState()],
    );
  });
}
