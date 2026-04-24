import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../bloc/upload_bloc.dart';

class UploadVideoPage extends StatefulWidget {
  const UploadVideoPage({super.key});

  @override
  State<UploadVideoPage> createState() => _UploadVideoPageState();
}

class _UploadVideoPageState extends State<UploadVideoPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();
  VideoPlayerController? _previewController;

  static const _categoryItems = <DropdownMenuItem<String>>[
    DropdownMenuItem(value: 'music', child: Text('Music')),
    DropdownMenuItem(value: 'gaming', child: Text('Gaming')),
    DropdownMenuItem(value: 'comedy', child: Text('Comedy')),
    DropdownMenuItem(value: 'education', child: Text('Education')),
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _previewController?.dispose();
    super.dispose();
  }

  Future<void> _pickVideo(ImageSource source) async {
    final file = await _picker.pickVideo(source: source);
    if (file == null || !mounted) return;

    final pickedFile = File(file.path);
    context.read<UploadVideoBloc>().add(PickVideoEvent(file: pickedFile));
    await _loadPreview(pickedFile);
  }

  Future<void> _loadPreview(File file) async {
    await _previewController?.dispose();
    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    setState(() => _previewController = controller);
  }

  Future<void> _showPickOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.video_library_outlined),
                title: const Text('Chọn từ thư viện'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.videocam_outlined),
                title: const Text('Quay video'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UploadVideoBloc, UploadVideoState>(
      listener: (context, state) {
        if (state is UploadFailureState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
        if (state is UploadSuccessState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload thành công: ${state.videoId}')),
          );
        }
      },
      builder: (context, state) {
        final uploadState = state is UploadInProgressState ? state : null;
        final isUploading = uploadState != null;
        final canSubmit = state.isReadyToUpload && !isUploading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Đăng video mới'),
            actions: [
              TextButton(
                onPressed: canSubmit
                    ? () {
                  context.read<UploadVideoBloc>().add(
                    StartUploadEvent(
                      userId: FirebaseAuth.instance.currentUser?.uid ?? 'guest',
                    ),
                  );
                }
                    : null,
                child: isUploading
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Text('Đăng'),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildPreview(state),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                maxLength: 150,
                decoration: const InputDecoration(
                  hintText: 'Tiêu đề...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => context
                    .read<UploadVideoBloc>()
                    .add(UpdateUploadFormEvent(title: value)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                minLines: 3,
                maxLines: 4,
                maxLength: 500,
                decoration: const InputDecoration(
                  hintText: 'Thêm mô tả, hashtag #... ',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) => context
                    .read<UploadVideoBloc>()
                    .add(UpdateUploadFormEvent(description: value)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: state.categoryId.isEmpty ? null : state.categoryId,
                decoration: const InputDecoration(
                  labelText: 'Danh mục',
                  border: OutlineInputBorder(),
                ),
                items: _categoryItems,
                onChanged: (value) => context
                    .read<UploadVideoBloc>()
                    .add(UpdateUploadFormEvent(categoryId: value ?? '')),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<VideoVisibility>(
                value: state.visibility,
                decoration: const InputDecoration(
                  labelText: 'Chế độ hiển thị',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: VideoVisibility.public,
                    child: Text('Công khai'),
                  ),
                  DropdownMenuItem(
                    value: VideoVisibility.private,
                    child: Text('Riêng tư'),
                  ),
                  DropdownMenuItem(
                    value: VideoVisibility.friendsOnly,
                    child: Text('Bạn bè'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  context
                      .read<UploadVideoBloc>()
                      .add(UpdateUploadFormEvent(visibility: value));
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Cho phép bình luận'),
                value: state.allowComment,
                onChanged: (value) => context
                    .read<UploadVideoBloc>()
                    .add(UpdateUploadFormEvent(allowComment: value)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Cho phép Duet / Stitch'),
                value: state.allowDuet,
                onChanged: (value) => context
                    .read<UploadVideoBloc>()
                    .add(UpdateUploadFormEvent(allowDuet: value)),
              ),
              if (isUploading) ...[
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: uploadState!.progress / 100,
                ),
                const SizedBox(height: 6),
                Text('Đang upload... ${uploadState!.progress}%'),
              ],
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: isUploading
                    ? () => context
                    .read<UploadVideoBloc>()
                    .add(const CancelUploadEvent())
                    : null,
                icon: const Icon(Icons.close),
                label: const Text('Huỷ'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreview(UploadVideoState state) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.black12,
        border: Border.all(color: Colors.white24),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _showPickOptions,
        child: state.video == null
            ? const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.video_call_outlined, size: 42),
              SizedBox(height: 8),
              Text('Chọn video (thư viện / camera)'),
            ],
          ),
        )
            : Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_previewController != null &&
                        _previewController!.value.isInitialized)
                      FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _previewController!.value.size.width,
                          height: _previewController!.value.size.height,
                          child: VideoPlayer(_previewController!),
                        ),
                      )
                    else
                      const ColoredBox(color: Colors.black26),
                    Center(
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          onPressed: () {
                            if (_previewController == null) return;
                            setState(() {
                              if (_previewController!.value.isPlaying) {
                                _previewController!.pause();
                              } else {
                                _previewController!.play();
                              }
                            });
                          },
                          icon: Icon(
                            _previewController?.value.isPlaying == true
                                ? Icons.pause
                                : Icons.play_arrow,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: FilledButton.tonalIcon(
                        onPressed: _showPickOptions,
                        icon: const Icon(Icons.photo_camera_back_outlined),
                        label: const Text('Chọn ảnh bìa'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '${state.video!.fileName} • ${state.video!.formattedSize} • ${state.video!.formattedDuration}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}