part of 'trusted_contacts_cubit.dart';

@freezed
abstract class TrustedContactsState with _$TrustedContactsState {
  const factory TrustedContactsState({
    @Default(false) bool isLoading,
    @Default(false) bool isSendingRequest,
    @Default(false) bool isLoadingSentRequests,
    @Default(false) bool isLoadingTrustedContacts,
    @Default(false) bool isDeletingRequest,
    @Default(false) bool isDeletingContact,
    @Default([]) List<ContactRequestItem> sentRequests,
    @Default([]) List<ContactRequestItem> trustedContacts,
    String? username,
    AppFailure? failure,
    AppFailure? sendRequestFailure,
    AppFailure? sentRequestsFailure,
    AppFailure? deleteRequestFailure,
    AppFailure? trustedContactsFailure,
    AppFailure? deleteContactFailure,
  }) = _TrustedContactsState;
}
