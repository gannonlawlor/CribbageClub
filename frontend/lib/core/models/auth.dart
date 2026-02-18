import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth.freezed.dart';
part 'auth.g.dart';

@freezed
class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required String token,
    required String userId,
    required String username,
    String? displayName,
    @Default(false) bool isGuest,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}

@freezed
class LoginRequest with _$LoginRequest {
  const factory LoginRequest({
    required String username,
    required String password,
  }) = _LoginRequest;

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);
}

@freezed
class RegisterRequest with _$RegisterRequest {
  const factory RegisterRequest({
    required String username,
    required String password,
    String? displayName,
  }) = _RegisterRequest;

  factory RegisterRequest.fromJson(Map<String, dynamic> json) =>
      _$RegisterRequestFromJson(json);
}

@freezed
class UpgradeRequest with _$UpgradeRequest {
  const factory UpgradeRequest({
    required String username,
    required String password,
    String? displayName,
  }) = _UpgradeRequest;

  factory UpgradeRequest.fromJson(Map<String, dynamic> json) =>
      _$UpgradeRequestFromJson(json);
}
