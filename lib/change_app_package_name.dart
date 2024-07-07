library change_app_package_name;

import './android_rename_steps.dart';
import './ios_rename_steps.dart';

class ChangeAppPackageName {
  static void start(List<String> arguments) async {
    if (arguments.isEmpty) {
      print('New package name is missing in paraments. please try again.');
    } else if (arguments.length > 1) {
      print('Wrong arguments, this package accepts only new package name');
    } else {
      await AndroidRenameSteps(arguments[0]).process();
      await IosRenameSteps(arguments[0]).process();
    }
  }
}
