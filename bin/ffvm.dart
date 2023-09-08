import 'dart:io';

import 'package:intl/intl.dart';
import 'package:pub_api_client/pub_api_client.dart';
import 'package:pubspec/pubspec.dart';

final dateFormat = DateFormat('MM/dd/yy hh:mm:ss');
const thirdPartyPackages = [
  'firebase_ui_oauth_oidc',
  'firebase_auth_mocks',
  'firebase_storage_mocks',
  'fake_cloud_firestore',
];

void main(List<String> arguments) async {
  if (arguments.length != 2) {
    print('Usage: ffvm <package> <version>');
    exit(1);
  }

  final lockPackage = arguments[0];
  final lockVersion = arguments[1];

  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('No pubspec.yaml file found');
    exit(1);
  }

  final pubspecString = pubspecFile.readAsStringSync();
  final pubspec = PubSpec.fromYamlString(pubspecString);

  print('Fetching packages created by firebase.google.com...');
  final client = PubClient();
  final ffPackages = thirdPartyPackages +
      (await client.fetchPublisherPackages('firebase.google.com'))
          .map((e) => e.package)
          .toList();
  print('Found ${ffPackages.length} packages');

  if (!ffPackages.contains(lockPackage)) {
    print('Package $lockPackage is not a firebase.google.com package');
    exit(1);
  }

  final lockVersionInfo =
      await client.packageVersionInfo(lockPackage, lockVersion);
  final lockDate = lockVersionInfo.published;
  print(
    'Lock date for $lockPackage $lockVersion is ${dateFormat.format(lockDate)}',
  );

  final ffDeps = ffPackages
      .toSet()
      .intersection(pubspec.allDependencies.keys.toSet())
    ..remove(lockPackage);

  final lockedVersions = {lockPackage: lockVersion};
  for (final package in ffDeps) {
    print('Finding appropriate version for $package...');
    final versions = await client.packageVersions(package);
    for (final version in versions) {
      final info = await client.packageVersionInfo(package, version);
      final date = info.published;
      if (isClose(lockDate, date)) {
        print('Found $package $version released on ${dateFormat.format(date)}');
        lockedVersions[package] = version;
        break;
      }
    }
    if (!lockedVersions.containsKey(package)) {
      // Use the most recent version
      lockedVersions[package] = versions.last;
    }
  }

  print('Updating pubspec.yaml...');
  var newPubspec = pubspecString;
  for (final entry in lockedVersions.entries) {
    final package = entry.key;
    final version = entry.value;

    newPubspec =
        newPubspec.replaceFirst(RegExp('$package: .+'), '$package: $version');
  }
  pubspecFile.writeAsStringSync(newPubspec);

  exit(0);
}

/// Check if [date2] is before [date1] or within 15 minutes
bool isClose(DateTime date1, DateTime date2) {
  return date2.isBefore(date1) || date2.difference(date1).inMinutes < 15;
}
