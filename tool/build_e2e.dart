// Copyright 2022 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

const argDevToolsBuild = 'devtools-build';
const argUpdatePerfetto = '--update-perfetto';
const argNoUpdateFlutter = '--no-update-flutter';

void main(List<String> args) async {
  final shouldUpdatePerfetto = args.contains(argUpdatePerfetto);
  final noUpdateFlutter = args.contains(argNoUpdateFlutter);

  final argsCopy = List.of(args)
    ..remove(argUpdatePerfetto)
    ..remove(argNoUpdateFlutter);

  final mainDevToolsDirectory = Directory.current;
  if (!mainDevToolsDirectory.path.endsWith('/devtools')) {
    throw Exception('Please execute this script from your top level '
        '\'devtools/\' directory.');
  }

  final localDartSdkLocation = Platform.environment['LOCAL_DART_SDK'];
  if (localDartSdkLocation == null) {
    throw Exception('LOCAL_DART_SDK environment variable not set. Please add '
        'the following to your \'.bash_profile\' or \'.bash_rc\' file:\n'
        'export LOCAL_DART_SDK=<absolute/path/to/my/dart/sdk>');
  }

  print('Running the build_release.sh script...');
  final buildProcess = await Process.start(
    './tool/build_release.sh',
    [
      if (shouldUpdatePerfetto) argUpdatePerfetto,
      if (noUpdateFlutter) argNoUpdateFlutter,
    ],
    workingDirectory: mainDevToolsDirectory.path,
  );
  _forwardOutputStreams(buildProcess);
  final buildProcessExitCode = await buildProcess.exitCode;
  if (buildProcessExitCode == 1) {
    throw Exception(
      'Something went wrong while running `tool/build_release.sh.',
    );
  }

  final devToolsBuildLocation =
      '${mainDevToolsDirectory.path}/packages/devtools_app/build/web';

  print('Completed building DevTools: $devToolsBuildLocation');

  print('Run pub get for DDS in local dart sdk');
  await Process.start(
    'dart',
    ['pub', 'get'],
    workingDirectory: '$localDartSdkLocation/pkg/dds',
  );

  print('Serving DevTools with a local devtools server...');
  final serveProcess = await Process.start(
    'dart',
    [
      'pkg/dds/tool/devtools_server/serve_local.dart',
      '--devtools-build=$devToolsBuildLocation',
      // Pass any args that were provided to our script along. This allows IDEs
      // to pass `--machine` (etc.) so that this script can behave the same as
      // the "dart devtools" command for testing local DevTools/server changes.
      ...argsCopy,
    ],
    workingDirectory: localDartSdkLocation,
  );
  _forwardOutputStreams(serveProcess);
  _forwardInputStream(serveProcess);
  await serveProcess.exitCode;
}

void _forwardOutputStreams(Process process) {
  process.stdout.listen(stdout.add);
  process.stderr.listen(stdout.add);
}

void _forwardInputStream(Process process) {
  stdin.listen(process.stdin.add);
}
