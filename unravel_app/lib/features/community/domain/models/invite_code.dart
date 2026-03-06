import 'package:freezed_annotation/freezed_annotation.dart';
part 'invite_code.freezed.dart';
part 'invite_code.g.dart';

@freezed
class InviteCode with _$InviteCode {
  const factory InviteCode({
    required String code,
    required String encryptedCode,
    required DateTime createdAt,
    @Default(false) bool isUsed,
  }) = _InviteCode;

  factory InviteCode.fromJson(Map<String, dynamic> json) => _$InviteCodeFromJson(json);
}
