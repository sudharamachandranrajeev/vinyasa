import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:brahma_core/brahma_core.dart';
import 'package:flutter/services.dart';

import '../db/database.dart';
import '../domain/photo_prep.dart';
import '../domain/vision.dart';

/// Video types Gemini takes as they are; others are sent as frames.
const _videoMime = {
  'mp4': 'video/mp4',
  'mov': 'video/quicktime',
  'webm': 'video/webm',
  '3gp': 'video/3gpp',
  'avi': 'video/x-msvideo',
};

/// At most this many pictures go in one request: enough to see a room,
/// few enough to keep the request small and the cost low.
const maxImages = 16;

/// Frames taken from each video.
const _framesPerVideo = 8;

/// The room's [media] made ready to send: photos cleaned (photo_prep.dart),
/// videos sent whole when [wholeVideo] allows and they are small enough,
/// otherwise as frames. [step] reports what is being done.
Future<List<VisionMedia>> prepareMedia(
  List<MediaRow> media, {
  required bool wholeVideo,
  void Function(String)? step,
}) async {
  final out = <VisionMedia>[];
  var noFrames = false;
  for (final m in media) {
    final room = maxImages - out.where((v) => !v.video).length;
    if (room <= 0) break;
    final file = File(m.path);
    if (!file.existsSync()) continue;
    if (m.kind != 'video') {
      step?.call('Preparing photo ${out.length + 1}');
      final bytes = await file.readAsBytes();
      final clean = await Isolate.run(() => cleanPhoto(bytes));
      if (clean != null) out.add(VisionMedia(clean, 'image/jpeg'));
      continue;
    }
    final mime = _videoMime[m.path.split('.').last.toLowerCase()];
    if (wholeVideo && mime != null && await file.length() < geminiInlineLimit * 3 ~/ 4) {
      out.add(VisionMedia(await file.readAsBytes(), mime));
      continue;
    }
    step?.call('Taking frames from a video');
    final frames = await _frames(m.path, math.min(room, _framesPerVideo));
    noFrames |= frames.isEmpty;
    out.addAll([for (final f in frames) VisionMedia(f, 'image/jpeg')]);
  }
  if (out.isEmpty && noFrames) {
    throw AskAiException(
      Platform.isAndroid
          ? 'No frames could be taken from the video. Add a few photos instead.'
          : 'Taking frames from a video needs the FFmpeg program (ffmpeg.org). '
                'Install it, or add a few photos instead.',
    );
  }
  return out;
}

/// Up to [count] JPEG frames through the video: Android's own decoder on
/// phones; on computers the ffmpeg program when it is installed. Nothing is
/// linked against FFmpeg, so the app runs the same without it.
Future<List<Uint8List>> _frames(String path, int count) async {
  try {
    if (Platform.isAndroid) {
      final frames = await const MethodChannel('dev.brahma.vinyasa/frames')
          .invokeListMethod<Uint8List>('frames', {'path': path, 'count': count, 'edge': 1600});
      return frames ?? const [];
    }
    return await _ffmpegFrames(path, count);
  } on Exception {
    return const [];
  }
}

Future<List<Uint8List>> _ffmpegFrames(String path, int count) async {
  final exe = locateTool('ffmpeg');
  if (exe == null) return const [];
  final dir = await Directory.systemTemp.createTemp('vinyasa-frames-');
  try {
    final process = await Process.start(exe, [
      '-v', 'error', //
      '-i', path,
      // One frame every 3 s, at most 1600 px on the long side.
      '-vf', "fps=1/3,scale='if(gt(iw,ih),min(1600,iw),-2)':'if(gt(iw,ih),-2,min(1600,ih))'",
      '-frames:v', '$count',
      '-q:v', '3',
      '${dir.path}${Platform.pathSeparator}f%02d.jpg',
    ]);
    unawaited(process.stdout.drain<void>());
    unawaited(process.stderr.drain<void>());
    await process.exitCode.timeout(
      const Duration(minutes: 1),
      onTimeout: () {
        process.kill();
        return -1;
      },
    );
    final files = dir.listSync().whereType<File>().toList()..sort((a, b) => a.path.compareTo(b.path));
    return [for (final f in files) await f.readAsBytes()];
  } finally {
    await dir.delete(recursive: true);
  }
}
