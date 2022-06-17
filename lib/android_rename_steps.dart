import 'dart:async';
import 'dart:io';

import './file_utils.dart';

/// [AndroidRenameSteps] this class tray rename old package name to new package name on android module.
class AndroidRenameSteps {
  /// [newPackageName] this property contain  new package name .
  final String newPackageName;

  /// [oldPackageName] this property contain  old package name .
  String? oldPackageName;

  /// [PATH_BUILD_GRADLE]  this property contain address of build.gradle directory in app directory .
  static const String PATH_BUILD_GRADLE = 'android/app/build.gradle';

  /// [PATH_MANIFEST] this property contain address of AndroidManifest.xml in main directory of android module .
  static const String PATH_MANIFEST =
      'android/app/src/main/AndroidManifest.xml';

  /// [PATH_MANIFEST_DEBUG] this property contain address of AndroidManifest.xml in debug directory of android module .
  static const String PATH_MANIFEST_DEBUG =
      'android/app/src/debug/AndroidManifest.xml';

  /// [PATH_MANIFEST_PROFILE] this property contain address of AndroidManifest.xml in profile directory of android module .
  static const String PATH_MANIFEST_PROFILE =
      'android/app/src/profile/AndroidManifest.xml';

  /// [PATH_ACTIVITY] this property contain address of main directory of android module .
  static const String PATH_ACTIVITY = 'android/app/src/main/';

  AndroidRenameSteps(this.newPackageName);

  /// [process] this method running all steps of renaming by order.
  Future<void> process() async {
    if (!await File(PATH_BUILD_GRADLE).exists()) {
      print(
          'ERROR:: build.gradle file not found, Check if you have a correct android directory present in your project'
          '\n\nrun " flutter create . " to regenerate missing files.');
      return;
    }
    String? contents = await readFileAsString(PATH_BUILD_GRADLE);

    var reg =
        RegExp('applicationId "(.*)"', caseSensitive: true, multiLine: false);

    var name = reg.firstMatch(contents!)!.group(1);
    oldPackageName = name;

    print("Old Package Name: $oldPackageName");

    print('Updating build.gradle File');
    await _replace(PATH_BUILD_GRADLE);

    var mText = 'package="$newPackageName">';
    var mRegex = '(package.*)';

    print('Updating Main Manifest file');
    await replaceInFileRegex(PATH_MANIFEST, mRegex, mText);

    print('Updating Debug Manifest file');
    await replaceInFileRegex(PATH_MANIFEST_DEBUG, mRegex, mText);

    print('Updating Profile Manifest file');
    await replaceInFileRegex(PATH_MANIFEST_PROFILE, mRegex, mText);

    await updateMainActivity();
  }

  /// [updateMainActivity]  this method tray find and update MainActivity file.
  Future<void> updateMainActivity() async {
    var path = await findMainActivity(type: 'java');
    if (path != null) {
      processMainActivity(path, 'java');
    }

    path = await findMainActivity(type: 'kotlin');
    if (path != null) {
      processMainActivity(path, 'kotlin');
    }
  }

  /// [processMainActivity]  this method tray updating MainActivity file by rename old package name to  new package name in files and directories .
  Future<void> processMainActivity(File path, String type) async {
    var extension = type == 'java' ? 'java' : 'kt';
    print('Project is using $type');
    print('Updating MainActivity.$extension');
    await replaceInFileRegex(
        path.path, '(package.*)', "package ${newPackageName}");

    String newPackagePath = newPackageName.replaceAll('.', '/');
    String newPath = '${PATH_ACTIVITY}${type}/$newPackagePath';

    print('Creating New Directory Structure');
    await Directory(newPath).create(recursive: true);
    await path.rename(newPath + '/MainActivity.$extension');

    print('Deleting old directories');

    await deleteEmptyDirs(type);
  }

  /// [_replace] this method replace old package name to  new package name .
  Future<void> _replace(String path) async {
    await replaceInFile(path, oldPackageName, newPackageName);
  }

  /// [deleteEmptyDirs] this method delete all empty and unused old directories.
  Future<void> deleteEmptyDirs(String type) async {
    var dirs = await dirContents(Directory(PATH_ACTIVITY + type));
    dirs = dirs.reversed.toList();
    for (var dir in dirs) {
      if (dir is Directory) {
        if (dir.listSync().toList().isEmpty) {
          dir.deleteSync();
        }
      }
    }
  }

  /// [findMainActivity] this method tray to find MainActivity file.
  Future<File?> findMainActivity({String type: 'java'}) async {
    var files = await dirContents(Directory(PATH_ACTIVITY + type));
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

  /// [dirContents] this method tray to return list of java or kotlin files in specific directory .
  Future<List<FileSystemEntity>> dirContents(Directory dir) {
    var files = <FileSystemEntity>[];
    var completer = Completer<List<FileSystemEntity>>();
    var lister = dir.list(recursive: true);
    lister.listen((file) => files.add(file),
        // should also register onError
        onDone: () => completer.complete(files));
    return completer.future;
  }
}
