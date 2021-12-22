import 'dart:developer';

import 'dart:math';

import 'package:flutter/material.dart';

abstract class Edge {
  Polygon get leftFace;
  Polygon get rightFace;
}

int lastIndex = 0;

class ColorPair {
  final int index;

  ColorPair({required this.index});

  static ColorPair get defaultPair => ColorPair(index: 0);

  static ColorPair newPair() {
    return ColorPair(index: ++lastIndex);
  }

  @override
  operator ==(dynamic other) {
    if (other is ColorPair) {
      return index == other.index;
    }
    return false;
  }

  @override
  int get hashCode => index.hashCode;
}

Iterable<T> skipTail<T>(List<T> list, int count) sync* {
  if (count >= list.length) return;
  for (int i = 0; i < list.length - count; i++) {
    yield list[i];
  }
}

class Tuple<T, K> {
  final T left;
  final K right;
  Tuple({required this.left, required this.right});
}

class ColorSplit {
  final Set<Polygon> nullColor;
  final List<Tuple<PolygonColor, Set<Polygon>>> otherColors;

  ColorSplit({required this.nullColor, required this.otherColors});
}

class Geometry {
  final List<Polygon> polygons;
  Iterable<Polygon> filterPolygons(PolygonColor color) {
    return polygons.where((element) => element.color == color);
  }

  final Map<Polygon, List<Polygon>> _neighbors;
  final List<List<SimplePolygon>> _grid;

  Geometry(
      {required this.polygons, required Map<Polygon, List<Polygon>> neighbors, required List<List<SimplePolygon>> grid})
      : _neighbors = neighbors,
        _grid = grid;
  Iterable<Polygon> neighbors(Polygon target) {
    return _neighbors[target] ?? [];
  }

  bool visit(bool Function(Polygon polygon, List<Polygon> neighbors) visitor) {
    for (List<SimplePolygon> list in skipTail(_grid, 1).skip(1)) {
      for (SimplePolygon polygon in skipTail(list, 1).skip(1)) {
        if (visitor(polygon, _neighbors[polygon] ?? [])) {
          return true;
        }
      }
    }
    return false;
  }

  ColorSplit splitByColor(Set<Polygon> polygons) {
    Set<Polygon> p = Set.from(polygons);
    List<Set<Polygon>> rvalue = [];
    final nullSet = p.where((element) => element.color == null).toList();
    p.removeAll(nullSet);
    while (p.isNotEmpty) {
      final first = p.first;
      final color = first.color;
      rvalue.add(Set.from(p.where((element) => element.color == color)));
      p.removeWhere((element) => element.color == color);
    }
    rvalue.sort((a, b) => b.length.compareTo(a.length));
    final others = rvalue.map((polygons) {
      final first = polygons.first;
      return Tuple(left: first.color!, right: polygons);
    });
    return ColorSplit(nullColor: Set.from(nullSet), otherColors: others.toList());
  }

  int _setColor(Polygon p, PolygonColor c) {
    if (p.color == c) return 0;
    if (p.color == null) {
      p.color = c;
      return 1;
    }
    int count = 0;
    for (Polygon pp in polygons.where((element) => element.color == p.color)) {
      pp.color = c;
      count++;
    }
    return count;
  }

  int markOpposite(Polygon p1, Polygon p2) {
    PolygonColor? c1 = p1.color;
    PolygonColor? c2 = p2.color;

    late PolygonColor leftColor;
    late PolygonColor rightColor;
    if (c1 != null && c2 != null) {
      if (c1.family.index < c2.family.index) {
        leftColor = c1;
        rightColor = c1.oppositeColor;
      } else {
        leftColor = c2.oppositeColor;
        rightColor = c2;
      }
    } else if (c1 != null && c2 == null) {
      leftColor = c1;
      rightColor = c1.oppositeColor;
    } else if (c2 != null && c1 == null) {
      leftColor = c2.oppositeColor;
      rightColor = c2;
    } else {
      final newColor = PolygonColor(family: ColorPair.newPair(), member: false);
      leftColor = newColor;
      rightColor = newColor.oppositeColor;
    }

    return _setColor(p1, leftColor) + _setColor(p2, rightColor);
  }

  PolygonColor? _minimumColor(Iterable<Polygon> polygons, bool orCreate) {
    final colors = polygons.map((e) => e.color).expand((element) {
      if (element != null) return [element];
      return <PolygonColor>[];
    }).toList();
    if (colors.isEmpty && orCreate) return PolygonColor(family: ColorPair.newPair(), member: true);
    colors.sort((value, element) => value.family.index.compareTo(element.family.index));
    return colors.isEmpty ? null : colors.first;
  }

  int markSame(Iterable<Polygon> polygons) {
    final color = _minimumColor(polygons, true);
    final changes = polygons.map((p) => _setColor(p, color ?? PolygonColor(family: ColorPair.newPair(), member: true)));
    return changes.reduce((value, element) => value + element);
  }

  bool numbersVisit() {
    return visit((polygon, neighbors) {
      final value = polygon.value;

      if (value == null) return false;

      if (value == 3) {
        Set<Polygon> n = Set.from(neighbors);
        final split = splitByColor(n);
        final other = split.otherColors;
        if (other.isEmpty) return false;
        final first = split.otherColors.first;
        if (first.right.length == 3) {
        } else if (first.right.length == 2) {
          final opposites = n.difference(first.right);
          assert(opposites.length == 2);
          int count = markOpposite(opposites.first, opposites.last) + markOpposite(polygon, first.right.first);
          if (count != 0) {
            return true;
          }
        }
      } else if (value == 0) {
        final count = markSame([polygon] + neighbors);
        if (count != 0) {
          return true;
        }
      }
      return false;
    });
  }

  static Geometry parse(List<String> lines) {
    final width = lines.map((e) => e.length).reduce((value, element) => max(value, element));
    final height = lines.length;

    final List<List<SimplePolygon>> grid = List.generate(height + 2, (y) {
      final index = (y == 0 || y == height + 1) ? 0 : (y - 1);
      final line = lines[index];
      return List.generate(width + 2, (x) {
        if (x == 0 || y == 0) return SimplePolygon(color: PolygonColor.blue);
        if (x == width + 1 || y == height + 1) return SimplePolygon(color: PolygonColor.blue);
        final index = x - 1;
        if (index >= line.length) return SimplePolygon();

        final char = line.substring(index, index + 1);
        if (char == " ") return SimplePolygon();
        final int? value = int.tryParse(char);
        return SimplePolygon(value: value);
      });
    });
    List<Polygon> allPolygons = grid.reduce((value, element) => value + element);
    Map<Polygon, List<Polygon>> neighbors = {};
    for (int i = 0; i < grid.length; i++) {
      for (int j = 0; j < grid[0].length; j++) {
        final polygon = grid[i][j];
        final List<Polygon> adjacent = [];
        if (i > 0) adjacent.add(grid[i - 1][j]);
        if (j > 0) adjacent.add(grid[i][j - 1]);
        if (i < grid.length - 1) adjacent.add(grid[i + 1][j]);
        if (j < grid[0].length - 1) adjacent.add(grid[i][j + 1]);
        neighbors[polygon] = adjacent;
      }
    }

    return Geometry(polygons: allPolygons, neighbors: neighbors, grid: grid);
  }

  @override
  String toString() {
    final a = "A".codeUnitAt(0);
    return _grid.map((e) {
      return e.map((polygon) {
        final color = polygon.color;
        if (color == null) return " ";
        return String.fromCharCode(a + 2 * color.family.index + (color.member ? 1 : 0));
      }).reduce((value, element) => value + element);
    }).reduce((value, element) => value + "\n" + element);
  }
}

class PolygonColor {
  final ColorPair family;
  final bool member;

  PolygonColor({required this.family, required this.member});

  static final PolygonColor blue = PolygonColor(family: ColorPair.defaultPair, member: false);
  static final PolygonColor green = PolygonColor(family: ColorPair.defaultPair, member: true);

  @override
  bool operator ==(dynamic other) {
    if (other is PolygonColor) {
      return other.family == family && other.member == member;
    }
    return false;
  }

  bool opposite(PolygonColor other) {
    return other.family == family && other.member != member;
  }

  PolygonColor get oppositeColor => PolygonColor(family: family, member: !member);

  @override
  int get hashCode => family.hashCode + 7 * member.hashCode;
}

abstract class Polygon {
  PolygonColor? color;
  abstract final int? value;
  abstract final int sides;
}

class SimplePolygon implements Polygon {
  @override
  PolygonColor? color;
  @override
  final int? value;

  @override
  int get sides => 4;
  SimplePolygon({this.color, this.value});
}

class Point {
  final int x;
  final int y;
  Point(this.x, this.y);

  @override
  bool operator ==(dynamic other) {
    if (other is Point) {
      return other.x == x && other.y == y;
    }
    return false;
  }

  @override
  int get hashCode => x.hashCode + 7 * y.hashCode;
}

int _id = 0;

class Node {
  final int id;

  Node(this.id);
  static Node newNode() {
    return Node(_id++);
  }
}

class Segment {
  final Point origin;
  final Point destination;
  Segment(this.origin, this.destination);

  @override
  bool operator ==(dynamic other) {
    if (other is Segment) {
      return (other.origin == origin && other.destination == destination) ||
          (other.origin == destination && other.destination == origin);
    }
    return false;
  }

  @override
  int get hashCode => origin.hashCode + destination.hashCode;
}

class DrawablePolygon {
  final List<Node> vertices;
  final List<Segment> edges;

  DrawablePolygon({required this.vertices, required this.edges})
      : assert(vertices.length >= 3, "A polygon must have at least 3 vertices."),
        assert(edges.length >= 3, "A polygon must have at least 3 edges.");

  static DrawablePolygon createHexagon(Point center) {
    List<Node> vertices = List.generate(6, (index) => Node.newNode());
    List<Segment> edges = [];
    //List.generate(6, (index) => Segment(vertices[index], vertices[(index + 1) % 6]));
    return DrawablePolygon(vertices: vertices, edges: edges);
  }
}

Set<Point> _points = {};

Set<Point> createPoints() {
  // 12 x 6
  for (int y = 0; y < 6; y++) {
    for (int x = 0; x < 12; x++) {
      final px = -1 + x - (y % 2);
      final py = 1 + (x % 2) - 3 * y;
      _points.add(Point(px, py));
    }
  }
  return _points;
}

Point getPoint(int x, int y) {
  final point = Point(x, y);
  final p = _points.lookup(point);
  if (p != null) {
    return p;
  }
  // log('adding point that wasn\'t found: ($x, $y)');
  _points.add(point);
  return point;
}

Set<Polygon> createHexagons() {
  for (int y = 0; y < 5; y++) {
    for (int x = 0; x < 5; x++) {
      if (x == 4 && y % 2 == 1) continue;

      final cx = y % 2 + 2 * x;
      final cy = -3 * y;

      final p1 = getPoint(cx + 1, cy + 1);
      final p2 = getPoint(cx, cy + 2);
      final p3 = getPoint(cx - 1, cy + 1);
      final p4 = getPoint(cx - 1, cy - 1);
      final p5 = getPoint(cx, cy - 2);
      final p6 = getPoint(cx + 1, cy - 1);

      final edge = print("($cx, $cy)");
    }
    print('\n');
  }
  return {};
}

List<List<Polygon>> createSquares({required int size}) {
  List<List<Polygon>> rvalue = List.generate(size, (row) {
    // return List.generate(size, (column) {
    //   /*
    //    * 4 points
    //    * (0,0)-(1,0)
    //    * (1,0)-(1,1)
    //    */
    //   return <Polygon>[];
    return <Polygon>[];
    // });
  });

  return rvalue;
}
