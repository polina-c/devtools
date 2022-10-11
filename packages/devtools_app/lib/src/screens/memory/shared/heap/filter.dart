// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:collection/collection.dart';

import 'heap.dart';

class HeapClassFilter {
  HeapClassFilter({this.fullName = '', this.includePathes = false});

  final String fullName;

  /// If true, the filter shows also clases that match [fullName] in one of their
  /// retaining pathes.
  final bool includePathes;

  bool isEqual(HeapClassFilter other) {
    return other.fullName == fullName && other.includePathes == includePathes;
  }

  /// Returns true if this filter is stonger than [other],
  /// i.e. can be applied to the result of other filter, not to the whole set.
  bool isStonger(HeapClassFilter other) {
    if (this == other)
      throw StateError('This method should not be applied to equal filters.');

    // 1 - stronger, 0 - equal, -1 - weaker.
    late int byPathInclusion;
    if (includePathes == other.includePathes) {
      byPathInclusion = 0;
    } else if (includePathes) {
      byPathInclusion = -1;
    } else {
      assert(!includePathes);
      byPathInclusion = 1;
    }

    // 1 - stronger, 0 - equal, -1 - weaker.
    late int byFullName;
    if (fullName == other.fullName) {
      byFullName = 0;
    } else if (fullName.contains(other.fullName)) {
      byFullName = 1;
    } else {
      byFullName = -1;
    }

    if (byPathInclusion == 0) return byFullName == 1;
    if (byFullName == 0) return byPathInclusion == 1;
    if (byFullName == byPathInclusion) return byFullName == 1;

    // One filter is stronger and other is weaker,
    // so the combination cannot reuse data.
    assert(byPathInclusion * byFullName == -1);
    return false;
  }
}

HeapClasses applyFilter({
  required HeapClasses nonFiltered,
  required HeapClasses? oldFiltered,
  required HeapClassFilter? oldFilter,
  required HeapClassFilter newFilter,
}) {
  if ((oldFilter == null) != (oldFiltered == null))
    throw StateError('$oldFilter does not match $oldFiltered');

  if (oldFilter == null || oldFiltered == null) {
    return _applyFilter(nonFiltered, newFilter);
  }

  if (newFilter.isStonger(oldFilter)) {
    return _applyFilter(oldFiltered, newFilter);
  } else {
    return _applyFilter(nonFiltered, newFilter);
  }
}

HeapClasses _applyFilter(
  HeapClasses classes,
  HeapClassFilter filter,
) {
  final newList = classes.classStatsList
      .map((e) => _applyFilterToItem(e, filter))
      .whereNotNull();

  return _withNewClassList(classes, newList);
}

ClassStats? _applyFilterToItem(
  ClassStats stats,
  HeapClassFilter filter,
) {
  final nameMatches = stats.heapClass.fullName.contains(filter.fullName);

  if (!filter.includePathes) return nameMatches ? stats : null;

  final matchingPathes = stats.statsByPath.entries.where(
    (entry) => entry.key.asLongString().contains(filter.fullName),
  );

  if (matchingPathes.isEmpty) return null;
  return _withNewPathSet(stats, matchingPathes);
}

ClassStats _withNewPathSet(
  ClassStats stats,
  Iterable<StatsByPathEntry> pathSet,
) {
  throw UnimplementedError();
}

HeapClasses _withNewClassList(
  HeapClasses classes,
  Iterable<ClassStats> list,
) {
  throw UnimplementedError();
}
