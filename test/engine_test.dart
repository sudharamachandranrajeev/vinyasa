import 'package:flutter_test/flutter_test.dart';
import 'package:vinyasa/domain/analysis.dart';
import 'package:vinyasa/domain/catalog.dart';
import 'package:vinyasa/domain/planner.dart';
import 'package:vinyasa/domain/samples.dart';
import 'package:vinyasa/domain/space.dart';
import 'package:vinyasa/domain/steps.dart';

void main() {
  test('sample rooms: findings, plan, steps', () {
    for (final room in [sampleBedroom('b'), sampleLiving('l'), sampleKitchen('k')]) {
      final r = analyse(room);
      // ignore: avoid_print
      print('${room.name}: ${r.overall} ${r.scores.map((k, v) => MapEntry(k.name, v))}');
      for (final f in r.findings) {
        // ignore: avoid_print
        print('  ${f.severity.name} ${f.rule}: ${f.title}');
      }
      final sw = Stopwatch()..start();
      final plan = arrange(room);
      // ignore: avoid_print
      print('  plan ${plan.after.overall} in ${sw.elapsedMilliseconds} ms');
      for (final f in plan.after.findings) {
        // ignore: avoid_print
        print('    left ${f.severity.name} ${f.rule}: ${f.title}');
      }
      for (final s in stepsFor(plan)) {
        // ignore: avoid_print
        print('    step: ${s.title} — ${s.detail}');
      }
      expect(Room.decode(room.encode()).encode(), room.encode());
    }
  });

  Set<String> rules(Room r) => {for (final f in analyse(r).findings) f.rule};
  Item item(String id, String kind, int x, int y) {
    final k = itemKind(kind);
    return Item(id: id, kind: kind, x: x, y: y, w: k.w, d: k.d, h: k.h);
  }

  test('a light within reach of the bed, a must for older sleepers', () {
    final bedroom = sampleBedroom('b');
    expect(rules(bedroom), isNot(contains('bed-lamp-reach')));
    final dark = bedroom.copyWith(
      items: bedroom.items.where((i) => !i.id.startsWith('ns')).toList(),
      occupants: bedroom.occupants.copyWith(elderly: true),
    );
    final f = analyse(dark).findings.firstWhere((f) => f.rule == 'bed-lamp-reach');
    expect(f.severity, Severity.must);
  });

  test('seats too far apart to talk', () {
    final living = sampleLiving('l');
    expect(rules(living), isNot(contains('talk-distance')));
    final apart = living.copyWith(
      width: 9000,
      items: [item('sofa', 'sofa_3', 0, 0), item('arm', 'armchair', 6000, 0)],
    );
    expect(rules(apart), contains('talk-distance'));
  });
}
