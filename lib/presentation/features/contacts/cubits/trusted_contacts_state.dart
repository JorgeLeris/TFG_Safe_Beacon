part of 'trusted_contacts_cubit.dart';

@freezed
abstract class TrustedContactsState with _$TrustedContactsState {
  const factory TrustedContactsState({
    @Default(false) bool isLoading,
    String? username,
    AppFailure? failure,
  }) = _TrustedContactsState;
}
