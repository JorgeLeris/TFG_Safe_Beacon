part of 'protected_people_cubit.dart';

@freezed
abstract class ProtectedPeopleState with _$ProtectedPeopleState {
  const factory ProtectedPeopleState({
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingReceivedRequests,
    @Default(false) bool isLoadingProtectedPeople,
    @Default(false) bool isDeletingRequest,
    @Default(false) bool isAcceptingRequest,
    @Default(false) bool isDeletingContact,
    @Default([]) List<ContactRequestItem> receivedRequests,
    @Default([]) List<ContactRequestItem> protectedPeople,
    String? username,
    AppFailure? failure,
    AppFailure? receivedRequestsFailure,
    AppFailure? protectedPeopleFailure,
    AppFailure? deleteRequestFailure,
    AppFailure? acceptRequestFailure,
    AppFailure? deleteContactFailure,
  }) = _ProtectedPeopleState;
}
