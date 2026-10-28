import 'package:flutter_test/flutter_test.dart';
import 'package:vinyasa/domain/samples.dart';
import 'package:vinyasa/domain/space.dart';
import 'package:vinyasa/domain/stored.dart';

Thing thing(String id, Stuff stuff, Use use, {bool heavy = false, String tagged = ''}) =>
    Thing(id: id, name: id, stuff: stuff, use: use, heavy: heavy, tagged: tagged);

Item unit(String id, String kind, {int x = 0, int y = 0}) =>
    Item.fromJson({'id': id, 'kind': kind, 'x': x, 'y': y});

Room room(List<Thing> things, {Occupants occupants = const Occupants(), RoomType type = RoomType.bedroom}) =>
    sampleBedroom('r').copyWith(
      items: [unit('w', 'wardrobe'), unit('s', 'shoe_rack', x: 2000)],
      things: things,
      occupants: occupants,
      type: type,
    );

void main() {
  test('daily clothes take an easy shelf and rare ones leave the easy shelves free', () {
    final plan = organise(
      room([thing('shirts', Stuff.clothes, Use.daily), thing('spare quilt', Stuff.clothes, Use.rare)]),
    );
    final daily = plan.placed.firstWhere((p) => p.thing.id == 'shirts');
    final rare = plan.placed.firstWhere((p) => p.thing.id == 'spare quilt');
    expect(daily.shelf.zone, Zone.prime);
    expect(rare.shelf.zone, isNot(Zone.prime));
  });

  test('shoes go on the shoe rack and nothing else goes there', () {
    final r = room([thing('boots', Stuff.shoes, Use.weekly), thing('mug', Stuff.kitchen, Use.daily)]);
    final plan = organise(r.copyWith(items: [...r.items, unit('c', 'cabinet', x: 1000)]));
    expect(plan.placed.firstWhere((p) => p.thing.id == 'boots').unit.item.kind, 'shoe_rack');
    expect(plan.placed.firstWhere((p) => p.thing.id == 'mug').unit.item.kind, isNot('shoe_rack'));
  });

  test('heavy things sit low, within reach, and never above 1100 mm', () {
    final plan = organise(
      room([
        thing('toolbox', Stuff.tools, Use.weekly, heavy: true),
        thing('jars', Stuff.kitchen, Use.rare, heavy: true),
      ]),
    );
    for (final p in plan.placed) {
      expect(p.shelf.top, lessThanOrEqualTo(1100), reason: p.thing.id);
      expect(p.shelf.zone.easy, isTrue, reason: p.thing.id);
    }
  });

  test('a wheelchair user gets shelves only inside 380–1220 mm for everyday things', () {
    final plan = organise(
      room([
        for (var i = 0; i < 8; i++) thing('d$i', Stuff.clothes, Use.daily),
      ], occupants: const Occupants(wheelchair: true)),
    );
    expect(plan.reach.okHigh, 1220);
    for (final p in plan.placed.where((p) => !p.compromise)) {
      expect(p.shelf.bottom + (p.shelf.top - p.shelf.bottom) / 2, inInclusiveRange(380, 1220));
    }
  });

  test('daily things sit nearer the door than rare ones', () {
    final r = sampleBedroom('r').copyWith(
      // The door is at the bottom left; one cabinet beside it and one far away.
      items: [unit('near', 'cabinet', x: 300, y: 2300), unit('far', 'cabinet', x: 2600, y: 100)],
      things: [thing('keys', Stuff.misc, Use.daily), thing('tax', Stuff.misc, Use.rare)],
    );
    final plan = organise(r);
    expect(plan.placed.firstWhere((p) => p.thing.id == 'keys').unit.item.id, 'near');
    expect(plan.placed.firstWhere((p) => p.thing.id == 'tax').unit.item.id, 'far');
  });

  test('things with no suitable storage are listed, and full shelves are not overfilled', () {
    final r = sampleBedroom('r').copyWith(
      items: [unit('shoes', 'shoe_rack')],
      things: [
        thing('book', Stuff.books, Use.daily),
        for (var i = 0; i < 40; i++) thing('s$i', Stuff.shoes, Use.weekly),
      ],
    );
    final plan = organise(r);
    expect(plan.unplaced.map((t) => t.id), contains('book'));
    final slots = plan.units.single.shelves.fold<int>(0, (n, s) => n + s.slots);
    expect(plan.placed.length, slots);
    expect(plan.unplaced.length, 41 - slots);
  });

  test('the method follows the room: KonMari at home, 5S at work, ABC in a storeroom', () {
    final things = [thing('a', Stuff.keepsakes, Use.rare), thing('b', Stuff.clothes, Use.daily)];
    final home = organise(room(things)).steps.first;
    expect(home.title, startsWith('Declutter'));
    expect(home.detail.indexOf('clothes'), lessThan(home.detail.indexOf('keepsakes')));

    final today = DateTime(2026, 10, 28);
    final work = organise(
      room([thing('x', Stuff.tools, Use.weekly, tagged: '2026-10-10')], type: RoomType.office),
      today: today,
    );
    expect(work.steps.first.title, startsWith('Sort'));
    expect(work.steps.first.detail, contains('1 overdue'));

    final stock = organise(room([thing('x', Stuff.stock, Use.daily)], type: RoomType.storeroom));
    expect(stock.steps.map((s) => s.title), contains(startsWith('Slot by')));
  });

  test('things survive the room’s JSON, and bad data is repaired', () {
    final r = room([thing('a', Stuff.books, Use.rare, heavy: true, tagged: '2026-10-01')]);
    final back = Room.decode(r.encode()).things.single;
    expect((back.stuff, back.use, back.heavy, back.tagged), (Stuff.books, Use.rare, true, '2026-10-01'));
    final odd = Thing.fromJson({'stuff': 'nonsense', 'use': 9, 'tagged': 'soon'});
    expect((odd.stuff, odd.use, odd.tagged), (Stuff.misc, Use.weekly, ''));
  });

  test('labels list every placed thing, escaped', () {
    final plan = organise(room([thing('<b>coat</b>', Stuff.clothes, Use.daily)]));
    expect(labelText(plan), contains('<b>coat</b>'));
    final html = labelSheet(plan, 'Bed & room');
    expect(html, contains('&lt;b&gt;coat&lt;/b&gt;'));
    expect(html, contains('Bed &amp; room'));
  });
}
