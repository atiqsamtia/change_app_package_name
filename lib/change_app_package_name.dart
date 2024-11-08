library change_app_package_name;

import './android_rename_steps.dart';
import './ios_rename_steps.dart';

class ChangeAppPackageName {
  static Future<void> start(List<String> arguments) async {
    if (arguments.isEmpty) {
      print('New package name is missing. Please provide a package name.');
      return;
    }

    if (arguments.length == 1) {
      // No platform-specific flag, rename both Android and iOS
      print('Renaming package for both Android and iOS.');
      return await _renameBoth(arguments.first);
    }
    if (arguments.length <= 3) {
      // Check for platform-specific flags
      final argument1 = arguments.elementAt(1).toLowerCase();
      final argument2 = arguments.elementAtOrNull(2)?.toLowerCase();
      if (argument1 == '--android') {
        print('Renaming package for Android only.');
        final isRenameOnly = argument2 == '--rename-only';
        return await AndroidRenameSteps(
          newPackageName: arguments.first,
          updateActivityFiles: !isRenameOnly,
        ).process();
      }
      if (argument1 == '--ios') {
        print('Renaming package for iOS only.');
        return await IosRenameSteps(arguments.first).process();
      }

      if (argument1 == '--rename-only') {
        return await _renameBoth(arguments.first, false);
      }

      print('Invalid argument. Use "--android" or "--ios".');
    } else {
      print('Too many arguments. This package accepts only the new package name and an optional platform flag.');
    }
  }

  static Future<void> _renameBoth(
    String newPackageName, [
    bool updateActivityFiles = true,
  ]) async {
    await AndroidRenameSteps(
      newPackageName: newPackageName,
      updateActivityFiles: updateActivityFiles,
    ).process();
    await IosRenameSteps(newPackageName).process();
  }
}
