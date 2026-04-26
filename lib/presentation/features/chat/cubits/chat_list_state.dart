part of 'chat_list_cubit.dart';

@freezed
abstract class ChatListState with _$ChatListState {
  const factory ChatListState({
    @Default(true) bool isLoading,
    @Default([]) List<ChatListEntry> chats,
    AppFailure? failure,
  }) = _ChatListState;
}

class ChatListEntry {
  const ChatListEntry({
    required this.chatId,
    required this.otherUid,
    required this.displayName,
    this.profilePhoto,
    this.lastMessage,
    this.lastMessageIsFromMe = false,
    this.unreadCount = 0,
  });

  final String chatId;
  final String otherUid;
  final String displayName;
  final String? profilePhoto;
  final String? lastMessage;
  final bool lastMessageIsFromMe;
  final int unreadCount;
}
