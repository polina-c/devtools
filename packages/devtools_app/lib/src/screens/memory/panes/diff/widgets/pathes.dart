// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../../../../primitives/utils.dart';
import '../../../../../shared/table/table.dart';
import '../../../../../shared/table/table_data.dart';
import '../../../../../shared/utils.dart';
import '../../../shared/heap/heap.dart';
import '../../../shared/heap/primitives.dart';
import '../controller/item_controller.dart';

typedef _RetainingPathRecord = MapEntry<ClassOnlyHeapPath, ObjectSetStats>;

class _RetainingPathColumn extends ColumnData<_RetainingPathRecord> {
  _RetainingPathColumn()
      : super.wide(
          'Shortest Retaining Path',
          titleTooltip: 'Class names of objects that retain'
              '\nthe instances from garbage collection.',
          alignment: ColumnAlignment.left,
        );

  @override
  String? getValue(RetainingPathRecord record) => record.key.asShortString();

  @override
  bool get supportsSorting => true;

  @override
  String getTooltip(_RetainingPathRecord record) => record.key.asLongString();
}

class _InstanceColumn extends ColumnData<RetainingPathRecord> {
  _InstanceColumn()
      : super(
          'Instances',
          titleTooltip: 'Number of instances of the class\n'
              'retained by the path.',
          fixedWidthPx: scaleByFontFactor(85.0),
          alignment: ColumnAlignment.right,
        );

  @override
  int getValue(RetainingPathRecord record) => record.value.instanceCount;

  @override
  bool get supportsSorting => true;

  @override
  bool get numeric => true;
}

class _ShallowSizeColumn extends ColumnData<RetainingPathRecord> {
  _ShallowSizeColumn()
      : super(
          'Shallow\nDart Size',
          titleTooltip: shallowSizeColumnTooltip,
          fixedWidthPx: scaleByFontFactor(85.0),
          alignment: ColumnAlignment.right,
        );

  @override
  int getValue(RetainingPathRecord record) => record.value.shallowSize;

  @override
  bool get supportsSorting => true;

  @override
  bool get numeric => true;

  @override
  String getDisplayValue(RetainingPathRecord record) => prettyPrintBytes(
        getValue(record),
        includeUnit: true,
        kbFractionDigits: 1,
      )!;
}

class _RetainedSizeColumn extends ColumnData<RetainingPathRecord> {
  _RetainedSizeColumn()
      : super(
          'Retained\nDart Size',
          titleTooltip: retainedSizeColumnTooltip,
          fixedWidthPx: scaleByFontFactor(85.0),
          alignment: ColumnAlignment.right,
        );

  @override
  int getValue(RetainingPathRecord record) => record.value.retainedSize;

  @override
  bool get supportsSorting => true;

  @override
  bool get numeric => true;

  @override
  String getDisplayValue(RetainingPathRecord record) => prettyPrintBytes(
        getValue(record),
        includeUnit: true,
        kbFractionDigits: 1,
      )!;
}

class ClassStatsRetainingPathTable extends StatelessWidget {
  const ClassStatsRetainingPathTable({
    Key? key,
    required this.data,
  }) : super(key: key);

  final SingleClassStats data;
  final ColumnSorting sorting;

  static final _shallowSizeColumn = _ShallowSizeColumn();

class _ClassStatsTableState extends State<ClassStatsTable>
    with AutoDisposeMixin {
  late final List<ColumnData<_RetainingPathRecord>> _columns;

  @override
  void didUpdateWidget(covariant ClassStatsTable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data == oldWidget.data) return;
  }

  @override
  void initState() {
    super.initState();
    assert(widget.data.isSealed);

    final _shallowSizeColumn = _ShallowSizeColumn();

    _columns = <ColumnData<_RetainingPathRecord>>[
      _RetainingPathColumn(),
      _InstanceColumn(),
      _shallowSizeColumn,
      _RetainedSizeColumn(),
    ];

    if (!widget.sorting.initialized) {
      widget.sorting
        ..direction = SortDirection.descending
        ..columnIndex = _columns.indexOf(_shallowSizeColumn)
        ..initialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlatTable<_RetainingPathRecord>(
      columns: _columns,
      data: widget.data.entries,
      keyFactory: (e) => Key(e.key.asLongString()),
      onItemSelected: (r) => {},
      sortColumn: _columns[widget.sorting.columnIndex],
      sortDirection: widget.sorting.direction,
      onSortChanged: (
        sortColumn,
        direction, {
        secondarySortColumn,
      }) =>
          setState(() {
        widget.sorting.columnIndex = _columns.indexOf(sortColumn);
        widget.sorting.direction = direction;
      }),
    );
  }
}
