part of 'trusted_contacts_cubit.dart';

@freezed
abstract class TrustedContactsState with _$TrustedContactsState {
  const factory TrustedContactsState({
    @Default(false) bool isLoading,
    @Default(false) bool isSendingRequest,
    @Default(false) bool isLoadingSentRequests,
    @Default([]) List<ContactRequestItem> sentRequests,
    String? username,
    AppFailure? failure,
    AppFailure? sendRequestFailure,
    AppFailure? sentRequestsFailure,
  }) = _TrustedContactsState;
}
