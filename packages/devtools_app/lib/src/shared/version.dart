// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:devtools_shared/devtools_shared.dart';

class FlutterVersion extends SemanticVersion {
  FlutterVersion._({
    required this.version,
    required this.channel,
    required this.repositoryUrl,
    required this.frameworkRevision,
    required this.frameworkCommitDate,
    required this.engineRevision,
    required this.dartSdkVersion,
  }) {
    final semVer = SemanticVersion.parse(version);
    major = semVer.major;
    minor = semVer.minor;
    patch = semVer.patch;
    preReleaseMajor = semVer.preReleaseMajor;
    preReleaseMinor = semVer.preReleaseMinor;
  }

  factory FlutterVersion.parse(Map<String, dynamic> json) {
    return FlutterVersion._(
      version: json['frameworkVersion'],
      channel: json['channel'],
      repositoryUrl: json['repositoryUrl'],
      frameworkRevision: json['frameworkRevisionShort'],
      frameworkCommitDate: json['frameworkCommitDate'],
      engineRevision: json['engineRevisionShort'],
      dartSdkVersion: _parseDartVersion(json['dartSdkVersion']),
    );
  }

  final String? version;

  final String? channel;

  final String? repositoryUrl;

  final String? frameworkRevision;

  final String? frameworkCommitDate;

  final String? engineRevision;

  final SemanticVersion? dartSdkVersion;

  String get flutterVersionSummary => [
        if (version != 'unknown') version,
        'channel $channel',
        repositoryUrl ?? 'unknown source',
      ].join(' • ');

  String get frameworkVersionSummary =>
      'revision $frameworkRevision • $frameworkCommitDate';

  String get engineVersionSummary => 'revision $engineRevision';

  @override
  // ignore: avoid-dynamic, necessary here.
  bool operator ==(other) {
    if (other is! FlutterVersion) return false;
    return version == other.version &&
        channel == other.channel &&
        repositoryUrl == other.repositoryUrl &&
        frameworkRevision == other.frameworkRevision &&
        frameworkCommitDate == other.frameworkCommitDate &&
        engineRevision == other.engineRevision &&
        dartSdkVersion == other.dartSdkVersion;
  }

  @override
  int get hashCode => Object.hash(
        version,
        channel,
        repositoryUrl,
        frameworkRevision,
        frameworkCommitDate,
        engineRevision,
        dartSdkVersion,
      );

  static SemanticVersion? _parseDartVersion(String? versionString) {
    if (versionString == null) return null;

    // Example Dart version string: "2.15.0 (build 2.15.0-178.1.beta)"
    const prefix = '(build ';
    final indexOfPrefix = versionString.indexOf(prefix);

    String rawVersion;
    if (indexOfPrefix != -1) {
      final startIndex = indexOfPrefix + prefix.length;
      rawVersion = versionString.substring(
        startIndex,
        versionString.length - 1,
      );
    } else {
      rawVersion = versionString;
    }
    return SemanticVersion.parse(rawVersion);
  }
}
