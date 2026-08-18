import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'audio_recorder.dart';

/// 使用 `record` 插件录制 16kHz / 16bit / 单声道 raw PCM 并交付字节。
final class RecordAudioRecorder implements AudioRecorderPort {
  RecordAudioRecorder({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  static const int sampleRate = 16000;
  static const int numChannels = 1;

  final AudioRecorder _recorder;
  bool _disposed = false;
  String? _activePath;

  @override
  Future<bool> hasPermission() async {
    _ensureUsable();
    try {
      return await _recorder.hasPermission();
    } on Object {
      return false;
    }
  }

  @override
  Future<void> start() async {
    _ensureUsable();
    if (_activePath != null) {
      throw const AudioRecordingException('already_recording', '录音已在进行中');
    }
    final temporaryDirectory = await getTemporaryDirectory();
    final path = p.join(
      temporaryDirectory.path,
      'pronunciation-$pid-${DateTime.now().microsecondsSinceEpoch}.pcm',
    );
    try {
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: sampleRate,
          numChannels: numChannels,
        ),
        path: path,
      );
      _activePath = path;
    } on Object {
      throw const AudioRecordingException('start_failed', '无法开始录音');
    }
  }

  @override
  Future<RecordedAudio> stop() async {
    _ensureUsable();
    final path = _activePath;
    _activePath = null;
    if (path == null) {
      throw const AudioRecordingException('not_recording', '当前没有进行中的录音');
    }
    try {
      final stoppedPath = await _recorder.stop();
      final file = File(stoppedPath ?? path);
      final Uint8List bytes;
      try {
        bytes = await file.readAsBytes();
      } finally {
        try {
          if (await file.exists()) {
            await file.delete();
          }
        } on FileSystemException {
          // 临时文件残留由系统清理。
        }
      }
      if (bytes.isEmpty) {
        throw const AudioRecordingException('empty_recording', '录音为空，请重试');
      }
      return RecordedAudio(pcmBytes: bytes);
    } on AudioRecordingException {
      rethrow;
    } on Object {
      throw const AudioRecordingException('stop_failed', '结束录音失败');
    }
  }

  @override
  Future<void> cancel() async {
    _ensureUsable();
    final path = _activePath;
    _activePath = null;
    if (path == null) {
      return;
    }
    try {
      await _recorder.cancel();
    } on Object {
      // 取消失败不影响后续录音。
    } finally {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } on FileSystemException {
        // 临时文件残留由系统清理。
      }
    }
  }

  @override
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    try {
      await _recorder.dispose();
    } on Object {
      // 释放阶段忽略插件错误。
    }
  }

  void _ensureUsable() {
    if (_disposed) {
      throw const AudioRecordingException('disposed', '录音服务已释放');
    }
  }
}
