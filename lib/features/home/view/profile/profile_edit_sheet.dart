part of '../profile_screen.dart';

Future<_ProfileEditDraft?> _showProfileEditSheet({
  required BuildContext context,
  required String displayName,
  required String bio,
  required String username,
  required String? photoUrl,
  required VoidCallback onChangePhoto,
}) async {
  final nameController = TextEditingController(text: displayName);
  final bioController = TextEditingController(text: bio);
  String? nameError;

  try {
    return await showModalBottomSheet<_ProfileEditDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: _ProfileScreenState._bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;

            void submit() {
              final trimmedName = nameController.text.trim();
              if (trimmedName.isEmpty) {
                setSheetState(() => nameError = 'Name cannot be empty');
                return;
              }

              Navigator.pop(
                sheetContext,
                _ProfileEditDraft(
                  name: trimmedName,
                  bio: bioController.text.trim(),
                ),
              );
            }

            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        IconButton(
                          tooltip: 'Close',
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(
                            Icons.close,
                            color: _ProfileScreenState._text,
                          ),
                        ),
                        const Expanded(
                          child: Text(
                            'Edit profile',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _ProfileScreenState._text,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: submit,
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              color: _ProfileScreenState._accent,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _EditableProfileAvatar(
                      photoUrl: photoUrl,
                      onTap: onChangePhoto,
                    ),
                    const SizedBox(height: 24),
                    _EditProfileField(
                      controller: nameController,
                      label: 'Name',
                      maxLength: 30,
                      errorText: nameError,
                      onChanged: (_) {
                        if (nameError == null) return;
                        setSheetState(() => nameError = null);
                      },
                    ),
                    const SizedBox(height: 14),
                    _ReadonlyProfileField(label: 'Username', value: username),
                    const SizedBox(height: 14),
                    _EditProfileField(
                      controller: bioController,
                      label: 'Bio',
                      maxLines: 3,
                      maxLength: 80,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  } finally {
    nameController.dispose();
    bioController.dispose();
  }
}

class _EditableProfileAvatar extends StatelessWidget {
  const _EditableProfileAvatar({required this.photoUrl, required this.onTap});

  final String? photoUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.trim().isNotEmpty;

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: _ProfileScreenState._surface,
                backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
                child: hasPhoto
                    ? null
                    : const Icon(
                        Icons.person,
                        color: _ProfileScreenState._text,
                        size: 42,
                      ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _ProfileScreenState._surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: _ProfileScreenState._bg, width: 2),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: _ProfileScreenState._text,
                  size: 15,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Change photo',
          style: TextStyle(
            color: _ProfileScreenState._text,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
