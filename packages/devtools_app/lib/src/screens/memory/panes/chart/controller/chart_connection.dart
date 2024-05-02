// Copyright 2024 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:devtools_app_shared/utils.dart';
import 'package:flutter/foundation.dart';

import '../../../../../shared/globals.dart';
import '../../../../../shared/utils.dart';
import '../../../shared/primitives/memory_timeline.dart';
import '../data/primitives.dart';
import 'memory_tracker.dart';

/// Connection between chart and application.
///
/// The connection consists of listeners to events from vm and
/// ongoing requests to vm service for current memory usage.
///
/// When user pauses the chart, the data is still collected.
///
/// Does not fail in case of accidental disconnect.
///
/// All interactions between chart and vm are initiated by this class.
/// So, if this class is not instantiated, the interaction does not happen.
class ChartVmConnection extends DisposableController
    with AutoDisposeControllerMixin {
  ChartVmConnection(this.timeline, {required this.isAndroidChartVisible});

  final MemoryTimeline timeline;
  final ValueListenable<bool> isAndroidChartVisible;

  late final MemoryTracker _memoryTracker = MemoryTracker(
    timeline,
    isAndroidChartVisible: isAndroidChartVisible,
  );

  bool initialized = false;

  DebounceTimer? _polling;

  late final bool isDeviceAndroid;

  void maybeInit() async {
    if (initialized) return;

    // We do this check for cases of disconnect, in order to avoid
    // failure for initialization of `isDeviceAndroid` next line.
    if (!serviceConnection.serviceManager.connectedState.value.connected) {
      isDeviceAndroid = false;
      initialized = true;
      return;
    }

    isDeviceAndroid =
        serviceConnection.serviceManager.vm?.operatingSystem == 'android';

    addAutoDisposeListener(serviceConnection.serviceManager.connectedState, () {
      final connected =
          serviceConnection.serviceManager.connectedState.value.connected;
      if (!connected) {
        _polling?.cancel();
      }
    });

    autoDisposeStreamSubscription(
      serviceConnection.serviceManager.service!.onExtensionEvent
          .listen(_memoryTracker.onMemoryData),
    );

    autoDisposeStreamSubscription(
      serviceConnection.serviceManager.service!.onGCEvent
          .listen(_memoryTracker.onGCEvent),
    );

    _polling = DebounceTimer.periodic(
      chartUpdateDelay,
      () async {
        if (!serviceConnection.serviceManager.connectedState.value.connected) {
          return;
        }
        try {
          await _memoryTracker.pollMemory();
        } catch (e) {
          if (serviceConnection.serviceManager.connectedState.value.connected) {
            rethrow;
          }
        }
      },
    );

    initialized = true;
  }

  @override
  void dispose() {
    _polling?.cancel();
    _polling?.dispose();
    _polling = null;
    super.dispose();
  }
}
