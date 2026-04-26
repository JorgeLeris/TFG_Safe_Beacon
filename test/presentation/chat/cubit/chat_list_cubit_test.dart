import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_beacon/domain/chat/chat_repository.dart';
import 'package:safe_beacon/domain/chat/entities/chat.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/profile/entities/user_profile.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';
import 'package:safe_beacon/presentation/features/chat/cubits/chat_list_cubit.dart';

// MARK: - MOCKS

class MockChatRepository extends Mock implements ChatRepository {}

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

// MARK: - DUMMY DATA

const _currentUid = 'uid_alice';
const _otherUid = 'uid_bob';

final _now = DateTime(2024, 6);

final _dummyChat = Chat(
  id: 'chat_1',
  participantUids: [_currentUid, _otherUid],
  lastMessage: 'Hello',
  lastMessageSenderUid: _otherUid,
  lastMessageAt: _now,
  createdAt: _now,
  unreadCounts: {_currentUid: 2},
);

const _dummyProfile = UserProfile(
  uid: _otherUid,
  name: 'Bob',
  surname: 'Smith',
  username: 'bobsmith',
);

// MARK: - TEST CASES

void main() {
  late MockChatRepository mockChatRepository;
  late MockUserProfileRepository mockUserProfileRepository;
  late ChatListCubit cubit;

  setUp(() {
    mockChatRepository = MockChatRepository();
    mockUserProfileRepository = MockUserProfileRepository();
    cubit = ChatListCubit(
      uid: _currentUid,
      chatRepository: mockChatRepository,
      userProfileRepository: mockUserProfileRepository,
    );
  });

  tearDown(() => cubit.close());

  // ---------------------------------------------------------------------------
  // watchChats
  // ---------------------------------------------------------------------------

  group('ChatListCubit.watchChats', () {
    blocTest<ChatListCubit, ChatListState>(
      '[HAPPY PATH] - GIVEN chats exist, WHEN watchChats is called, THEN should emit [loading, entries with resolved profile]',
      build: () {
        when(
          () => mockChatRepository.watchChats(_currentUid),
        ).thenAnswer((_) => Stream.value([_dummyChat]));
        when(
          () => mockUserProfileRepository.getProfile(_otherUid),
        ).thenAnswer((_) async => const Result.success(_dummyProfile));
        return cubit;
      },
      act: (cubit) => cubit.watchChats(),
      expect: () => [
        isA<ChatListState>().having((s) => s.isLoading, 'loading', true),
        isA<ChatListState>()
            .having((s) => s.isLoading, 'loading', false)
            .having((s) => s.chats.length, 'chats length', 1)
            .having((s) => s.chats.first.chatId, 'chatId', 'chat_1')
            .having(
              (s) => s.chats.first.displayName,
              'displayName',
              'Bob Smith',
            )
            .having((s) => s.chats.first.unreadCount, 'unreadCount', 2)
            .having(
              (s) => s.chats.first.lastMessageIsFromMe,
              'lastMessageIsFromMe',
              false,
            ),
      ],
      verify: (_) {
        verify(() => mockUserProfileRepository.getProfile(_otherUid)).called(1);
      },
    );

    blocTest<ChatListCubit, ChatListState>(
      '[HAPPY PATH] - GIVEN no chats, WHEN watchChats is called, THEN should emit [loading, empty list]',
      build: () {
        when(
          () => mockChatRepository.watchChats(_currentUid),
        ).thenAnswer((_) => Stream.value([]));
        return cubit;
      },
      act: (cubit) => cubit.watchChats(),
      expect: () => [
        isA<ChatListState>().having((s) => s.isLoading, 'loading', true),
        isA<ChatListState>()
            .having((s) => s.isLoading, 'loading', false)
            .having((s) => s.chats, 'chats', isEmpty),
      ],
    );

    blocTest<ChatListCubit, ChatListState>(
      '[HAPPY PATH] - GIVEN profile is fetched once, WHEN watchChats emits two updates, THEN should use the cache and call getProfile only once',
      build: () {
        when(() => mockChatRepository.watchChats(_currentUid)).thenAnswer(
          (_) => Stream.fromIterable([
            [_dummyChat],
            [_dummyChat],
          ]),
        );
        when(
          () => mockUserProfileRepository.getProfile(_otherUid),
        ).thenAnswer((_) async => const Result.success(_dummyProfile));
        return cubit;
      },
      act: (cubit) => cubit.watchChats(),
      verify: (_) {
        verify(() => mockUserProfileRepository.getProfile(_otherUid)).called(1);
      },
    );

    blocTest<ChatListCubit, ChatListState>(
      '[ERROR PATH] - GIVEN a stream error, WHEN watchChats is called, THEN should emit [loading, failure]',
      build: () {
        when(
          () => mockChatRepository.watchChats(_currentUid),
        ).thenAnswer((_) => Stream.error(Exception('stream error')));
        return cubit;
      },
      act: (cubit) => cubit.watchChats(),
      expect: () => [
        isA<ChatListState>().having((s) => s.isLoading, 'loading', true),
        isA<ChatListState>()
            .having((s) => s.isLoading, 'loading', false)
            .having((s) => s.failure, 'failure', const AppFailure.unknown()),
      ],
    );

    blocTest<ChatListCubit, ChatListState>(
      '[ERROR PATH] - GIVEN profile fetch fails, WHEN watchChats is called, THEN should fall back to uid as displayName',
      build: () {
        when(
          () => mockChatRepository.watchChats(_currentUid),
        ).thenAnswer((_) => Stream.value([_dummyChat]));
        when(
          () => mockUserProfileRepository.getProfile(_otherUid),
        ).thenAnswer((_) async => const Result.failure(AppFailure.unknown()));
        return cubit;
      },
      act: (cubit) => cubit.watchChats(),
      expect: () => [
        isA<ChatListState>().having((s) => s.isLoading, 'loading', true),
        isA<ChatListState>()
            .having((s) => s.isLoading, 'loading', false)
            .having(
              (s) => s.chats.first.displayName,
              'displayName fallback',
              _otherUid,
            ),
      ],
    );
  });
}
