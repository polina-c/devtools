// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

library matchers;

import 'dart:io' as io;

import 'package:devtools_app/src/screens/inspector/diagnostics_node.dart';
import 'package:flutter_test/flutter_test.dart';

RemoteDiagnosticsNode? findNodeMatching(
  RemoteDiagnosticsNode node,
  String text,
) {
  if (node.name?.startsWith(text) == true ||
      node.description?.startsWith(text) == true) {
    return node;
  }
  for (var child in node.childrenNow) {
    final match = findNodeMatching(child, text);
    if (match != null) {
      return match;
    }
  }
  return null;
}

String treeToDebugString(RemoteDiagnosticsNode node) {
  return node.toDiagnosticsNode().toStringDeep();
}

String treeToDebugStringTruncated(RemoteDiagnosticsNode node, int maxLines) {
  List<String> lines = node.toDiagnosticsNode().toStringDeep().split('\n');
  if (lines.length > maxLines) {
    lines = lines.take(maxLines).toList()..add('...');
  }
  return lines.join('\n');
}

/// Asserts that a [path] matches a golden file after normalizing likely hash
/// codes.
///
/// Paths are assumed to reference files within the `test/goldens` directory.
///
/// To rebaseline all golden files run:
/// ```
/// tool/update_goldens.sh
/// ```
///
/// A `#` followed by 5 hexadecimal digits is assumed to be a short hash code
/// and is normalized to #00000.
///
/// See Also:
///
///  * [equalsIgnoringHashCodes], which does the same thing without the golden
///    file functionality.
Matcher equalsGoldenIgnoringHashCodes(String path) {
  return _EqualsGoldenIgnoringHashCodes(path);
}

Matcher equalsGoldenValueIgnoringHashCodes(String value) {
  const shouldCheckForMatchingGoldens = bool.fromEnvironment(
    'SHOULD_TEST_GOLDENS',
    defaultValue: true,
  );

  if (shouldCheckForMatchingGoldens) {
    return equalsIgnoringHashCodes(value);
  }

  return const _AlwaysTrueMatcher();
}

class _EqualsGoldenIgnoringHashCodes extends Matcher {
  _EqualsGoldenIgnoringHashCodes(String pathWithinGoldenDirectory) {
    path = 'test/goldens$_goldensSuffix/$pathWithinGoldenDirectory';
    try {
      _value = _normalize(io.File(path).readAsStringSync());
    } catch (e) {
      _value = 'Error reading $path: $e';
    }
  }
  late String path;
  late String _value;

  static final Object _mismatchedValueKey = Object();

  static final String _goldensSuffix =
      io.Platform.environment['DEVTOOLS_GOLDENS_SUFFIX'] ?? '';

  static bool get updateGoldens => autoUpdateGoldenFiles;

  static String _normalize(String s) {
    return s.replaceAll(RegExp(r'#[0-9a-f]{5}'), '#00000');
  }

  @override
  bool matches(dynamic object, Map<dynamic, dynamic> matchState) {
    const shouldCheckForMatchingGoldens = bool.fromEnvironment(
      'SHOULD_TEST_GOLDENS',
      defaultValue: true,
    );
    if (shouldCheckForMatchingGoldens) {
      final String description = _normalize(object);
      if (_value != description) {
        if (updateGoldens) {
          io.File(path).writeAsStringSync(description);
          print('Updated golden file $path\nto\n$description');
          // Act like the match succeeded so all goldens are updated instead of
          // just the first failure.
          return true;
        }

        matchState[_mismatchedValueKey] = description;
        return false;
      }
    }
    return true;
  }

  @override
  Description describe(Description description) {
    return description.add('multi line description equals $_value');
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (!matchState.containsKey(_mismatchedValueKey)) {
      return mismatchDescription;
    }

    final String? actualValue = matchState[_mismatchedValueKey];
    // Leading whitespace is added so that lines in the multi-line
    // description returned by addDescriptionOf are all indented equally
    // which makes the output easier to read for this case.
    return mismatchDescription
        .add('expected golden file \'$path\' with normalized value\n  ')
        .addDescriptionOf(_value)
        .add('\nbut got\n  ')
        .addDescriptionOf(actualValue)
        .add('\nTo update golden files run:\n')
        .add('  tool/update_goldens.sh"\n');
  }
}

class _AlwaysTrueMatcher extends Matcher {
  const _AlwaysTrueMatcher();

  @override
  bool matches(dynamic object, Map<dynamic, dynamic> matchState) {
    return true;
  }

  @override
  Description describe(Description description) {
    return description;
  }
}

// TODO(https://github.com/flutter/devtools/issues/4060): add a check to the
// bots script that verifies we never use [matchesGoldenFile] directly.
/// A matcher for testing DevTools goldens which will always return true when
/// the 'SHOULD_TEST_GOLDENS' environment variable is set to false.
///
/// This should always be used instead of [matchesGoldenFile] for testing
/// DevTools golden images.
///
/// We configure this environment variable on the bots, where we have bots that
/// test against a pinned flutter version and bots that test against Flutter
/// master. To avoid noise on the bots, we only want to test goldens against the
/// pinned version of Flutter that we build DevTools from (see
/// flutter-version.txt).
Matcher matchesDevToolsGolden(Object key) {
  const shouldCheckForMatchingGoldens = bool.fromEnvironment(
    'SHOULD_TEST_GOLDENS',
    defaultValue: true,
  );
  if (shouldCheckForMatchingGoldens && io.Platform.isMacOS) {
    return matchesGoldenFile(key);
  }
  return const _AlwaysTrueMatcher();
}
