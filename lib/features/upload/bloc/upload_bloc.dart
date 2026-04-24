import 'dart:async';
import 'dart:io';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';

import '../../../core/services/notification_service.dart';

enum VideoVisibility { public, private, friendsOnly }

class PickedVideo {
  const PickedVideo({
    required this.file,
    required this.fileName,
    required this.fileSizeInBytes,
    required this.duration,
    this.thumbnailTimestamp = Duration.zero,
  });

  final File file;
  final String fileName;
  final int fileSizeInBytes;
  final Duration duration;
  final Duration thumbnailTimestamp;

  String get formattedSize {
    const kb = 1024;
    const mb = kb * 1024;
    if (fileSizeInBytes < mb) {
      return '${(fileSizeInBytes / kb).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeInBytes / mb).toStringAsFixed(1)} MB';
  }

  String get formattedDuration {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

abstract class UploadVideoEvent {
  const UploadVideoEvent();
}

class PickVideoEvent extends UploadVideoEvent {
  const PickVideoEvent({required this.file});

  final File file;
}

class ValidateVideoEvent extends UploadVideoEvent {
  const ValidateVideoEvent();
}

class StartUploadEvent extends UploadVideoEvent {
  const StartUploadEvent({required this.userId});

  final String userId;
}

class PauseUploadEvent extends UploadVideoEvent {
  const PauseUploadEvent();
}

class CancelUploadEvent extends UploadVideoEvent {
  const CancelUploadEvent();
}

class RetryUploadEvent extends UploadVideoEvent {
  const RetryUploadEvent();
}

class UpdateUploadFormEvent extends UploadVideoEvent {
  const UpdateUploadFormEvent({
    this.title,
    this.description,
    this.categoryId,
    this.visibility,
    this.allowComment,
    this.allowDuet,
    this.thumbnailTimestamp,
  });

  final String? title;
  final String? description;
  final String? categoryId;
  final VideoVisibility? visibility;
  final bool? allowComment;
  final bool? allowDuet;
  final Duration? thumbnailTimestamp;
}

class _UploadTickEvent extends UploadVideoEvent {
  const _UploadTickEvent({required this.progress});

  final int progress;
}

abstract class UploadVideoState {
  const UploadVideoState({
    required this.video,
    required this.title,
    required this.description,
    required this.categoryId,
    required this.visibility,
    required this.allowComment,
    required this.allowDuet,
    required this.thumbnailTimestamp,
  });

  final PickedVideo? video;
  final String title;
  final String description;
  final String categoryId;
  final VideoVisibility visibility;
  final bool allowComment;
  final bool allowDuet;
  final Duration thumbnailTimestamp;

  bool get isReadyToUpload => video != null && title.trim().isNotEmpty;
}

class UploadInitial extends UploadVideoState {
  const UploadInitial()
      : super(
    video: null,
    title: '',
    description: '',
    categoryId: '',
    visibility: VideoVisibility.public,
    allowComment: true,
    allowDuet: true,
    thumbnailTimestamp: Duration.zero,
  );
}

class UploadVideoPickedState extends UploadVideoState {
  const UploadVideoPickedState({
    required super.video,
    required super.title,
    required super.description,
    required super.categoryId,
    required super.visibility,
    required super.allowComment,
    required super.allowDuet,
    required super.thumbnailTimestamp,
  });
}

class UploadVideoValidatingState extends UploadVideoState {
  const UploadVideoValidatingState({
    required super.video,
    required super.title,
    required super.description,
    required super.categoryId,
    required super.visibility,
    required super.allowComment,
    required super.allowDuet,
    required super.thumbnailTimestamp,
  });
}

class UploadVideoValidatedState extends UploadVideoState {
  const UploadVideoValidatedState({
    required super.video,
    required super.title,
    required super.description,
    required super.categoryId,
    required super.visibility,
    required super.allowComment,
    required super.allowDuet,
    required super.thumbnailTimestamp,
  });
}

class UploadInProgressState extends UploadVideoState {
  const UploadInProgressState({
    required this.progress,
    required super.video,
    required super.title,
    required super.description,
    required super.categoryId,
    required super.visibility,
    required super.allowComment,
    required super.allowDuet,
    required super.thumbnailTimestamp,
  });

  final int progress;
}

class UploadSuccessState extends UploadVideoState {
  const UploadSuccessState({
    required this.videoId,
    required super.video,
    required super.title,
    required super.description,
    required super.categoryId,
    required super.visibility,
    required super.allowComment,
    required super.allowDuet,
    required super.thumbnailTimestamp,
  });

  final String videoId;
}

class UploadFailureState extends UploadVideoState {
  const UploadFailureState({
    required this.message,
    required super.video,
    required super.title,
    required super.description,
    required super.categoryId,
    required super.visibility,
    required super.allowComment,
    required super.allowDuet,
    required super.thumbnailTimestamp,
  });

  final String message;
}

class UploadCancelledState extends UploadVideoState {
  const UploadCancelledState({
    required super.video,
    required super.title,
    required super.description,
    required super.categoryId,
    required super.visibility,
    required super.allowComment,
    required super.allowDuet,
    required super.thumbnailTimestamp,
  });
}

class UploadVideoBloc extends Bloc<UploadVideoEvent, UploadVideoState> {
  UploadVideoBloc() : super(const UploadInitial()) {
    on<PickVideoEvent>(_onPickVideo);
    on<ValidateVideoEvent>(_onValidateVideo);
    on<UpdateUploadFormEvent>(_onUpdateForm);
    on<StartUploadEvent>(_onStartUpload);
    on<PauseUploadEvent>(_onPauseUpload);
    on<CancelUploadEvent>(_onCancelUpload);
    on<RetryUploadEvent>(_onRetryUpload);
    on<_UploadTickEvent>(_onUploadTick);
  }

  static const _maxVideoSizeBytes = 500 * 1024 * 1024;
  static const _minVideoDuration = Duration(seconds: 15);
  static const _maxVideoDuration = Duration(minutes: 10);

  Timer? _uploadTimer;
  int _lastProgress = 0;

  Future<void> _onPickVideo(
      PickVideoEvent event,
      Emitter<UploadVideoState> emit,
      ) async {
    try {
      final picked = await _toPickedVideo(event.file);
      emit(_pickedState(video: picked));
      add(const ValidateVideoEvent());
    } catch (error, stack) {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: 'pick_video_failed',
        fatal: false,
      );
      emit(_failureState('Không thể đọc video đã chọn.'));
    }
  }

  Future<void> _onUpdateForm(
      UpdateUploadFormEvent event,
      Emitter<UploadVideoState> emit,
      ) async {
    emit(
      UploadVideoPickedState(
        video: state.video,
        title: event.title ?? state.title,
        description: event.description ?? state.description,
        categoryId: event.categoryId ?? state.categoryId,
        visibility: event.visibility ?? state.visibility,
        allowComment: event.allowComment ?? state.allowComment,
        allowDuet: event.allowDuet ?? state.allowDuet,
        thumbnailTimestamp: event.thumbnailTimestamp ?? state.thumbnailTimestamp,
      ),
    );
  }

  Future<void> _onValidateVideo(
      ValidateVideoEvent event,
      Emitter<UploadVideoState> emit,
      ) async {
    emit(_validatingState());

    final validationError = _validateAll();
    if (validationError != null) {
      await FirebaseCrashlytics.instance.recordError(
        Exception(validationError),
        StackTrace.current,
        reason: 'validate_video_failed',
        fatal: false,
      );
      emit(_failureState(validationError));
      return;
    }

    emit(
      UploadVideoValidatedState(
        video: state.video,
        title: state.title,
        description: state.description,
        categoryId: state.categoryId,
        visibility: state.visibility,
        allowComment: state.allowComment,
        allowDuet: state.allowDuet,
        thumbnailTimestamp: state.thumbnailTimestamp,
      ),
    );
  }

  Future<void> _onStartUpload(
      StartUploadEvent event,
      Emitter<UploadVideoState> emit,
      ) async {
    final validationError = _validateAll();
    if (validationError != null) {
      emit(_failureState(validationError));
      return;
    }

    final video = state.video;
    if (video == null) {
      emit(_failureState('Video không hợp lệ.'));
      return;
    }

    await _setCrashlyticsKeys(userId: event.userId, video: video);

    _uploadTimer?.cancel();
    _lastProgress = 0;
    emit(_progressState(progress: 0));
    await NotificationService.instance.showUploadProgress(0);

    _uploadTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      _lastProgress += 5;
      add(_UploadTickEvent(progress: _lastProgress));
      if (_lastProgress >= 100) {
        timer.cancel();
      }
    });
  }

  Future<void> _onUploadTick(
      _UploadTickEvent event,
      Emitter<UploadVideoState> emit,
      ) async {
    final clamped = event.progress.clamp(0, 100);
    try {
      emit(_progressState(progress: clamped));
      await NotificationService.instance.showUploadProgress(clamped);

      if (clamped >= 100) {
        final videoId = 'vid_${DateTime.now().millisecondsSinceEpoch}';
        await NotificationService.instance.showUploadSuccess();
        emit(
          UploadSuccessState(
            videoId: videoId,
            video: state.video,
            title: state.title,
            description: state.description,
            categoryId: state.categoryId,
            visibility: state.visibility,
            allowComment: state.allowComment,
            allowDuet: state.allowDuet,
            thumbnailTimestamp: state.thumbnailTimestamp,
          ),
        );
      }
    } catch (error, stack) {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: 'upload_tick_failed',
        fatal: true,
      );
      emit(_failureState('Upload thất bại do lỗi hệ thống.'));
    }
  }

  Future<void> _onPauseUpload(
      PauseUploadEvent event,
      Emitter<UploadVideoState> emit,
      ) async {
    _uploadTimer?.cancel();
    emit(_pickedState());
  }

  Future<void> _onCancelUpload(
      CancelUploadEvent event,
      Emitter<UploadVideoState> emit,
      ) async {
    _uploadTimer?.cancel();
    _lastProgress = 0;
    await NotificationService.instance.showUploadCancelled();
    emit(
      UploadCancelledState(
        video: state.video,
        title: state.title,
        description: state.description,
        categoryId: state.categoryId,
        visibility: state.visibility,
        allowComment: state.allowComment,
        allowDuet: state.allowDuet,
        thumbnailTimestamp: state.thumbnailTimestamp,
      ),
    );
  }

  Future<void> _onRetryUpload(
      RetryUploadEvent event,
      Emitter<UploadVideoState> emit,
      ) async {
    add(const StartUploadEvent(userId: 'retry_user'));
  }

  UploadVideoPickedState _pickedState({PickedVideo? video}) {
    return UploadVideoPickedState(
      video: video ?? state.video,
      title: state.title,
      description: state.description,
      categoryId: state.categoryId,
      visibility: state.visibility,
      allowComment: state.allowComment,
      allowDuet: state.allowDuet,
      thumbnailTimestamp: state.thumbnailTimestamp,
    );
  }

  UploadVideoValidatingState _validatingState() {
    return UploadVideoValidatingState(
      video: state.video,
      title: state.title,
      description: state.description,
      categoryId: state.categoryId,
      visibility: state.visibility,
      allowComment: state.allowComment,
      allowDuet: state.allowDuet,
      thumbnailTimestamp: state.thumbnailTimestamp,
    );
  }

  UploadInProgressState _progressState({required int progress}) {
    return UploadInProgressState(
      progress: progress,
      video: state.video,
      title: state.title,
      description: state.description,
      categoryId: state.categoryId,
      visibility: state.visibility,
      allowComment: state.allowComment,
      allowDuet: state.allowDuet,
      thumbnailTimestamp: state.thumbnailTimestamp,
    );
  }

  UploadFailureState _failureState(String message) {
    unawaited(NotificationService.instance.showUploadFailure());
    return UploadFailureState(
      message: message,
      video: state.video,
      title: state.title,
      description: state.description,
      categoryId: state.categoryId,
      visibility: state.visibility,
      allowComment: state.allowComment,
      allowDuet: state.allowDuet,
      thumbnailTimestamp: state.thumbnailTimestamp,
    );
  }

  String? _validateAll() {
    final video = state.video;
    if (video == null) {
      return 'Vui lòng chọn video trước khi đăng.';
    }

    if (video.fileSizeInBytes > _maxVideoSizeBytes) {
      return 'Dung lượng video tối đa 500MB.';
    }

    if (video.duration < _minVideoDuration || video.duration > _maxVideoDuration) {
      return 'Thời lượng video phải từ 15 giây đến 10 phút.';
    }

    final title = state.title.trim();
    if (title.isEmpty || title.length > 150) {
      return 'Tiêu đề bắt buộc và tối đa 150 ký tự.';
    }

    if (state.description.length > 500) {
      return 'Mô tả tối đa 500 ký tự.';
    }

    return null;
  }

  Future<void> _setCrashlyticsKeys({
    required String userId,
    required PickedVideo video,
  }) async {
    await FirebaseCrashlytics.instance.setCustomKey('userId', userId);
    await FirebaseCrashlytics.instance
        .setCustomKey('videoSize', video.fileSizeInBytes);
    await FirebaseCrashlytics.instance
        .setCustomKey('videoDuration', video.duration.inSeconds);
    await FirebaseCrashlytics.instance.setCustomKey('categoryId', state.categoryId);
  }

  Future<PickedVideo> _toPickedVideo(File file) async {
    final fileName = file.uri.pathSegments.isEmpty
        ? 'video.mp4'
        : file.uri.pathSegments.last;
    final fileSizeInBytes = await file.length();

    final controller = VideoPlayerController.file(file);
    await controller.initialize();
    final duration = controller.value.duration;
    await controller.dispose();

    return PickedVideo(
      file: file,
      fileName: fileName,
      fileSizeInBytes: fileSizeInBytes,
      duration: duration,
      thumbnailTimestamp: Duration.zero,
    );
  }

  @override
  Future<void> close() {
    _uploadTimer?.cancel();
    return super.close();
  }
}