// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../../../../../config_specific/import_export/import_export.dart';
import '../../../../../primitives/auto_dispose.dart';
import '../../../../../shared/globals.dart';
import '../../../shared/heap/heap.dart';
import '../../../shared/heap/model.dart';
import 'heap_diff.dart';

abstract class SnapshotItem extends DisposableController {
  /// Number, that if shown in name, should be unique in the list.
  ///
  /// If the number is not expected to be shown in UI, it should be 0.
  int get displayNumber;

  ValueListenable<bool> get isProcessing => _isProcessing;
  final _isProcessing = ValueNotifier<bool>(false);

  /// If true, the item contains data, that can be compared and analyzed.
  bool get hasData;
}

class SnapshotDocItem extends SnapshotItem {
  @override
  int get displayNumber => 0;

  @override
  bool get hasData => false;
}

class SnapshotInstanceItem extends SnapshotItem
    with AutoDisposeControllerMixin {
  SnapshotInstanceItem({
    required Future<AdaptedHeapData?> receiver,
    required this.displayNumber,
    required this.isolateName,
    required this.diffStore,
    required this.id,
    required this.selectedClassName,
    required this.selectedPath,
  }) {
    _isProcessing.value = true;
    receiver.whenComplete(() async {
      final data = await receiver;
      if (data != null) {
        heap = AdaptedHeap(data);
        // TODO(https://github.com/flutter/devtools/issues/4539): it is unclear
        // whether preserving the selection between snapshots should be the
        // default behavior. Revisit after consulting with UXR.
        _handleSelectionChange();
        addAutoDisposeListener(
          selectedClassName,
          _handleSelectionChange,
        );
        addAutoDisposeListener(
          selectedPath,
          _handleSelectionChange,
        );
        addAutoDisposeListener(selectedDiffClassStats, () {
          selectedClassName.value = selectedDiffClassStats.value?.heapClass;
          _handleSelectionChange();
        });
        addAutoDisposeListener(selectedSingleClassStats, () {
          selectedClassName.value = selectedSingleClassStats.value?.heapClass;
          _handleSelectionChange();
        });
      }
      _isProcessing.value = false;
    });
  }

  final int id;

  final String isolateName;

  final HeapDiffStore diffStore;

  AdaptedHeap? heap;

  @override
  final int displayNumber;

  String get name => '$isolateName-$displayNumber';

  ValueListenable<SnapshotInstanceItem?> get diffWith => _diffWith;
  final _diffWith = ValueNotifier<SnapshotInstanceItem?>(null);
  void setDiffWith(SnapshotInstanceItem? value) {
    _diffWith.value = value;
    _handleSelectionChange();
  }

  final ValueNotifier<HeapClassName?> selectedClassName;

  final ValueNotifier<ClassOnlyHeapPath?> selectedPath;

  final selectedSingleClassStats = ValueNotifier<SingleClassStats?>(null);

  final selectedDiffClassStats = ValueNotifier<DiffClassStats?>(null);

  ValueListenable<ClassStats?> get selectedClassStats => _selectedClassStats;
  final _selectedClassStats = ValueNotifier<ClassStats?>(null);

  /// Selected retaining path.
  final selectedPathEntry = ValueNotifier<StatsByPathEntry?>(null);

  @override
  bool get hasData => heap != null;

  HeapClasses classesToShow() {
    final theHeap = heap!;
    final itemToDiffWith = diffWith.value;
    if (itemToDiffWith == null) return theHeap.classes;
    return diffStore.compare(theHeap, itemToDiffWith.heap!);
  }

  bool _handlingSelectionChange = false;
  void _handleSelectionChange() {
    final className = selectedClassName.value;
    // The class name is null only in the beginning when nothing is selected.
    if (className == null) return;

    if (_handlingSelectionChange) return;
    _handlingSelectionChange = true;

    if (name.contains('-3')) {
      print('handling #3');
    }

    final heapClasses = classesToShow();

    // Update what class to show.
    if (heapClasses is SingleHeapClasses) {
      selectedSingleClassStats.value =
          _selectedClassStats.value = heapClasses.classesByName[className];
      selectedDiffClassStats.value = null;
    } else if (heapClasses is DiffHeapClasses) {
      selectedDiffClassStats.value =
          _selectedClassStats.value = heapClasses.classesByName[className];
      selectedSingleClassStats.value = null;
    } else {
      throw StateError('Unexpected type: ${heapClasses.runtimeType}.');
    }

    // Update what path to show.
    StatsByPathEntry? newByPathEntry;
    final path = selectedPath.value;
    final classStats = _selectedClassStats.value;
    if (path != null && classStats != null) {
      final pathStats = classStats.statsByPath[path];
      if (pathStats != null) {
        newByPathEntry = classStats.statsByPathEntries
            .firstWhereOrNull((e) => e.key == path);
      }
    }
    selectedPathEntry.value = newByPathEntry;

    _handlingSelectionChange = false;
  }

  void downloadToCsv() {
    final csvBuffer = StringBuffer();

    // Write the headers first.
    csvBuffer.writeln(
      [
        'Class',
        'Library',
        'Instances',
        'Shallow Dart Size',
        'Retained Dart Size',
        'Short Retaining Path',
        'Full Retaining Path',
      ].map((e) => '"$e"').join(','),
    );

    // TODO(polina-c): write data to file before opening the feature.
    // // Write a row per retaining path.
    // final data = heapClassesToShow();
    // for (var classStats in data.classAnalysis) {
    //   for (var pathStats in classStats.objectsByPath.entries) {
    //     csvBuffer.writeln(
    //       [
    //         classStats.heapClass.className,
    //         classStats.heapClass.library,
    //         pathStats.value.instanceCount,
    //         pathStats.value.shallowSize,
    //         pathStats.value.retainedSize,
    //         pathStats.key.asShortString(),
    //         pathStats.key.asLongString().replaceAll('\n', ' | '),
    //       ].join(','),
    //     );
    //   }
    // }

    final file = ExportController().downloadFile(
      csvBuffer.toString(),
      type: ExportFileType.csv,
    );

    // TODO(polina-c): add the notification to ExportController.downloadFile.
    notificationService.push(successfulExportMessage(file));

    throw UnimplementedError();
  }
}
