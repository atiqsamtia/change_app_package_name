import 'dart:io';

import './file_utils.dart';

class AndroidRenameSteps {
  final String newPackageName;
  String? oldPackageName;

  static const String PATH_BUILD_GRADLE = 'android/app/build.gradle';
  static const String PATH_MANIFEST = 'android/app/src/main/AndroidManifest.xml';
  static const String PATH_MANIFEST_DEBUG = 'android/app/src/debug/AndroidManifest.xml';
  static const String PATH_MANIFEST_PROFILE = 'android/app/src/profile/AndroidManifest.xml';

  static const String PATH_ACTIVITY = 'android/app/src/main/';

  AndroidRenameSteps(this.newPackageName);

  Future<void> process() async {
    if (!await File(PATH_BUILD_GRADLE).exists()) {
      print('ERROR:: build.gradle file not found, Check if you have a correct android directory present in your project'
          '\n\nrun " flutter create . " to regenerate missing files.');
      return;
    }
    String? contents = await readFileAsString(PATH_BUILD_GRADLE);

    var reg = RegExp('applicationId "(.*)"', caseSensitive: true, multiLine: false);

    var name = reg.firstMatch(contents!)!.group(1);
    oldPackageName = name;

    print("Old Package Name: $oldPackageName");

    print('Updating build.gradle File');
    await _replace(PATH_BUILD_GRADLE);

    print('Updating Main Manifest file');
    await _replace(PATH_MANIFEST);

    print('Updating Debug Manifest file');
    await _replace(PATH_MANIFEST_DEBUG);

    print('Updating Profile Manifest file');
    await _replace(PATH_MANIFEST_PROFILE);

    await updateMainActivity();
  }

  Future<void> updateMainActivity() async {
    String oldPackagePath = oldPackageName!.replaceAll('.', '/');
    String javaPath = PATH_ACTIVITY + 'java/$oldPackagePath/MainActivity.java';
    String kotlinPath = PATH_ACTIVITY + 'kotlin/$oldPackagePath/MainActivity.kt';

    String newPackagePath = newPackageName.replaceAll('.', '/');
    String newJavaPath = PATH_ACTIVITY + 'java/$newPackagePath/MainActivity.java';
    String newKotlinPath = PATH_ACTIVITY + 'kotlin/$newPackagePath/MainActivity.kt';

    if (await File(javaPath).exists()) {
      print('Project is using Java');
      print('Updating MainActivity.java');
      await _replace(javaPath);

      print('Creating New Directory Structure');
      await Directory(PATH_ACTIVITY + 'java/$newPackagePath').create(recursive: true);
      await File(javaPath).rename(newJavaPath);

      print('Deleting old directories');
      await deleteOldDirectories('java', oldPackageName!, PATH_ACTIVITY);
    } else if (await File(kotlinPath).exists()) {
      print('Project is using kotlin');
      print('Updating MainActivity.kt');
      await _replace(kotlinPath);

      print('Creating New Directory Structure');
      await Directory(PATH_ACTIVITY + 'kotlin/$newPackagePath').create(recursive: true);
      await File(kotlinPath).rename(newKotlinPath);

      print('Deleting old directories');
      await deleteOldDirectories('kotlin', oldPackageName!, PATH_ACTIVITY);
    } else {
      print('ERROR:: Unknown Directory structure, both java & kotlin files not found.');
    }
  }

  Future<void> _replace(String path) async {
    await replaceInFile(path, oldPackageName, newPackageName);
  }
}
