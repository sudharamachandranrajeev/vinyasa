/// The room's floor as a grid of cells: which are covered, how far each free
/// cell is from the nearest obstacle, and which cells a person can reach
/// from the doors through a path of a given width. Rules ask it about
/// circulation; the planner asks it thousands of times, so it stays plain
/// arrays and integer maths.
library;

import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'space.dart';

class FloorGrid {
  FloorGrid._(this.room, this.cell, this.cols, this.rows, this._dist);

  /// Builds the grid with [cell]-millimetre cells, or a size that keeps a
  /// large room (a warehouse) under about 150 cells a side.
  factory FloorGrid.of(Room room, {int? cell}) {
    final size = cell ?? math.max(50, (math.max(room.width, room.depth) / 150).ceil());
    final cols = (room.width / size).ceil(), rows = (room.depth / size).ceil();
    // Distances in tenths of a cell: 10 straight, 14 diagonal (a chamfer
    // transform, within 8% of true distance).
    const far = 1 << 28;
    final dist = Int32List(cols * rows)..fillRange(0, cols * rows, far);
    for (final item in room.items) {
      if (!item.spec.blocks) continue;
      final b = item.box;
      final c0 = (b.x / size).floor().clamp(0, cols), c1 = (b.right / size).ceil().clamp(0, cols);
      final r0 = (b.y / size).floor().clamp(0, rows), r1 = (b.bottom / size).ceil().clamp(0, rows);
      for (var r = r0; r < r1; r++) {
        dist.fillRange(r * cols + c0, r * cols + c1, 0);
      }
    }
    // Walls are obstacles just outside the grid: seed the edge cells with
    // half a cell to the wall.
    int at(int c, int r) => dist[r * cols + c];
    void set(int c, int r, int v) {
      if (v < dist[r * cols + c]) dist[r * cols + c] = v;
    }

    for (var c = 0; c < cols; c++) {
      set(c, 0, 5);
      set(c, rows - 1, 5);
    }
    for (var r = 0; r < rows; r++) {
      set(0, r, 5);
      set(cols - 1, r, 5);
    }
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        var v = at(c, r);
        if (v == 0) continue;
        if (c > 0) v = math.min(v, at(c - 1, r) + 10);
        if (r > 0) {
          v = math.min(v, at(c, r - 1) + 10);
          if (c > 0) v = math.min(v, at(c - 1, r - 1) + 14);
          if (c < cols - 1) v = math.min(v, at(c + 1, r - 1) + 14);
        }
        dist[r * cols + c] = v;
      }
    }
    for (var r = rows - 1; r >= 0; r--) {
      for (var c = cols - 1; c >= 0; c--) {
        var v = at(c, r);
        if (v == 0) continue;
        if (c < cols - 1) v = math.min(v, at(c + 1, r) + 10);
        if (r < rows - 1) {
          v = math.min(v, at(c, r + 1) + 10);
          if (c < cols - 1) v = math.min(v, at(c + 1, r + 1) + 14);
          if (c > 0) v = math.min(v, at(c - 1, r + 1) + 14);
        }
        dist[r * cols + c] = v;
      }
    }
    return FloorGrid._(room, size, cols, rows, dist);
  }

  final Room room;
  final int cell, cols, rows;
  final Int32List _dist;
  final _reach = <int, Uint8List>{};

  bool _inside(int c, int r) => c >= 0 && r >= 0 && c < cols && r < rows;

  /// Clear distance from the cell's centre to the nearest obstacle or wall,
  /// in millimetres; 0 for a covered cell.
  int clearance(int c, int r) => _inside(c, r) ? _dist[r * cols + c] * cell ~/ 10 : 0;

  /// Share of the floor not covered by anything that blocks walking.
  double get freeShare {
    var free = 0;
    for (final v in _dist) {
      if (v > 0) free++;
    }
    return free / _dist.length;
  }

  /// The largest clear circle anywhere, as its diameter in millimetres
  /// (where a wheelchair could turn), and where.
  ({int diameter, int c, int r}) widestSpot({Uint8List? within}) {
    var best = 0, bc = 0, br = 0;
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        final i = r * cols + c;
        if (within != null && within[i] == 0) continue;
        if (_dist[i] > best) {
          best = _dist[i];
          bc = c;
          br = r;
        }
      }
    }
    return (diameter: best * cell ~/ 5, c: bc, r: br);
  }

  /// Cells just inside each passable opening: where people come in.
  List<(int, int)> entries() {
    final out = <(int, int)>[];
    for (final o in room.openings.where((o) => o.kind.passable)) {
      final from = (o.offset / cell).floor(), to = ((o.offset + o.width) / cell).ceil();
      for (var k = from; k < to; k++) {
        final (c, r) = switch (o.wall) {
          Wall.top => (k, 0),
          Wall.bottom => (k, rows - 1),
          Wall.left => (0, k),
          Wall.right => (cols - 1, k),
        };
        if (_inside(c, r)) out.add((c, r));
      }
    }
    return out;
  }

  /// Cells reachable from any door through a path at least [width] mm wide,
  /// as a mask (1 = reached). With no doors, the widest open spot stands in.
  Uint8List reachable(int width) => _reach.putIfAbsent(width, () {
    // The path's centre line must keep half the width clear on each side.
    final need = width * 5 ~/ cell; // half width, in tenths of a cell
    final seen = Uint8List(cols * rows);
    final queue = Queue<int>();
    var starts = entries();
    if (starts.isEmpty) {
      final w = widestSpot();
      starts = [(w.c, w.r)];
    }
    for (final (c, r) in starts) {
      // A door is as wide as it is: from the doorway, step in until the
      // path is wide enough, so a narrow door does not hide the whole room.
      final i = r * cols + c;
      if (_dist[i] > 0 && seen[i] == 0) {
        seen[i] = 1;
        queue.add(i);
      }
    }
    // The first steps in from a door may be narrower than [width] (the door
    // itself is); they are allowed for one door's depth.
    final grace = math.max(1, 600 ~/ cell);
    final depth = Int32List(cols * rows);
    while (queue.isNotEmpty) {
      final i = queue.removeFirst();
      final c = i % cols, r = i ~/ cols;
      for (final (dc, dr) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        final nc = c + dc, nr = r + dr;
        if (!_inside(nc, nr)) continue;
        final n = nr * cols + nc;
        if (seen[n] == 1 || _dist[n] == 0) continue;
        final d = depth[i] + 1;
        if (_dist[n] < need && d > grace) continue;
        seen[n] = 1;
        depth[n] = _dist[n] >= need ? grace + 1 : d;
        queue.add(n);
      }
    }
    return seen;
  });

  /// Whether any reached cell of [mask] lies in [box].
  bool touches(Uint8List mask, Box box) {
    final c0 = (box.x / cell).floor().clamp(0, cols), c1 = (box.right / cell).ceil().clamp(0, cols);
    final r0 = (box.y / cell).floor().clamp(0, rows), r1 = (box.bottom / cell).ceil().clamp(0, rows);
    for (var r = r0; r < r1; r++) {
      for (var c = c0; c < c1; c++) {
        if (mask[r * cols + c] == 1) return true;
      }
    }
    return false;
  }

  /// Share of [box]'s area (inside the room) that nothing blocks.
  double clearShare(Box box) {
    final c0 = (box.x / cell).floor().clamp(0, cols), c1 = (box.right / cell).ceil().clamp(0, cols);
    final r0 = (box.y / cell).floor().clamp(0, rows), r1 = (box.bottom / cell).ceil().clamp(0, rows);
    // Cells of the box that fall outside the room count as blocked: a
    // wall is in the way.
    final wanted = math.max(1, (box.w / cell).ceil() * (box.d / cell).ceil());
    var free = 0;
    for (var r = r0; r < r1; r++) {
      for (var c = c0; c < c1; c++) {
        if (_dist[r * cols + c] > 0) free++;
      }
    }
    return math.min(1, free / wanted);
  }
}
