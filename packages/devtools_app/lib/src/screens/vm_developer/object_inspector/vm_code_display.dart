// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:string_scanner/string_scanner.dart';
import 'package:vm_service/vm_service.dart';

import '../../../shared/common_widgets.dart';
import '../../../shared/primitives/utils.dart';
import '../../../shared/split.dart';
import '../../../shared/table/table.dart';
import '../../../shared/table/table_data.dart';
import '../../../shared/theme.dart';
import '../vm_developer_common_widgets.dart';
import '../vm_service_private_extensions.dart';
import 'object_inspector_view_controller.dart';
import 'vm_object_model.dart';

abstract class _CodeColumnData extends ColumnData<Instruction> {
  _CodeColumnData(super.title, {required super.fixedWidthPx});
  _CodeColumnData.wide(super.title) : super.wide();

  @override
  bool get supportsSorting => false;
}

class _AddressColumn extends _CodeColumnData {
  _AddressColumn()
      : super(
          'Address',
          fixedWidthPx: 160,
        );

  @override
  int getValue(Instruction dataObject) {
    return int.parse(dataObject.address, radix: 16);
  }

  @override
  String getDisplayValue(Instruction dataObject) {
    final value = getValue(dataObject);
    return '0x${value.toRadixString(16).toUpperCase().padLeft(8)}';
  }
}

// TODO(bkonyi): consider coloring the background similarly to how we indicate
// code "hotness" in the debugger tab. To do this properly here, we'd need to
// modify the table column padding logic to allow for custom column rendering
// that can fill the entire column which is a can of worms I'd rather not open
// for some rather niche functionality. We can revisit this once we can use the
// table implementation from the Flutter framework.
class _ProfileTicksColumn extends _CodeColumnData {
  _ProfileTicksColumn(
    super.title, {
    required this.inclusive,
    required this.ticks,
  }) : super(fixedWidthPx: 140);

  final bool inclusive;
  final CpuProfilerTicksTable? ticks;

  @override
  int? getValue(Instruction dataObject) {
    if (ticks == null) return null;
    final tick = ticks![dataObject.unpaddedAddress];
    return inclusive ? tick?.inclusiveTicks : tick?.exclusiveTicks;
  }

  @override
  String getDisplayValue(Instruction dataObject) {
    final value = getValue(dataObject);
    if (value == null) return '';

    final percentage = percent2(value / ticks!.sampleCount);
    return '$percentage ($value)';
  }
}

class _InstructionColumn extends _CodeColumnData
    implements ColumnRenderer<Instruction> {
  _InstructionColumn()
      : super(
          'Disassembly',
          fixedWidthPx: 240,
        );

  @override
  Object? getValue(Instruction dataObject) {
    return dataObject.instruction;
  }

  @override
  Widget build(
    BuildContext context,
    Instruction data, {
    bool isRowSelected = false,
    VoidCallback? onPressed,
  }) {
    final theme = Theme.of(context);
    return Text.rich(
      style: theme.fixedFontStyle,
      _highlightAssemblyCode(
        context,
        data.instruction,
      ),
    );
  }

  String _getLastMatch(StringScanner scanner) {
    final match = scanner.lastMatch!;
    return scanner.substring(match.start, match.end);
  }

  TextSpan _buildInstructionSpanRegExp(
    ColorScheme colorScheme,
    StringScanner scanner,
  ) {
    return TextSpan(
      text: _getLastMatch(scanner),
      style: TextStyle(
        color: colorScheme.controlFlowSyntaxColor,
      ),
    );
  }

  TextSpan _buildRegisterSpan(ColorScheme colorScheme, StringScanner scanner) {
    return TextSpan(
      text: _getLastMatch(scanner),
      style: TextStyle(
        color: colorScheme.variableSyntaxColor,
      ),
    );
  }

  TextSpan _buildNumericSpan(
    ColorScheme colorScheme,
    StringScanner scanner, {
    required bool isHex,
  }) {
    final match = _getLastMatch(scanner);
    return TextSpan(
      text: isHex ? '0x${match.substring(2).toUpperCase()}' : match,
      style: TextStyle(
        color: colorScheme.numericConstantSyntaxColor,
      ),
    );
  }

  TextSpan _highlightAssemblyCode(BuildContext context, String instruction) {
    final instructionSpan = RegExp(r'[a-zA-Z]+');
    final registerRegExp = RegExp(r'[a-zA-Z0-9]{2,3}');
    final addressRegExp = RegExp(r'0x[a-fA-F0-9]+');
    final numericRegExp = RegExp(r'\d+');
    final spans = <TextSpan>[];

    final scanner = StringScanner(instruction);
    final colorScheme = Theme.of(context).colorScheme;

    // The instruction (e.g., push, movq, jl, etc) will always be first, if
    // it's present.
    if (scanner.scan(instructionSpan)) {
      spans.add(_buildInstructionSpanRegExp(colorScheme, scanner));
    }
    while (!scanner.isDone) {
      if (scanner.scan(addressRegExp)) {
        spans.add(_buildNumericSpan(colorScheme, scanner, isHex: true));
      } else if (scanner.scan(numericRegExp)) {
        spans.add(_buildNumericSpan(colorScheme, scanner, isHex: false));
      } else if (scanner.scan(registerRegExp)) {
        spans.add(_buildRegisterSpan(colorScheme, scanner));
      } else {
        spans.add(
          TextSpan(
            text: String.fromCharCode(scanner.readChar()),
          ),
        );
      }
    }
    return TextSpan(children: spans);
  }
}

class _DartObjectColumn extends _CodeColumnData
    implements ColumnRenderer<Instruction> {
  _DartObjectColumn({required this.controller}) : super.wide('Object');

  final ObjectInspectorViewController controller;

  @override
  Response? getValue(Instruction inst) => inst.object;

  @override
  Widget? build(
    BuildContext context,
    Instruction data, {
    bool isRowSelected = false,
    VoidCallback? onPressed,
  }) {
    if (data.object == null) return Container();
    return VmServiceObjectLink(
      object: data.object!,
      onTap: controller.findAndSelectNodeForObject,
    );
  }
}

/// A widget for the object inspector historyViewport displaying information
/// related to [Code] objects in the Dart VM.
class VmCodeDisplay extends StatelessWidget {
  const VmCodeDisplay({
    required this.controller,
    required this.code,
  });

  final ObjectInspectorViewController controller;
  final CodeObject code;

  @override
  Widget build(BuildContext context) {
    return Split(
      initialFractions: const [0.4, 0.6],
      axis: Axis.vertical,
      children: [
        OutlineDecoration.onlyBottom(
          child: VmObjectDisplayBasicLayout(
            controller: controller,
            object: code,
            generalDataRows: vmObjectGeneralDataRows(controller, code),
            sideCardTitle: 'Code Details',
            sideCardDataRows: _codeDetailRows(code),
          ),
        ),
        OutlineDecoration.onlyTop(
          child: CodeTable(
            code: code,
            controller: controller,
            ticks: code.ticksTable,
          ),
        ),
      ],
    );
  }

  /// Returns a list of key-value pairs (map entries)
  /// containing detailed information of a VM Func object [function].
  List<MapEntry<String, Widget Function(BuildContext)>> _codeDetailRows(
    CodeObject code,
  ) {
    return [
      selectableTextBuilderMapEntry(
        'Kind',
        code.obj.kind,
      ),
      serviceObjectLinkBuilderMapEntry(
        controller: controller,
        key: 'Function',
        object: code.obj.function!,
      ),
      serviceObjectLinkBuilderMapEntry(
        controller: controller,
        key: 'Object Pool',
        object: code.obj.objectPool,
      ),
    ];
  }
}

class CodeTable extends StatelessWidget {
  CodeTable({
    Key? key,
    required this.code,
    required this.controller,
    required this.ticks,
  }) : super(key: key);

  late final columns = <ColumnData<Instruction>>[
    _AddressColumn(),
    _InstructionColumn(),
    _DartObjectColumn(controller: controller),
    if (ticks != null) ...[
      _ProfileTicksColumn(
        'Total %',
        ticks: code.ticksTable,
        inclusive: true,
      ),
      _ProfileTicksColumn(
        'Self %',
        ticks: code.ticksTable,
        inclusive: false,
      ),
    ],
  ];

  final ObjectInspectorViewController controller;
  final CodeObject code;
  final CpuProfilerTicksTable? ticks;

  @override
  Widget build(BuildContext context) {
    return FlatTable<Instruction>(
      data: code.obj.disassembly.instructions,
      dataKey: 'vm-code-display',
      keyFactory: (instruction) => Key(instruction.address),
      columnGroups: [
        ColumnGroup.fromText(title: 'Instructions', range: const Range(0, 3)),
        if (ticks != null)
          ColumnGroup.fromText(
            title: 'Profiler Ticks',
            range: const Range(3, 5),
          ),
      ],
      columns: columns,
      defaultSortColumn: columns[0],
      defaultSortDirection: SortDirection.ascending,
    );
  }
}

/// A mapping of [Instruction] addresses to corresponding CPU profiler ticks.
class CpuProfilerTicksTable {
  CpuProfilerTicksTable.parse({
    required this.sampleCount,
    required List<dynamic> ticks,
  }) : assert(ticks.length % 3 == 0) {
    // Ticks are built up of groups of 3 elements:
    // [address, exclusiveTicks, inclusiveTicks]
    for (int i = 0; i < ticks.length; i += 3) {
      _table[ticks[i] as String] = CodeTicks(
        exclusiveTicks: ticks[i + 1],
        inclusiveTicks: ticks[i + 2],
      );
    }
  }

  /// The total number of samples in the original [CpuSamples] response.
  final int sampleCount;

  /// Retrieves CPU profiler [CodeTicks] associated with a given [Instruction]
  /// address.
  ///
  /// If no CPU samples were collected for a given instruction address, null is
  /// returned.
  CodeTicks? operator [](String address) => _table[address];

  final _table = <String, CodeTicks>{};
}

/// Tracks inclusive and exclusive CPU profiler ticks for a single
/// [Instruction].
class CodeTicks {
  const CodeTicks({
    required this.inclusiveTicks,
    required this.exclusiveTicks,
  });

  final int exclusiveTicks;
  final int inclusiveTicks;
}
