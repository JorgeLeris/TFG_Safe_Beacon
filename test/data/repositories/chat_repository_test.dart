import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:safe_beacon/data/repositories/chat_repository_impl.dart';
import 'package:safe_beacon/data/sources/firebase/chat/chat_api.dart';
import 'package:safe_beacon/data/sources/firebase/chat/dto/chat_dto.dart';
import 'package:safe_beacon/data/sources/firebase/chat/dto/message_dto.dart';
import 'package:safe_beacon/domain/chat/entities/chat.dart';
import 'package:safe_beacon/domain/chat/entities/message.dart';
import 'package:safe_beacon/domain/common/app_failure.dart';
import 'package:safe_beacon/domain/common/result.dart';

// MARK: - DUMMY DATA & MOCKS

class MockChatApi extends Mock implements ChatApi {}

final _now = DateTime(2024, 6);

final _dummyChatDto = ChatDto(
  participantUids: ['uid_alice', 'uid_bob'],
  lastMessage: 'Hello',
  lastMessageSenderUid: 'uid_alice',
  lastMessageAt: _now,
  createdAt: _now,
  unreadCounts: {'uid_bob': 1},
);

final _dummyChatRecord = (id: 'chat_1', dto: _dummyChatDto);

final _dummyChat = Chat(
  id: 'chat_1',
  participantUids: ['uid_alice', 'uid_bob'],
  lastMessage: 'Hello',
  lastMessageSenderUid: 'uid_alice',
  lastMessageAt: _now,
  createdAt: _now,
  unreadCounts: {'uid_bob': 1},
);

final _dummyMessageDto = MessageDto(
  senderUid: 'uid_alice',
  text: 'Hello',
  createdAt: _now,
  readBy: ['uid_alice'],
);

final _dummyMessageRecord = (id: 'msg_1', dto: _dummyMessageDto);

final _dummyMessage = Message(
  id: 'msg_1',
  senderUid: 'uid_alice',
  text: 'Hello',
  createdAt: _now,
  readBy: ['uid_alice'],
);

FirebaseException _firebaseException(String code) =>
    FirebaseException(plugin: 'firestore', code: code);

// MARK: - TEST CASES

void main() {
  late MockChatApi mockApi;
  late ChatRepositoryImpl repository;

  setUp(() {
    mockApi = MockChatApi();
    repository = ChatRepositoryImpl(api: mockApi);
  });

  // ---------------------------------------------------------------------------
  // getOrCreateChat
  // ---------------------------------------------------------------------------

  group('ChatRepositoryImpl.getOrCreateChat', () {
    test(
      '[HAPPY PATH] - GIVEN an existing chat, WHEN getOrCreateChat is called, THEN should return the existing chat ID without creating a new one',
      () async {
        when(
          () => mockApi.findChat('uid_alice', 'uid_bob'),
        ).thenAnswer((_) async => _dummyChatRecord);

        final result = await repository.getOrCreateChat(
          currentUid: 'uid_alice',
          otherUid: 'uid_bob',
        );

        expect(result, isA<Success<String>>());
        expect((result as Success).value, equals('chat_1'));
        verifyNever(() => mockApi.createChat(any(), any()));
      },
    );

    test(
      '[HAPPY PATH] - GIVEN no existing chat, WHEN getOrCreateChat is called, THEN should create a new chat and return its ID',
      () async {
        when(
          () => mockApi.findChat('uid_alice', 'uid_bob'),
        ).thenAnswer((_) async => null);
        when(
          () => mockApi.createChat('uid_alice', 'uid_bob'),
        ).thenAnswer((_) async => 'chat_new');

        final result = await repository.getOrCreateChat(
          currentUid: 'uid_alice',
          otherUid: 'uid_bob',
        );

        expect(result, isA<Success<String>>());
        expect((result as Success).value, equals('chat_new'));
        verify(() => mockApi.createChat('uid_alice', 'uid_bob')).called(1);
      },
    );

    test(
      '[ERROR PATH] - GIVEN a FirebaseException with permission-denied, WHEN getOrCreateChat is called, THEN should return AppFailure.forbidden',
      () async {
        when(
          () => mockApi.findChat(any(), any()),
        ).thenThrow(_firebaseException('permission-denied'));

        final result = await repository.getOrCreateChat(
          currentUid: 'uid_alice',
          otherUid: 'uid_bob',
        );

        expect(result, isA<Failure<String>>());
        expect(
          (result as Failure).failure,
          equals(const AppFailure.forbidden()),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN an unexpected exception, WHEN getOrCreateChat is called, THEN should return AppFailure.unknown',
      () async {
        when(
          () => mockApi.findChat(any(), any()),
        ).thenThrow(Exception('unexpected'));

        final result = await repository.getOrCreateChat(
          currentUid: 'uid_alice',
          otherUid: 'uid_bob',
        );

        expect(result, isA<Failure<String>>());
        expect((result as Failure).failure, equals(const AppFailure.unknown()));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // watchChats
  // ---------------------------------------------------------------------------

  group('ChatRepositoryImpl.watchChats', () {
    test(
      '[HAPPY PATH] - GIVEN a list of chat records, WHEN watchChats is called, THEN should emit a list of mapped Chat entities',
      () {
        when(
          () => mockApi.watchChats('uid_alice'),
        ).thenAnswer((_) => Stream.value([_dummyChatRecord]));

        expect(repository.watchChats('uid_alice'), emits([_dummyChat]));
      },
    );

    test(
      '[EDGE CASE] - GIVEN an empty list, WHEN watchChats is called, THEN should emit an empty list',
      () {
        when(
          () => mockApi.watchChats('uid_alice'),
        ).thenAnswer((_) => Stream.value([]));

        expect(repository.watchChats('uid_alice'), emits(isEmpty));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // watchMessages
  // ---------------------------------------------------------------------------

  group('ChatRepositoryImpl.watchMessages', () {
    test(
      '[HAPPY PATH] - GIVEN a list of message records, WHEN watchMessages is called, THEN should emit a list of mapped Message entities',
      () {
        when(
          () => mockApi.watchMessages('chat_1'),
        ).thenAnswer((_) => Stream.value([_dummyMessageRecord]));

        expect(repository.watchMessages('chat_1'), emits([_dummyMessage]));
      },
    );

    test(
      '[EDGE CASE] - GIVEN an empty list, WHEN watchMessages is called, THEN should emit an empty list',
      () {
        when(
          () => mockApi.watchMessages('chat_1'),
        ).thenAnswer((_) => Stream.value([]));

        expect(repository.watchMessages('chat_1'), emits(isEmpty));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // sendMessage
  // ---------------------------------------------------------------------------

  group('ChatRepositoryImpl.sendMessage', () {
    test(
      '[HAPPY PATH] - GIVEN a valid chat and sender, WHEN sendMessage is called, THEN should call the API with the correct otherUid and return success',
      () async {
        when(
          () => mockApi.findChatById('chat_1'),
        ).thenAnswer((_) async => _dummyChatRecord);
        when(
          () => mockApi.sendMessage(
            chatId: 'chat_1',
            senderUid: 'uid_alice',
            text: 'Hello',
            otherUid: 'uid_bob',
          ),
        ).thenAnswer((_) async {});

        final result = await repository.sendMessage(
          chatId: 'chat_1',
          senderUid: 'uid_alice',
          text: 'Hello',
        );

        expect(result, isA<Success<void>>());
        verify(
          () => mockApi.sendMessage(
            chatId: 'chat_1',
            senderUid: 'uid_alice',
            text: 'Hello',
            otherUid: 'uid_bob',
          ),
        ).called(1);
      },
    );

    test(
      '[ERROR PATH] - GIVEN a chat that does not exist, WHEN sendMessage is called, THEN should return AppFailure.notFound',
      () async {
        when(
          () => mockApi.findChatById('chat_missing'),
        ).thenAnswer((_) async => null);

        final result = await repository.sendMessage(
          chatId: 'chat_missing',
          senderUid: 'uid_alice',
          text: 'Hello',
        );

        expect(result, isA<Failure<void>>());
        expect(
          (result as Failure).failure,
          equals(const AppFailure.notFound('chat')),
        );
      },
    );

    test(
      '[ERROR PATH] - GIVEN a FirebaseException, WHEN sendMessage is called, THEN should return a mapped AppFailure',
      () async {
        when(
          () => mockApi.findChatById(any()),
        ).thenThrow(_firebaseException('unavailable'));

        final result = await repository.sendMessage(
          chatId: 'chat_1',
          senderUid: 'uid_alice',
          text: 'Hello',
        );

        expect(result, isA<Failure<void>>());
        expect((result as Failure).failure, equals(const AppFailure.network()));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // markAsRead
  // ---------------------------------------------------------------------------

  group('ChatRepositoryImpl.markAsRead', () {
    test(
      '[HAPPY PATH] - GIVEN a valid chat and uid, WHEN markAsRead is called, THEN should call the API and return success',
      () async {
        when(
          () => mockApi.markAsRead(chatId: 'chat_1', uid: 'uid_bob'),
        ).thenAnswer((_) async {});

        final result = await repository.markAsRead(
          chatId: 'chat_1',
          uid: 'uid_bob',
        );

        expect(result, isA<Success<void>>());
        verify(
          () => mockApi.markAsRead(chatId: 'chat_1', uid: 'uid_bob'),
        ).called(1);
      },
    );

    test(
      '[ERROR PATH] - GIVEN a FirebaseException, WHEN markAsRead is called, THEN should return a mapped AppFailure',
      () async {
        when(
          () => mockApi.markAsRead(
            chatId: any(named: 'chatId'),
            uid: any(named: 'uid'),
          ),
        ).thenThrow(_firebaseException('permission-denied'));

        final result = await repository.markAsRead(
          chatId: 'chat_1',
          uid: 'uid_bob',
        );

        expect(result, isA<Failure<void>>());
        expect(
          (result as Failure).failure,
          equals(const AppFailure.forbidden()),
        );
      },
    );
  });
}
