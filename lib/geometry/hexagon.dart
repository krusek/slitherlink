import 'dart:developer';

import 'dart:math';

import 'package:flutter/material.dart';

import 'geometry.dart';

abstract class Edge {
  Polygon get leftFace;
  Polygon get rightFace;
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
