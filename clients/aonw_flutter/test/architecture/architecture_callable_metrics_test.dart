import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/architecture/dart_metrics.dart';
import '../../../../tool/architecture/failure.dart';

void main() {
  test('analyzer 12.1 public AST measures each supported type kind', () {
    final metrics = measureDartSource(
      'lib/sample.dart',
      '''
/// Documentation is deliberately outside the declaration span.
@deprecated
class Alpha {
  void first() {}
}

enum Choice { one }
mixin Capability {}
extension NamedStrings on String {}
extension on int {}
extension on int {
  bool get positive => this > 0;
}
extension type Meter(int value) {}
'''
          .trimLeft(),
    );
    final byKey = {
      for (final metric in metrics.declarations) metric.key: metric,
    };

    expect(byKey.keys, contains('lib/sample.dart::class:Alpha'));
    expect(byKey.keys, contains('lib/sample.dart::enum:Choice'));
    expect(byKey.keys, contains('lib/sample.dart::mixin:Capability'));
    expect(byKey.keys, contains('lib/sample.dart::extension:NamedStrings'));
    expect(byKey.keys, contains('lib/sample.dart::extension:<on:int>#1'));
    expect(byKey.keys, contains('lib/sample.dart::extension:<on:int>#2'));
    expect(byKey.keys, contains('lib/sample.dart::extension_type:Meter'));
    expect(byKey['lib/sample.dart::class:Alpha']!.startLine, 2);
    expect(byKey['lib/sample.dart::class:Alpha']!.lines, 4);
  });

  test('callable identities and exclusive line spans are stable', () {
    final metrics = measureDartSource(
      'lib/callables.dart',
      '''
int topLevel(int value) => value + 1;
int get globalValue => 0;
set globalValue(int value) {}
class Counter {
  Counter();
  Counter.named(bool enabled) : assert(enabled ? true : false);
  int get value => 0;
  set value(int next) {}
  Counter operator +(Counter other) => this;
  void run() {
    int helper(int input) {
      return input + 1;
    }
    final initial = (int input) {
      return helper(input);
    };
    [1].map((input) {
      return input * 2;
    }).toList();
    register('ready', () {
      helper(initial(1));
    });
  }
}
class FirstOwner {
  final callback = () => 1;
}
class SecondOwner {
  final callback = () => 2;
}
void compact() {
  before();
  register('first', () {}); register('second', () {});
  after();
}
'''
          .trimLeft(),
    );

    expect(
      {
        for (final metric in metrics.callables)
          metric.key: {'startLine': metric.startLine, 'lines': metric.lines},
      },
      {
        'lib/callables.dart::function:topLevel': {'startLine': 1, 'lines': 1},
        'lib/callables.dart::getter:globalValue': {'startLine': 2, 'lines': 1},
        'lib/callables.dart::setter:globalValue': {'startLine': 3, 'lines': 1},
        'lib/callables.dart::class:Counter/constructor:<unnamed>': {
          'startLine': 5,
          'lines': 1,
        },
        'lib/callables.dart::class:Counter/constructor:named': {
          'startLine': 6,
          'lines': 1,
        },
        'lib/callables.dart::class:Counter/getter:value': {
          'startLine': 7,
          'lines': 1,
        },
        'lib/callables.dart::class:Counter/setter:value': {
          'startLine': 8,
          'lines': 1,
        },
        'lib/callables.dart::class:Counter/operator:+': {
          'startLine': 9,
          'lines': 1,
        },
        'lib/callables.dart::class:Counter/method:run': {
          'startLine': 10,
          'lines': 2,
        },
        'lib/callables.dart::class:Counter/method:run/local_function:helper#1':
            {'startLine': 11, 'lines': 3},
        'lib/callables.dart::class:Counter/method:run/closure:initializer[initial]#1':
            {'startLine': 14, 'lines': 3},
        'lib/callables.dart::class:Counter/method:run/closure:map#1': {
          'startLine': 17,
          'lines': 3,
        },
        'lib/callables.dart::class:Counter/method:run/closure:register[ready]#1':
            {'startLine': 20, 'lines': 3},
        'lib/callables.dart::class:FirstOwner/closure:initializer[callback]#1':
            {'startLine': 26, 'lines': 1},
        'lib/callables.dart::class:SecondOwner/closure:initializer[callback]#1':
            {'startLine': 29, 'lines': 1},
        'lib/callables.dart::function:compact': {'startLine': 31, 'lines': 4},
        'lib/callables.dart::function:compact/closure:register[first]#1': {
          'startLine': 33,
          'lines': 1,
        },
        'lib/callables.dart::function:compact/closure:register[second]#1': {
          'startLine': 33,
          'lines': 1,
        },
      },
    );
    final namedConstructor = metrics.callables.singleWhere(
      (metric) => metric.key.endsWith('/constructor:named'),
    );
    expect(namedConstructor.nesting, 1);
    expect(namedConstructor.cyclomaticComplexity, 2);
    expect(namedConstructor.cognitiveComplexity, 1);
  });

  test('control-flow complexity has deterministic golden values', () {
    final metrics = measureDartSource(
      'lib/complexity.dart',
      '''
void straight() {}
void nested(int value) {
  if (value > 0) {
    while (value > 1) {
      if (value > 2 && value < 10) {
        value--;
      } else {
        value++;
      }
    }
  } else if (value == 0) {
    value++;
  } else {
    value--;
  }
}
void loops(Iterable<int> values) {
  for (final value in values) {
    while (value > 0) {
      do {
        break;
      } while (value < 10);
    }
  }
  try {
    values.first;
  } catch (_) {
    return;
  }
}
int choose(int value) {
  switch (value) {
    case 0:
      return 0;
    case 1:
      return 1;
    default:
      return -1;
  }
}
bool conditional(bool first, bool second, bool third) =>
    first && second || third ? true : false;
List<int> collect(List<int> values) => [
  for (final value in values)
    if (value > 0) value,
];
List<int> collectBranch(int value) => [
  if (value > 0) 1 else if (value == 0) 0 else -1,
];
int pattern(Object value) => switch (value) {
  int result when result > 0 && result < 10 => result,
  int result => result,
  _ => 0,
};
void owner() {
  void local(bool condition) {
    if (condition) {}
  }
  local(true);
}
'''
          .trimLeft(),
    );

    expect(
      {
        for (final metric in metrics.callables)
          metric.key: {
            'nesting': metric.nesting,
            'cyclomatic': metric.cyclomaticComplexity,
            'cognitive': metric.cognitiveComplexity,
          },
      },
      {
        'lib/complexity.dart::function:straight': {
          'nesting': 0,
          'cyclomatic': 1,
          'cognitive': 0,
        },
        'lib/complexity.dart::function:nested': {
          'nesting': 3,
          'cyclomatic': 6,
          'cognitive': 10,
        },
        'lib/complexity.dart::function:loops': {
          'nesting': 3,
          'cyclomatic': 5,
          'cognitive': 7,
        },
        'lib/complexity.dart::function:choose': {
          'nesting': 1,
          'cyclomatic': 3,
          'cognitive': 1,
        },
        'lib/complexity.dart::function:conditional': {
          'nesting': 1,
          'cyclomatic': 4,
          'cognitive': 3,
        },
        'lib/complexity.dart::function:collect': {
          'nesting': 2,
          'cyclomatic': 3,
          'cognitive': 3,
        },
        'lib/complexity.dart::function:collectBranch': {
          'nesting': 1,
          'cyclomatic': 3,
          'cognitive': 3,
        },
        'lib/complexity.dart::function:pattern': {
          'nesting': 1,
          'cyclomatic': 6,
          'cognitive': 3,
        },
        'lib/complexity.dart::function:owner': {
          'nesting': 0,
          'cyclomatic': 1,
          'cognitive': 0,
        },
        'lib/complexity.dart::function:owner/local_function:local#1': {
          'nesting': 1,
          'cyclomatic': 2,
          'cognitive': 1,
        },
      },
    );
  });

  test('parser diagnostics fail closed', () {
    expect(
      () => measureDartSource('lib/broken.dart', 'void broken( {'),
      throwsA(isA<ArchitectureFailure>()),
    );
  });
}
