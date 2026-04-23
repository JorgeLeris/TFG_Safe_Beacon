part of 'conversation_cubit.dart';

@freezed
abstract class ConversationState with _$ConversationState {
  const factory ConversationState({
    @Default(true) bool isLoading,
    @Default([]) List<Message> messages,
    @Default(false) bool isSending,
    AppFailure? failure,
  }) = _ConversationState;
}
