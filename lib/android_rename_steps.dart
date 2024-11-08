import 'dart:async';
import 'dart:io';

import './file_utils.dart';

final class AndroidRenameSteps {
  final String newPackageName;
  final bool updateActivityFiles;

  static const String PATH_BUILD_GRADLE = 'android/app/build.gradle';
  static const String PATH_MANIFEST = 'android/app/src/main/AndroidManifest.xml';
  static const String PATH_MANIFEST_DEBUG = 'android/app/src/debug/AndroidManifest.xml';
  static const String PATH_MANIFEST_PROFILE = 'android/app/src/profile/AndroidManifest.xml';

  static const String PATH_ACTIVITY = 'android/app/src/main/';

  const AndroidRenameSteps({
    required this.newPackageName,
    this.updateActivityFiles = true,
  });

  Future<void> process() async {
    print("Running for android");
    if (!await File(PATH_BUILD_GRADLE).exists()) {
      print('ERROR:: build.gradle file not found, Check if you have a correct android directory present in your project'
          '\n\nrun " flutter create . " to regenerate missing files.');
      return;
    }
    final contents = await readFileAsString(PATH_BUILD_GRADLE);

    final reg = RegExp(r'applicationId\s*=?\s*"(.*)"', caseSensitive: true, multiLine: false);
    final match = reg.firstMatch(contents!);
    if (match == null) {
      print('ERROR:: applicationId not found in build.gradle file, '
          'Please file an issue on github with $PATH_BUILD_GRADLE file attached.');
      return;
    }

    final oldPackageName = match.group(1) ?? '';

    print("Old Package Name: $oldPackageName");

    print('Updating build.gradle File');
    await _replace(
      path: PATH_BUILD_GRADLE,
      oldPackageName: oldPackageName,
    );

    final mText = 'package="$newPackageName">';
    final mRegex = '(package=.*)';

    print('Updating Main Manifest file');
    await replaceInFileRegex(PATH_MANIFEST, mRegex, mText);

    print('Updating Debug Manifest file');
    await replaceInFileRegex(PATH_MANIFEST_DEBUG, mRegex, mText);

    print('Updating Profile Manifest file');
    await replaceInFileRegex(PATH_MANIFEST_PROFILE, mRegex, mText);

    if (updateActivityFiles) {
      await _updateMainActivity();
    }
    print('Finished updating android package name');
  }

  Future<void> _updateMainActivity() async {
    var path = await _findMainActivity(type: 'java');
    if (path != null) {
      _processMainActivity(path, 'java');
    }

    path = await _findMainActivity(type: 'kotlin');
    if (path != null) {
      _processMainActivity(path, 'kotlin');
    }
  }

  Future<void> _processMainActivity(File path, String type) async {
    var extension = type == 'java' ? 'java' : 'kt';
    print('Project is using $type');
    print('Updating MainActivity.$extension');
    await replaceInFileRegex(path.path, r'^(package (?:\.|\w)+)', "package ${newPackageName}");

    String newPackagePath = newPackageName.replaceAll('.', '/');
    String newPath = '${PATH_ACTIVITY}${type}/$newPackagePath';

    print('Creating New Directory Structure');
    await Directory(newPath).create(recursive: true);
    await path.rename(newPath + '/MainActivity.$extension');

    print('Deleting old directories');

    await _deleteEmptyDirs(type);
  }

  Future<void> _replace({
    required String path,
    required String oldPackageName,
  }) async {
    await replaceInFile(path, oldPackageName, newPackageName);
  }

  Future<void> _deleteEmptyDirs(String type) async {
    var dirs = await _dirContents(Directory(PATH_ACTIVITY + type));
    dirs = dirs.reversed.toList();
    for (var dir in dirs) {
      if (dir is Directory) {
        if (dir.listSync().toList().isEmpty) {
          dir.deleteSync();
        }
      }
    }
  }

  Future<File?> _findMainActivity({String type = 'java'}) async {
    var files = await _dirContents(Directory(PATH_ACTIVITY + type));
    String extension = type == 'java' ? 'java' : 'kt';
    for (var item in files) {
      if (item is File) {
        if (item.path.endsWith('MainActivity.' + extension)) {
          return item;
        }
      }
    }
    return null;
  }

  Future<List<FileSystemEntity>> _dirContents(Directory dir) {
    if (!dir.existsSync()) return Future.value([]);
    var files = <FileSystemEntity>[];
    var completer = Completer<List<FileSystemEntity>>();
    var lister = dir.list(recursive: true);
    lister.listen((file) => files.add(file),
        // should also register onError
        onDone: () => completer.complete(files));
    return completer.future;
  }
}
