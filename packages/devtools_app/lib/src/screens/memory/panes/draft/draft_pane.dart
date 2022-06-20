import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:heap_explorer/model.dart';
import '../../../../shared/globals.dart';

class DraftPane extends StatefulWidget {
  const DraftPane({Key? key}) : super(key: key);

  @override
  State<DraftPane> createState() => _DraftPaneState();
}

class _DraftPaneState extends State<DraftPane> {
  String _message = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_message),
        MaterialButton(
          child: const Text('Serialize Heap Snapshot and Copy'),
          onPressed: () async {
            setState(() {
              _message = 'taking heap snapshot...';
            });
            await Future.delayed(const Duration(milliseconds: 50));

            final isolate =
                serviceManager.isolateManager.selectedIsolate.value!;
            final graph =
                (await serviceManager.service?.getHeapSnapshotGraph(isolate))!;
            final result = jsonEncode(MtHeap.fromHeapSnapshot(graph).toJson());
            await Clipboard.setData(ClipboardData(text: result));

            setState(() {
              _message = 'copied snapshot to clipboard';
            });
          },
        ),
      ],
    );
  }
}
