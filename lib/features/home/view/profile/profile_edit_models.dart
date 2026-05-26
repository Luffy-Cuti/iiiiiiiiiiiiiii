part of '../profile_screen.dart';

class _ProfileSaveResult {
  const _ProfileSaveResult({required this.saved, required this.message});

  final bool saved;
  final String message;
}

class _ProfileEditDraft {
  const _ProfileEditDraft({required this.name, required this.bio});

  final String name;
  final String bio;
}
