// Copyright 2024 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import '../../../../../shared/globals.dart';

class MemoryControlPaneController {
  bool get isGcing => _gcing;
  bool _gcing = false;

  Future<void> gc() async {
    _gcing = true;
    try {
      await serviceConnection.serviceManager.service!.getAllocationProfile(
        (serviceConnection
            .serviceManager.isolateManager.selectedIsolate.value?.id)!,
        gc: true,
      );
      notificationService.push('Successfully garbage collected.');
    } finally {
      _gcing = false;
    }
  }
}