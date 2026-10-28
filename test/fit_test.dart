import 'package:flutter_test/flutter_test.dart';
import 'package:vinyasa/domain/fit.dart';
import 'package:vinyasa/domain/samples.dart';
import 'package:vinyasa/domain/space.dart';

Item piece(String kind, {int? w, int? d, int? h}) =>
    Item.fromJson({'id': 'new', 'kind': kind, 'x': 0, 'y': 0, 'w': ?w, 'd': ?d, 'h': ?h});

void main() {
  test('a bookshelf finds places against a wall, clear of everything, best first', () {
    final room = sampleBedroom('r');
    final watch = Stopwatch()..start();
    final fit = findFit(room, piece('bookshelf'));
    // Debug-mode tests are slow; a release build is several times faster.
    expect(watch.elapsedMilliseconds, lessThan(8000));
    expect(fit.spots, isNotEmpty);
    for (final s in fit.spots) {
      final b = s.item.box;
      expect(b.x >= 0 && b.y >= 0 && b.right <= room.width && b.bottom <= room.depth, isTrue);
      for (final other in room.items.where((i) => i.spec.blocks)) {
        expect(b.overlaps(other.box), isFalse, reason: '${s.item.box} on ${other.kind}');
      }
      final swing = doorSwing(room, room.openings.first)!;
      expect(b.overlaps(swing), isFalse);
      expect(s.room.items, hasLength(room.items.length + 1));
    }
    final deltas = [for (final s in fit.spots) s.delta];
    expect(deltas, [...deltas]..sort());
  });

  test('a piece too big for the room has nowhere to go', () {
    final fit = findFit(sampleBedroom('r'), piece('sofa_3', w: 5000));
    expect(fit.spots, isEmpty);
  });

  test('the door check: on its side, tilted, or not at all', () {
    final room = sampleBedroom('r'); // one 900 mm door
    expect(throughDoor(room, 2000, 800, 900).fits, isTrue);
    final tilted = throughDoor(room, 2100, 850, 2150);
    expect((tilted.fits, tilted.text.contains('tilted')), (true, true));
    expect(throughDoor(room, 1000, 1000, 2000).fits, isFalse);
    expect(throughDoor(room, 3000, 800, 2500).fits, isFalse);
    expect(throughDoor(room.copyWith(openings: const []), 5000, 5000, 5000).fits, isTrue);
  });
}
