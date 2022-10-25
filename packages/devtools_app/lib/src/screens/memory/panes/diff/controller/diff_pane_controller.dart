// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../../../../../config_specific/import_export/import_export.dart';
import '../../../../../primitives/auto_dispose.dart';
import '../../../../../primitives/utils.dart';
import '../../../primitives/class_name.dart';
import '../../../primitives/memory_utils.dart';
import '../../../shared/heap/class_filter.dart';
import '../../../shared/heap/heap.dart';
import '../../../shared/heap/model.dart';
import 'heap_diff.dart';
import 'item_controller.dart';
import 'simple_controllers.dart';
import 'utils.dart';

class DiffPaneController extends DisposableController {
  DiffPaneController(this.snapshotTaker);

  final SnapshotTaker snapshotTaker;

  /// If true, some process is going on.
  ValueListenable<bool> get isProcessing => _isProcessing;
  final _isProcessing = ValueNotifier<bool>(false);

  final retainingPathController = RetainingPathController();

  final core = CoreData();
  late final derived = DerivedData(core);

  /// True, if the list contains snapshots, i.e. items beyond the first
  /// informational item.
  bool get hasSnapshots => core.snapshots.value.length > 1;

  // This value should never be reset. It is incremented for every snapshot that
  // is taken, and is used to assign a unique id to each [SnapshotListItem].
  int _snapshotId = 0;

  Future<void> takeSnapshot() async {
    _isProcessing.value = true;
    final future = snapshotTaker.take();
    final snapshots = core._snapshots;

    final item = SnapshotInstanceItem(
      id: _snapshotId++,
      displayNumber: _nextDisplayNumber(),
      isolateName: currentIsolateName ?? '<isolate-not-detected>',
    );

    snapshots.add(item);
    item.setHeapData(await future);

    final newElementIndex = snapshots.value.length - 1;
    core._selectedSnapshotIndex.value = newElementIndex;
    _isProcessing.value = false;
    derived._updateValues();
  }

  Future<void> clearSnapshots() async {
    final snapshots = core._snapshots;
    for (var i = 1; i < snapshots.value.length; i++) {
      snapshots.value[i].dispose();
    }
    snapshots.removeRange(1, snapshots.value.length);
    core._selectedSnapshotIndex.value = 0;
    derived._updateValues();
  }

  int _nextDisplayNumber() {
    final numbers = core._snapshots.value.map((e) => e.displayNumber);
    assert(numbers.isNotEmpty);
    return numbers.max + 1;
  }

  void deleteCurrentSnapshot() {
    final item = core.selectedItem;
    assert(item is SnapshotInstanceItem);
    item.dispose();
    final index = core.selectedSnapshotIndex.value;
    core._snapshots.removeAt(index);
    // We change the selectedIndex, because:
    // 1. It is convenient UX
    // 2. Otherwise the content will not be re-rendered.
    core._selectedSnapshotIndex.value = max(index - 1, 0);
    derived._updateValues();
  }

  void setSnapshotIndex(int index) {
    core._selectedSnapshotIndex.value = index;
    derived._updateValues();
  }

  void setDiffing(
    SnapshotInstanceItem diffItem,
    SnapshotInstanceItem? withItem,
  ) {
    diffItem.diffWith.value = withItem;
    derived._updateValues();
  }

  void applyFilter(ClassFilter filter) {
    core._classFilter.value = filter;
    derived._updateValues();
  }

  void downloadCurrentItemToCsv() {
    final classes = derived.heapClasses.value!;
    final item = core.selectedItem as SnapshotInstanceItem;
    final diffWith = item.diffWith.value;

    late String filePrefix;
    if (diffWith == null) {
      filePrefix = item.name;
    } else {
      filePrefix = '${item.name}-${diffWith.name}';
    }

    ExportController().downloadFile(
      classesToCsv(classes.classStatsList),
      type: ExportFileType.csv,
      fileName: ExportController.generateFileName(
        type: ExportFileType.csv,
        prefix: filePrefix,
      ),
    );
  }
}

/// Values that define what data to show on diff screen.
///
/// Widgets should not update the fields directly, they should use
/// [DiffPaneController] or [DerivedData] for this.
class CoreData {
  /// The list contains one item that show information and all others
  /// are snapshots.
  ValueListenable<List<SnapshotItem>> get snapshots => _snapshots;
  final _snapshots = ListValueNotifier(<SnapshotItem>[SnapshotDocItem()]);

  /// Selected snapshot.
  ValueListenable<int> get selectedSnapshotIndex => _selectedSnapshotIndex;
  final _selectedSnapshotIndex = ValueNotifier<int>(0);

  SnapshotItem get selectedItem =>
      _snapshots.value[_selectedSnapshotIndex.value];

  /// Full name for the selected class (cross-snapshot).
  HeapClassName? className;

  /// Selected retaining path (cross-snapshot).
  ClassOnlyHeapPath? path;

  /// Current class filter.
  ValueListenable<ClassFilter> get classFilter => _classFilter;
  final _classFilter = ValueNotifier(ClassFilter.empty());
}

/// Values that can be calculated from [CoreData] and notifiers that take signal
/// from widgets.
class DerivedData extends DisposableController with AutoDisposeControllerMixin {
  DerivedData(this._core) {
    _selectedItem = ValueNotifier<SnapshotItem>(_core.selectedItem);

    addAutoDisposeListener(
      selectedSingleClassStats,
      () => _setClassIfNotNull(selectedSingleClassStats.value?.heapClass),
    );
    addAutoDisposeListener(
      selectedDiffClassStats,
      () => _setClassIfNotNull(selectedDiffClassStats.value?.heapClass),
    );
    addAutoDisposeListener(
      selectedPathEntry,
      () => _setPathIfNotNull(selectedPathEntry.value?.key),
    );
  }

  final CoreData _core;

  /// Currently selected item, to take signal from the list widget.
  ValueListenable<SnapshotItem> get selectedItem => _selectedItem;
  late final ValueNotifier<SnapshotItem> _selectedItem;

  /// Classes to show.
  final heapClasses = ValueNotifier<HeapClasses?>(null);

  /// Selected single class item in snapshot, to take signal from the table widget.
  final selectedSingleClassStats = ValueNotifier<SingleClassStats?>(null);

  /// Selected diff class item in snapshot, to take signal from the table widget.
  final selectedDiffClassStats = ValueNotifier<DiffClassStats?>(null);

  /// Cllasses to show for currently selected item, if the item is diffed.
  ValueListenable<List<DiffClassStats>?> get diffClassesToShow =>
      _diffClassesToShow;
  final _diffClassesToShow = ValueNotifier<List<DiffClassStats>?>(null);

  /// Cllasses to show for currently selected item, if the item is not diffed.
  ValueListenable<List<SingleClassStats>?> get singleClassesToShow =>
      _singleClassesToShow;
  final _singleClassesToShow = ValueNotifier<List<SingleClassStats>?>(null);

  /// List of retaining paths to show for the selected class.
  final pathEntries = ValueNotifier<List<StatsByPathEntry>?>(null);

  /// Selected retaining path record in a concrete snapshot, to take signal from the table widget.
  final selectedPathEntry = ValueNotifier<StatsByPathEntry?>(null);

  /// Storage for already calculated diffs between snapshots.
  late final _diffStore = HeapDiffStore();

  /// Updates cross-snapshot class if the argument is not null.
  void _setClassIfNotNull(HeapClassName? theClass) {
    if (theClass == null || theClass == _core.className) return;
    _core.className = theClass;
    _updateValues();
  }

  /// Updates cross-snapshot path if the argument is not null.
  void _setPathIfNotNull(ClassOnlyHeapPath? path) {
    if (path == null || path == _core.path) return;
    _core.path = path;
    _updateValues();
  }

  void _assertIntegrity() {
    assert(() {
      var singleHidden = true;
      var diffHidden = true;
      var context = 'no data';
      final item = selectedItem.value;
      if (item is SnapshotInstanceItem) {
        diffHidden = item.diffWith.value == null;
        singleHidden = !diffHidden;
        context = diffHidden ? 'single' : 'diff';
      }

      assert(singleHidden || diffHidden);

      if (singleHidden) assert(selectedSingleClassStats.value == null, context);
      if (diffHidden) assert(selectedDiffClassStats.value == null, context);

      assert((singleClassesToShow.value == null) == singleHidden, context);
      assert((diffClassesToShow.value == null) == diffHidden, context);

      return true;
    }());
  }

  /// Classes for the selected snapshot with diffing applied.
  HeapClasses? _snapshotClassesAfterDiffing() {
    final theItem = _core.selectedItem;
    if (theItem is! SnapshotInstanceItem) return null;
    final heap = theItem.heap;
    if (heap == null) return null;
    final itemToDiffWith = theItem.diffWith.value;
    if (itemToDiffWith == null) return heap.classes;
    return _diffStore.compare(heap, itemToDiffWith.heap!);
  }

  void _updateClasses({
    required HeapClasses? classes,
    required HeapClassName? className,
  }) {
    final filter = _core.classFilter.value;
    if (classes is SingleHeapClasses) {
      _singleClassesToShow.value = classes.filtered(filter);
      _diffClassesToShow.value = null;
      selectedSingleClassStats.value =
          _filter(classes.classesByName[className]);
      selectedDiffClassStats.value = null;
    } else if (classes is DiffHeapClasses) {
      _singleClassesToShow.value = null;
      _diffClassesToShow.value = classes.filtered(filter);
      selectedSingleClassStats.value = null;
      selectedDiffClassStats.value = _filter(classes.classesByName[className]);
    } else if (classes == null) {
      _singleClassesToShow.value = null;
      _diffClassesToShow.value = null;
      selectedSingleClassStats.value = null;
      selectedDiffClassStats.value = null;
    } else {
      throw StateError('Unexpected type: ${classes.runtimeType}.');
    }
  }

  /// Returns [classStats] if it matches the current filter.
  T? _filter<T extends ClassStats>(T? classStats) {
    if (classStats == null) return null;
    if (_core.classFilter.value.apply(classStats.heapClass)) return classStats;
    return null;
  }

  bool _updatingValues = false;

  /// Updates fields in this instance based on the values in [core].
  void _updateValues() {
    assert(!_updatingValues);
    _updatingValues = true;

    // Set class to show.
    final classes = _snapshotClassesAfterDiffing();

    // do we need heapClasses field?
    heapClasses.value = classes;
    _updateClasses(
      classes: classes,
      className: _core.className,
    );

    // Set paths to show.
    final theClass =
        selectedSingleClassStats.value ?? selectedDiffClassStats.value;
    final thePathEntries = pathEntries.value = theClass?.statsByPathEntries;
    final paths = theClass?.statsByPath;
    StatsByPathEntry? thePathEntry;
    if (_core.path != null && paths != null && thePathEntries != null) {
      final pathStats = paths[_core.path];
      if (pathStats != null) {
        thePathEntry =
            thePathEntries.firstWhereOrNull((e) => e.key == _core.path);
      }
    }
    selectedPathEntry.value = thePathEntry;

    // Set current snapshot.
    _selectedItem.value = _core.selectedItem;

    _assertIntegrity();
    _updatingValues = false;
  }
}
