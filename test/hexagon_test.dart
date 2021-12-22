import 'package:flutter_test/flutter_test.dart';
import 'package:slitherlink/geometry/hexagon.dart';

void main() {
  test('test point creation -- check random points', () {
    final points = createPoints();
    assert(points.contains(Point(-1, 1)));
    assert(points.contains(Point(0, 2)));
    assert(points.contains(Point(1, 1)));
    assert(points.contains(Point(2, 2)));
    assert(points.contains(Point(3, 1)));

    assert(points.contains(Point(-1, -1)));
    assert(points.contains(Point(0, -2)));
    assert(points.contains(Point(1, -1)));

    assert(points.contains(Point(-1, -5)));
  });

  test('test hexagon creation -- check random centers', () {
    createHexagons();
  });
}
