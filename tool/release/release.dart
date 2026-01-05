import 'dart:io';

import 'package:yaml/yaml.dart';

void main(List<String> args) async {
  print('🚀 Starting Release Process\n');

  try {
    args = ['widget_macro'];
    if (args.isEmpty) {
      throw Exception('Package name is required. Usage: dart run release.dart <packageName>');
    }

    final packageName = args.first;
    final packageDir = Directory('packages/$packageName');

    if (!packageDir.existsSync()) {
      throw Exception('Package directory not found: packages/$packageName');
    }

    // Step 1: Read pubspec.yaml and extract version info
    final pubspecFile = File('${packageDir.path}/pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      throw Exception('pubspec.yaml not found in packages/$packageName');
    }

    final pubspecContent = pubspecFile.readAsStringSync();
    final pubspec = loadYaml(pubspecContent);
    final versionName = pubspec['version'] as String;

    // Step 2: Extract changelog for this version
    print('\n📋 Extracting changelog...');
    final changelogFile = File('${packageDir.path}/CHANGELOG.md');
    if (!changelogFile.existsSync()) {
      throw Exception('CHANGELOG.md not found in packages/$packageName');
    }

    final changelogContent = changelogFile.readAsStringSync();
    final changelog = extractChangelogForVersion(changelogContent, versionName);

    if (changelog.isEmpty) {
      print('⚠️  No changelog found for version $versionName');
      if (!await confirm('Continue without changelog?')) {
        print('❌ Aborted by user');
        exit(1);
      }
    } else {
      print('📋 Changelog for v$versionName:');
      print(changelog);
      if (!await confirm('Is this changelog correct?')) {
        print('❌ Aborted by user');
        exit(1);
      }
    }

    // Step 3: Publish to pub.dev
    print('\n📦 Publishing package to pub.dev...');
    print('This will show a dry-run first.\n');

    // First do a dry-run
    final dryRunResult = await Process.run('dart', ['pub', 'publish', '--dry-run'], workingDirectory: packageDir.path);
    print(dryRunResult.stdout);
    if (dryRunResult.stderr.toString().isNotEmpty) {
      print(dryRunResult.stderr);
    }

    if (!await confirm('\nDry-run successful. Proceed with actual publishing?')) {
      print('❌ Publishing cancelled by user');
      exit(1);
    }

    // Actual publish
    print('\n📤 Publishing to pub.dev...');
    final publishResult = await Process.run(
      'dart',
      ['pub', 'publish', '--force'],
      workingDirectory: packageDir.path,
      runInShell: true,
    );

    print(publishResult.stdout);
    if (publishResult.stderr.toString().isNotEmpty) {
      print(publishResult.stderr);
    }

    if (publishResult.exitCode != 0) {
      print('❌ Publishing failed');
      exit(1);
    }

    print('✅ Package published successfully');

    // Step 4: Create GitHub release
    print('\n🎉 Creating GitHub release...');

    final tagName = '$packageName-$versionName';
    final releaseBody = changelog.isNotEmpty ? changelog : 'Release $versionName';

    // Using gh CLI to create release
    final ghInstalled = await isCommandAvailable('gh');
    if (!ghInstalled) {
      print('⚠️  GitHub CLI (gh) not found. Please install it or create the release manually.');
      print('   Tag: $tagName');
      print('   Release notes:\n$releaseBody');
      exit(0);
    }

    if (!await confirm('Create GitHub release using gh CLI?')) {
      print('❌ Aborted by user');
      print('⚠️  Tag pushed but release not created. You can create it manually on GitHub.');
      exit(1);
    }

    final releaseFile = File('.release_notes_temp.md');
    releaseFile.writeAsStringSync(releaseBody);

    try {
      await runCommand('gh', [
        'release',
        'create',
        tagName,
        '--title',
        'Release $versionName',
        '--notes-file',
        '.release_notes_temp.md',
      ]);
      print('✅ GitHub release created');
    } finally {
      if (releaseFile.existsSync()) {
        releaseFile.deleteSync();
      }
    }

    print('\n🎊 Release process completed successfully!');
    print('   Package: $packageName');
    print('   Version: $versionName');
    print('   Tag: $tagName');
    print('   Release: https://github.com/rebaz94/widget_macro/releases/tag/$tagName');
  } catch (e) {
    print('\n❌ Error: $e');
    exit(1);
  }
}

Future<bool> confirm(String message) async {
  stdout.write('$message (y/n) [y]: ');
  final input = stdin.readLineSync()?.toLowerCase().trim();
  return input == 'y' || input == 'yes' || input == '' || input == null;
}

Future<String> runCommand(String command, List<String> args) async {
  final result = await Process.run(command, args);
  if (result.exitCode != 0) {
    throw Exception('Command failed: $command ${args.join(' ')}\n${result.stderr}');
  }
  return result.stdout.toString();
}

Future<bool> isCommandAvailable(String command) async {
  try {
    await Process.run('which', [command]);
    return true;
  } catch (e) {
    return false;
  }
}

String extractChangelogForVersion(String changelog, String version) {
  // Split by ## headers
  final sections = changelog.split(RegExp(r'^##\s+', multiLine: true));

  for (final section in sections) {
    // Check if this section starts with our version (with or without brackets)
    final versionPattern = RegExp(r'^\[?' + RegExp.escape(version) + r'\]?');
    if (versionPattern.hasMatch(section)) {
      // Extract content after the first line
      final lines = section.split('\n');
      if (lines.length > 1) {
        return lines.sublist(1).join('\n').trim();
      }
    }
  }

  return '';
}
