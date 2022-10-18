// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../../../../../shared/common_widgets.dart';
import '../../../../../../shared/theme.dart';
import '../../../../shared/heap/model.dart';
import '../../controller/simple_controllers.dart';

class RetainingPathView extends StatelessWidget {
  const RetainingPathView({
    super.key,
    required this.path,
    required this.controller,
  });

  final ClassOnlyHeapPath path;
  final RetainingPathController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: densePadding),
        _PathControlPane(
          controller: controller,
          path: path,
        ),
        Expanded(
          child: Padding(
            padding:
                const EdgeInsets.only(top: densePadding, left: densePadding),
            child: _PathView(path: path, controller: controller),
          ),
        ),
      ],
    );
  }
}

class _PathControlPane extends StatelessWidget {
  const _PathControlPane({required this.controller, required this.path});

  final ClassOnlyHeapPath path;
  final RetainingPathController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CopyToClipboardControl(
          dataProvider: () => path.asLongString(delimiter: '\n'),
          // We do not give success message because it pops up directly on
          // top of the path control, that makes the control anavailable
          // while message is here.
          successMessage: null,
        ),
        const SizedBox(width: denseSpacing),
        ValueListenableBuilder<bool>(
          valueListenable: controller.hideStandard,
          builder: (_, hideStandard, __) => FilterButton(
            onPressed: () =>
                controller.hideStandard.value = !controller.hideStandard.value,
            isFilterActive: hideStandard,
            message: 'Hide standard libraries',
          ),
        ),
        const SizedBox(width: denseSpacing),
        ValueListenableBuilder<bool>(
          valueListenable: controller.invert,
          builder: (_, invert, __) => ToggleButton(
            onPressed: () => controller.invert.value = !controller.invert.value,
            isSelected: invert,
            message: 'Invert the path',
            icon: Icons.turn_left,
          ),
        ),
      ],
    );
  }
}

class _PathView extends StatelessWidget {
  const _PathView({required this.path, required this.controller});

  final ClassOnlyHeapPath path;
  final RetainingPathController controller;

  @override
  Widget build(BuildContext context) {
    return DualValueListenableBuilder<bool, bool>(
      firstListenable: controller.hideStandard,
      secondListenable: controller.invert,
      builder: (_, hideStandard, invert, __) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Text(
            path.asLongString(inverted: invert, hideStandard: hideStandard),
            overflow: TextOverflow.visible,
          ),
        ),
      ),
    );
  }
}
