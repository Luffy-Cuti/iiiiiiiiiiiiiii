import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/notification_service.dart';

abstract class UploadEvent {
  const UploadEvent();
}

class StartUpload extends UploadEvent {
  const StartUpload();
}

class _UploadTick extends UploadEvent {
  const _UploadTick(this.progress);

  final int progress;
}

class UploadState {
  const UploadState({required this.progress, required this.isUploading});

  final int progress;
  final bool isUploading;

  const UploadState.initial() : this(progress: 0, isUploading: false);

  UploadState copyWith({int? progress, bool? isUploading}) {
    return UploadState(
      progress: progress ?? this.progress,
      isUploading: isUploading ?? this.isUploading,
    );
  }
}

class UploadBloc extends Bloc<UploadEvent, UploadState> {
  UploadBloc() : super(const UploadState.initial()) {
    on<StartUpload>(_onStartUpload);
    on<_UploadTick>(_onUploadTick);
  }

  Timer? _timer;

  Future<void> _onStartUpload(StartUpload event, Emitter<UploadState> emit) async {
    if (state.isUploading) return;

    emit(state.copyWith(progress: 0, isUploading: true));
    await NotificationService.instance.showUploadProgress(0);

    _timer?.cancel();
    var progress = 0;
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      progress += 10;
      add(_UploadTick(progress));
      if (progress >= 100) {
        timer.cancel();
      }
    });
  }

  Future<void> _onUploadTick(_UploadTick event, Emitter<UploadState> emit) async {
    final clamped = event.progress.clamp(0, 100);
    await NotificationService.instance.showUploadProgress(clamped);
    emit(state.copyWith(progress: clamped, isUploading: clamped < 100));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}