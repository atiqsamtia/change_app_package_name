library change_app_package_name;

import './android_rename_steps.dart';

/// [ChangeAppPackageName] this is main class of package and rename current package name.
class ChangeAppPackageName {
  /// [start] this method get new package name and start renaming package name steps.
  static void start(List<String> arguments) {
    if (arguments.isEmpty) {
      print('New package name is missing in paraments. please try again.');
    } else if (arguments.length > 1) {
      print('Wrong arguments, this package accepts only new package name');
    } else {
      AndroidRenameSteps(arguments[0]).process();
    }
  }
}
