import 'dart:io';

import 'package:brahma_core/brahma_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:vinyasa/app/scan_media.dart';
import 'package:vinyasa/db/database.dart';

MediaRow _row(String path, String kind) => MediaRow(id: path, room: 'r', path: path, kind: kind, added: '');

void main() {
  late Directory dir;
  setUp(() async => dir = await Directory.systemTemp.createTemp('vinyasa-media-'));
  tearDown(() => dir.delete(recursive: true));

  test('photos are cleaned; missing files are skipped', () async {
    final photo = File('${dir.path}/a.jpg')
      ..writeAsBytesSync(img.encodeJpg(img.Image(width: 3000, height: 2000)));
    final out = await prepareMedia([
      _row(photo.path, 'photo'),
      _row('${dir.path}/gone.jpg', 'photo'),
    ], wholeVideo: false);
    expect(out, hasLength(1));
    expect(img.decodeJpg(out.single.bytes)!.width, 2576);
  });

  test('videos: whole for Gemini, frames through ffmpeg otherwise', () async {
    final ffmpeg = locateTool('ffmpeg');
    if (ffmpeg == null) {
      markTestSkipped('ffmpeg is not installed');
      return;
    }
    final video = '${dir.path}/turn.mp4';
    final made = await Process.run(ffmpeg, [
      '-v', 'error', '-f', 'lavfi', '-i', 'testsrc=duration=10:size=1920x1080:rate=10', //
      '-pix_fmt', 'yuv420p', video,
    ]);
    expect(made.exitCode, 0, reason: '${made.stderr}');
    final whole = await prepareMedia([_row(video, 'video')], wholeVideo: true);
    expect(whole.single.mime, 'video/mp4');
    final frames = await prepareMedia([_row(video, 'video')], wholeVideo: false);
    expect(frames.length, inInclusiveRange(3, 4), reason: 'one every 3 s of 10 s');
    final first = img.decodeJpg(frames.first.bytes)!;
    expect((first.width, first.height), (1600, 900));
  });
}
