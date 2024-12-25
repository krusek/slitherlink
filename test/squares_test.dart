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
  final string = grid.checkPattern(expected);
  expect(string, null, reason: string);
  return string == null;
}

void main() {
  group('number patterns', () {
    test('test 1s patterns', () {
      verifyMap([
        " A ",
        "A1B",
        "   ",
      ], [
        " A ",
        "AAB",
        " A ",
      ]);
      verifyMap([
        "      ",
        "  1AB ",
        "      ",
      ], [
        " A ",
        "AAB",
        " A ",
      ], configuration: const ParsingConfiguration(boxLength: 2, includeBorder: false));
      verifyMap([
        "   ",
        "A1B",
        "   ",
      ], [
        " C ",
        "ACB",
        " C ",
      ]);
    });

    test('test 3s patterns', () {
      verifyMap([
        " A ",
        "A3B",
        "   ",
      ], [
        " A ",
        "ABB",
        " A ",
      ]);
      verifyMap([
        "      ",
        "  3AA ",
        "      ",
      ], [
        " B ",
        "BAA",
        " B ",
      ], configuration: const ParsingConfiguration(boxLength: 2, includeBorder: false));
      verifyMap([
        "   ",
        "A3B",
        "   ",
      ], [
        " E ",
        "AFB",
        " E ",
      ]);
      verifyMap([
        "   ",
        "A3A",
        "   ",
      ], [
        " G ",
        "ABA",
        " H ",
      ]);
    });

    test('test 2s patterns', () {
      verifyMap([
        " A ",
        "A2 ",
        "   ",
      ], [
        " A ",
        "A B",
        " B ",
      ]);
      verifyMap([
        " B ",
        "A2 ",
        "   ",
      ], [
        " B ",
        "A D",
        " C ",
      ]);
    });

    test('test 0s patterns', () {
      verifyMap([
        "   ",
        "A0 ",
        "   ",
      ], [
        " A ",
        "AAA",
        " A ",
      ]);
      verifyMap([
        "   ",
        " 0 ",
        "   ",
      ], [
        " D ",
        "DDD",
        " D ",
      ]);
    });
  });

  group('specific patterns', () {
    test('cross pattern', () {
      verifyMap(["AB", "B "], ["AB", "BB"]);
      verifyMap(["AB", "BC"], ["AB", "BB"]);
      verifyMap(["CB", "BA"], ["BB", "BA"]);
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
