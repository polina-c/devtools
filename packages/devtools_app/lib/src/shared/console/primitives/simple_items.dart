// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../../screens/memory/shared/heap/model.dart';
import '../../memory/model.dart';
import '../../object_tree.dart';
import '../../primitives/trees.dart';

enum FlutterTreeType {
  widget, // ('Widget'),
  renderObject // ('Render');
// TODO(jacobr): add semantics, and layer trees.
}

class DartVariableData extends TreeNode<DartVariableData> {
  DartVariableData(this.variable, this.heap);

  final DartObjectNode variable;
  final AdaptedHeapData? heap;

  @override
  TreeNode<DartVariableData> shallowCopy() {
    return DartVariableData(variable, heap);
  }
}
