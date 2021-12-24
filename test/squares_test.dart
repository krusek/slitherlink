import 'dart:developer';

import 'package:flutter_test/flutter_test.dart';
import 'package:slitherlink/geometry/geometry.dart';

bool verifyMap(List<String> input, List<String> expected, {ParsingConfiguration? configuration}) {
  ParsingConfiguration config = configuration ?? const ParsingConfiguration(boxLength: 1, includeBorder: false);
  final grid = Geometry.parseAdvanced(input, config);
  int count = 0;
  while (grid.numbersVisit() && count < 100) {
    count++;
  }
  final e = expected.join("\n");
  final string = grid.toString();
  assert(e == string);
  return e == string;
}

void main() {
  group('specific patterns', () {
    test('test 1s patterns', () {
      assert(verifyMap([
        " A ",
        "A1B",
        "   ",
      ], [
        " A ",
        "AAB",
        " A ",
      ]));
      assert(verifyMap([
        "      ",
        "  1AB ",
        "      ",
      ], [
        " A ",
        "AAB",
        " A ",
      ], configuration: const ParsingConfiguration(boxLength: 2, includeBorder: false)));
      assert(verifyMap([
        "   ",
        "A1B",
        "   ",
      ], [
        " D ",
        "A B",
        " C ",
      ]));
    });
  });
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
    int turns = 1;
    while (grid.numbersVisit() && turns < 100) {
      turns++;
    }
    log('skip forward $turns turns');
    log(grid.toString());
  });
}
