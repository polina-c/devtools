// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// TODO(jacobr): add render, semantics, and layer trees.
enum FlutterTreeType {
  widget('Widget');

  const FlutterTreeType(this.title);

  final String title;
}
