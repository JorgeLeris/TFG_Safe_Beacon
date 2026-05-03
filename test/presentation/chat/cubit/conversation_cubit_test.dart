import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safe_beacon/domain/chat/chat_repository.dart';
import 'package:safe_beacon/domain/chat/entities/message.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';
import 'package:safe_beacon/domain/profile/entities/user_profile.dart';
import 'package:safe_beacon/domain/profile/user_profile_repository.dart';
import 'package:safe_beacon/presentation/features/chat/cubits/conversation_cubit.dart';

// MARK: - MOCKS

class MockChatRepository extends Mock implements ChatRepository {}

class MockUserProfileRepository extends Mock implements UserProfileRepository {}

// MARK: - DUMMY DATA

const _chatId = 'chat_1';
const _currentUid = 'uid_alice';
const _otherUid = 'uid_bob';

final _now = DateTime(2024, 6);

final _dummyMessage = Message(
  id: 'msg_1',
  senderUid: _otherUid,
  text: 'Hello',
  createdAt: _now,
  readBy: [_otherUid],
);

const _dummyProfile = UserProfile(
  uid: _currentUid,
  name: 'Alice',
  username: 'alice',
);

const _otherProfile = UserProfile(
  uid: _otherUid,
  name: 'Bob',
  username: 'bob',
  profilePhoto: 'https://example.com/photo.jpg',
);

// MARK: - TEST CASES

void main() {
  late MockChatRepository mockChatRepository;
  late MockUserProfileRepository mockUserProfileRepository;
  late ConversationCubit cubit;

  setUp(() {
    mockChatRepository = MockChatRepository();
    mockUserProfileRepository = MockUserProfileRepository();

    // Default stub for markAsRead (called automatically on watchMessages).
    when(
      () => mockChatRepository.markAsRead(
        chatId: any(named: 'chatId'),
        uid: any(named: 'uid'),
      ),
    ).thenAnswer((_) async => const Result.success(null));

    // Default stub for profile loads triggered inside watchMessages.
    when(
      () => mockUserProfileRepository.getProfile(any()),
    ).thenAnswer((_) async => const Result.success(_otherProfile));

    cubit = ConversationCubit(
      chatId: _chatId,
      currentUid: _currentUid,
      chatRepository: mockChatRepository,
      userProfileRepository: mockUserProfileRepository,
      participantUids: [_currentUid, _otherUid],
    );
  });

  tearDown(() => cubit.close());

  // ---------------------------------------------------------------------------
  // watchMessages
  // ---------------------------------------------------------------------------

  group('ConversationCubit.watchMessages', () {
    blocTest<ConversationCubit, ConversationState>(
      '[HAPPY PATH] - GIVEN messages exist, WHEN watchMessages is called, THEN should emit [loading, messages] and mark as read',
      build: () {
        when(
          () => mockChatRepository.watchMessages(_chatId),
        ).thenAnswer((_) => Stream.value([_dummyMessage]));
        return cubit;
      },
      act: (cubit) => cubit.watchMessages(),
      expect: () => [
        isA<ConversationState>().having((s) => s.isLoading, 'loading', true),
        // _loadOtherProfilePhoto resolves concurrently and emits before messages.
        isA<ConversationState>().having(
          (s) => s.otherProfilePhoto,
          'otherProfilePhoto',
          'https://example.com/photo.jpg',
        ),
        isA<ConversationState>()
            .having((s) => s.isLoading, 'loading', false)
            .having((s) => s.messages, 'messages', [_dummyMessage]),
      ],
      verify: (_) {
        verify(
          () =>
              mockChatRepository.markAsRead(chatId: _chatId, uid: _currentUid),
        ).called(greaterThanOrEqualTo(1));
      },
    );

    blocTest<ConversationCubit, ConversationState>(
      '[HAPPY PATH] - GIVEN watchMessages is called, THEN should load other participant photo into state',
      build: () {
        when(
          () => mockChatRepository.watchMessages(_chatId),
        ).thenAnswer((_) => Stream.value([]));
        when(
          () => mockUserProfileRepository.getProfile(_otherUid),
        ).thenAnswer((_) async => const Result.success(_otherProfile));
        return cubit;
      },
      act: (cubit) => cubit.watchMessages(),
      expect: () => [
        isA<ConversationState>().having((s) => s.isLoading, 'loading', true),
        isA<ConversationState>().having(
          (s) => s.otherProfilePhoto,
          'otherProfilePhoto',
          'https://example.com/photo.jpg',
        ),
        isA<ConversationState>().having((s) => s.isLoading, 'loading', false),
      ],
    );

    blocTest<ConversationCubit, ConversationState>(
      '[ERROR PATH] - GIVEN a stream error, WHEN watchMessages is called, THEN should emit [loading, (photo), failure]',
      build: () {
        when(
          () => mockChatRepository.watchMessages(_chatId),
        ).thenAnswer((_) => Stream.error(Exception('stream error')));
        return cubit;
      },
      act: (cubit) => cubit.watchMessages(),
      expect: () => [
        isA<ConversationState>().having((s) => s.isLoading, 'loading', true),
        // Photo may arrive before or after the error — skip with any matcher.
        isA<ConversationState>(),
        isA<ConversationState>()
            .having((s) => s.isLoading, 'loading', false)
            .having((s) => s.failure, 'failure', const AppFailure.unknown()),
      ],
    );
  });

  // ---------------------------------------------------------------------------
  // sendMessage
  // ---------------------------------------------------------------------------

  group('ConversationCubit.sendMessage', () {
    blocTest<ConversationCubit, ConversationState>(
      '[HAPPY PATH] - GIVEN a valid text, WHEN sendMessage is called, THEN should emit [sending, idle] and call the repository',
      build: () {
        when(
          () => mockChatRepository.sendMessage(
            chatId: _chatId,
            senderUid: _currentUid,
            text: 'Hello',
          ),
        ).thenAnswer((_) async => const Result.success(null));
        when(
          () => mockUserProfileRepository.getProfile(_currentUid),
        ).thenAnswer((_) async => const Result.success(_dummyProfile));
        when(
          () => mockUserProfileRepository.getFcmTokensForUsers([_otherUid]),
        ).thenAnswer((_) async => const Result.success([]));
        return cubit;
      },
      act: (cubit) => cubit.sendMessage('Hello'),
      expect: () => [
        isA<ConversationState>().having((s) => s.isSending, 'sending', true),
        isA<ConversationState>().having((s) => s.isSending, 'sending', false),
      ],
      verify: (_) {
        verify(
          () => mockChatRepository.sendMessage(
            chatId: _chatId,
            senderUid: _currentUid,
            text: 'Hello',
          ),
        ).called(1);
      },
    );

    blocTest<ConversationCubit, ConversationState>(
      '[EDGE CASE] - GIVEN an empty or whitespace-only text, WHEN sendMessage is called, THEN should not emit any state and not call the repository',
      build: () => cubit,
      act: (cubit) => cubit.sendMessage('   '),
      expect: () => [],
      verify: (_) {
        verifyNever(
          () => mockChatRepository.sendMessage(
            chatId: any(named: 'chatId'),
            senderUid: any(named: 'senderUid'),
            text: any(named: 'text'),
          ),
        );
      },
    );

    blocTest<ConversationCubit, ConversationState>(
      '[ERROR PATH] - GIVEN a repository failure, WHEN sendMessage is called, THEN should emit [sending, failure]',
      build: () {
        when(
          () => mockChatRepository.sendMessage(
            chatId: any(named: 'chatId'),
            senderUid: any(named: 'senderUid'),
            text: any(named: 'text'),
          ),
        ).thenAnswer((_) async => const Result.failure(AppFailure.unknown()));
        return cubit;
      },
      act: (cubit) => cubit.sendMessage('Hello'),
      expect: () => [
        isA<ConversationState>().having((s) => s.isSending, 'sending', true),
        isA<ConversationState>()
            .having((s) => s.isSending, 'sending', false)
            .having((s) => s.failure, 'failure', const AppFailure.unknown()),
      ],
    );
  });
}
