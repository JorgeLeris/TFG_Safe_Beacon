part of 'protected_people_cubit.dart';

@freezed
abstract class ProtectedPeopleState with _$ProtectedPeopleState {
  const factory ProtectedPeopleState({
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingReceivedRequests,
    @Default(false) bool isDeletingRequest,
    @Default([]) List<ContactRequestItem> receivedRequests,
    String? username,
    AppFailure? failure,
    AppFailure? receivedRequestsFailure,
    AppFailure? deleteRequestFailure,
  }) = _ProtectedPeopleState;
}
