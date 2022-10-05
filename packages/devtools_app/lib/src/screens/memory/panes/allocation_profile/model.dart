// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:vm_service/vm_service.dart';

import '../../../vm_developer/vm_service_private_extensions.dart';
import '../../shared/heap/model.dart';

class ProfileRecord {
  ProfileRecord.fromClassHeapStats(ClassHeapStats stats)
      : heapClass = HeapClass.fromClassRef(stats.classRef),
        instances = stats.instancesCurrent ?? 0,
        totalExternalSize =
            stats.newSpace.externalSize + stats.oldSpace.externalSize,
        newExternalSize = stats.newSpace.externalSize,
        oldExternalSize = stats.oldSpace.externalSize,
        totalDartSize = stats.newSpace.size + stats.oldSpace.size,
        newDartSize = stats.newSpace.size,
        oldDartSize = stats.oldSpace.size;

  ProfileRecord.fromAllocationProfile(AllocationProfile profile)
      : heapClass = null,
        instances = null,
        totalExternalSize = profile.memoryUsage?.externalUsage ?? 0,
        newExternalSize = null,
        oldExternalSize = null,
        totalDartSize = profile.memoryUsage?.heapUsage ?? 0,
        newDartSize = null,
        oldDartSize = null;

  /// If null, the record represents total for all classes.
  final HeapClass? heapClass;

  final int? instances;

  final int? newDartSize;
  final int? oldDartSize;
  final int totalDartSize;

  final int? newExternalSize;
  final int? oldExternalSize;
  final int totalExternalSize;
}
