import 'dart:developer';

import 'package:flutter_test/flutter_test.dart';
import 'package:slitherlink/geometry/hexagon.dart';

void main() {
  test('test point creation -- check random points', () {
    final grid = Geometry.parse([
      "      3",
      "1212 2 ",
      "33  201",
      "221 102",
      "320  23",
      "2 2 2  ",
      "     1 ",
    ]);
    log(grid.toString());
    grid.numbersVisit();
    log(grid.toString());
    grid.numbersVisit();
    log(grid.toString());
    grid.numbersVisit();
    log(grid.toString());
    grid.numbersVisit();
    log(grid.toString());
    grid.numbersVisit();
    log(grid.toString());
    grid.numbersVisit();
    log(grid.toString());
  });
}
