import 'dart:math';

int _lastIndex = 0;

class ColorPair {
  final int index;

  ColorPair({required this.index});

  static ColorPair get defaultPair => ColorPair(index: 0);

  static ColorPair newPair() {
    return ColorPair(index: ++_lastIndex);
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

class ParsingConfiguration {
  final int boxLength;
  final bool includeBorder;

  const ParsingConfiguration({this.boxLength = 1, this.includeBorder = true});

  static const defaultConfiguration = ParsingConfiguration();
}

class Geometry {
  final List<Polygon> polygons;
  Iterable<Polygon> filterPolygons(PolygonColor color) {
    return polygons.where((element) => element.color == color);
  }

  final Map<Polygon, List<Polygon>> _neighbors;
  final List<List<SimplePolygon>> _grid;

  Geometry({required this.polygons, required List<List<SimplePolygon>> grid})
      : _neighbors = _generateNeighbors(grid),
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

  int markAllOpposite(Polygon p1, Iterable<Polygon> opposites) {
    return opposites.map((e) => markOpposite(p1, e)).reduce((value, element) => value + element);
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

  List<Polygon>? _findOpposites(Iterable<Polygon> polygons) {
    int index = 0;
    for (Polygon p in polygons) {
      final color1 = p.color;
      index += 1;
      if (color1 == null) continue;
      for (Polygon pp in polygons.skip(index)) {
        final color2 = pp.color;
        if (color2 == null) continue;
        if (color1.opposite(color2)) {
          return [p, pp];
        }
      }
    }
  }

  List<Polygon> _findSame(Polygon polygon, Iterable<Polygon> neighbors) {
    final color = polygon.color;
    if (color == null) return [];

    return neighbors.where((element) => color == element.color).toList();
  }

  bool numbersVisit() {
    return visit((polygon, neighbors) {
      final value = polygon.value;

      if (value == null) return false;

      if (value == 0) {
        final count = markSame([polygon] + neighbors);
        if (count != 0) {
          return true;
        }
      }

      Set<Polygon> n = Set.from(neighbors);
      final split = splitByColor(n);
      final other = split.otherColors;

      if (other.isEmpty) return false;

      // If all neighbors have the same color then the center one must match.
      if (other.length == 1 && other.first.right.length == neighbors.length) {
        return markSame([polygon, neighbors.first]) > 0;
      }

      final majorityTuple = split.otherColors.first;
      final mainColorSet = majorityTuple.right;

      if (mainColorSet.length > value) {
        int changes = markSame([polygon, mainColorSet.first]);
        final remaining = Set.from(neighbors);
        remaining.removeAll(mainColorSet);
        if (remaining.length == 2) {
          changes += markOpposite(remaining.first, remaining.last);
        }
        if (remaining.length == 1) {
          changes += markOpposite(remaining.first, polygon);
        }
        if (changes > 0) return true;
      }
      if (mainColorSet.length > neighbors.length - value) {
        int changes = markOpposite(polygon, mainColorSet.first);
        final remaining = Set.from(neighbors);
        remaining.removeAll(mainColorSet);
        if (remaining.length == 2) {
          changes += markOpposite(remaining.first, remaining.last);
        }
        if (remaining.length == 1) {
          changes += markSame([remaining.first, polygon]);
        }
        if (changes > 0) return true;
      }
      if (value * 2 == neighbors.length && mainColorSet.length == value) {
        final remaining = Set<Polygon>.from(neighbors);
        remaining.removeAll(mainColorSet);
        final changes = markAllOpposite(mainColorSet.first, remaining);
        if (changes > 0) return true;
      }

      if (value == 2 && neighbors.length == 4) {
        final opposites = _findOpposites(neighbors);
        if (opposites != null) {
          final remaining = Set<Polygon>.from(neighbors);
          remaining.removeAll(opposites);
          final changes = markOpposite(remaining.first, remaining.last);
          if (changes > 0) return true;
        }
      }

      final color = polygon.color;
      if (color != null) {
        final sames = _findSame(polygon, neighbors);
        final remaining = Set<Polygon>.from(neighbors);
        remaining.removeAll(sames);
        if (remaining.length == value) {
          final changes = markAllOpposite(polygon, remaining);
          if (changes > 0) return true;
        }
      }
      if (color != null) {
        final opposites = neighbors.where((element) => color.opposite(element.color));
        final remaining = Set<Polygon>.from(neighbors);
        remaining.removeAll(opposites);
        if (opposites.length == value) {
          remaining.add(polygon);
          final changes = markSame(remaining);
          if (changes > 0) return true;
        }
      }

      if (1 == value || 1 == neighbors.length - value) {
        final opposites = _findOpposites(neighbors);
        if (opposites != null) {
          final remaining = Set<Polygon>.from(neighbors);
          remaining.removeAll(opposites);
          final changes = markSame(remaining);
          if (value == 1) {
            markSame([polygon, remaining.first]);
          } else {
            markOpposite(polygon, remaining.first);
          }
          if (changes > 0) return true;
        }
      }

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

  static Geometry parseAdvanced(List<String> data, ParsingConfiguration configuration) {
    final boxLength = configuration.boxLength;
    final includeBorder = configuration.includeBorder;

    List<String> lines = data;

    final width = (lines.map((e) => e.length).reduce((value, element) => max(value, element)) ~/ boxLength) +
        (includeBorder ? 2 : 0);
    final height = lines.length + (includeBorder ? 2 : 0);

    if (includeBorder) {
      lines = lines.map((e) => 'A' + e + 'A').toList();
      final extraLine = List.generate(width, (index) => 'A').join();
      final realExtraLine = List.generate(boxLength, (index) => extraLine).join();

      lines.add(realExtraLine);
      lines.insert(0, realExtraLine);
    }

    final List<List<SimplePolygon>> grid = List.generate(height, (y) {
      final index = y;
      final line = lines[index];
      return List.generate(width, (x) {
        int? value;
        PolygonColor? color;

        for (int i = 0; i < boxLength; i++) {
          final char = line.substring(boxLength * x + i, boxLength * x + i + 1);
          if (char == " ") continue;

          final int? v = int.tryParse(char);
          if (v != null) {
            value = v;
          } else {
            final cvalue = char.codeUnitAt(0) - "A".codeUnitAt(0);
            final family = cvalue ~/ 2;
            color = PolygonColor(family: ColorPair(index: family), member: cvalue % 2 == 1);
          }
        }
        return SimplePolygon(color: color, value: value);
      });
    });
    List<Polygon> allPolygons = grid.reduce((value, element) => value + element);

    return Geometry(polygons: allPolygons, grid: grid);
  }

  static Geometry parse(List<String> lines) {
    return parseAdvanced(lines, ParsingConfiguration());
  }

  static Map<Polygon, List<Polygon>> _generateNeighbors(List<List<SimplePolygon>> grid) {
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
    return neighbors;
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

  String? checkPattern(List<String> pattern) {
    Map<String, PolygonColor> map1 = {"A": PolygonColor.blue, "B": PolygonColor.green};
    Map<PolygonColor, String> map2 = {PolygonColor.blue: "A", PolygonColor.green: "B"};

    const skip = " ";
    for (int i = 0; i < _grid.length; i++) {
      for (int j = 0; j < _grid[0].length; j++) {
        final String character = pattern[i].substring(j, j + 1);
        if (character == skip) continue;
        final color = _grid[i][j].color;
        if (color == null) {
          return "Expected $character at ($i,$j) but found empty";
        }

        final foundCharacter = map2[color];
        final expectedColor = map1[character];
        if (foundCharacter == null && expectedColor == null) {
          map1[character] = color;
          map2[color] = character;

          final unit = character.codeUnitAt(0);
          final oppositeCode = unit - 1 + 2 * (unit % 2);
          final oppositeCharacter = String.fromCharCode(oppositeCode);
          final oppositeColor = color.oppositeColor;
          map1[oppositeCharacter] = oppositeColor;
          map2[oppositeColor] = oppositeCharacter;
        }
        if (foundCharacter != null && expectedColor != null) {
          if (character != foundCharacter) {
            return "Expected $character at ($i, $j) but found $foundCharacter";
          }
        }
        if (foundCharacter != null && expectedColor == null) {
          return "Expected $character at ($i, $j) but found $foundCharacter";
        }
        if (foundCharacter == null && expectedColor != null) {
          return "Expected $character at ($i, $j) but found different";
        }
      }
    }
    return null;
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

  bool opposite(PolygonColor? other) {
    if (other == null) return false;
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
