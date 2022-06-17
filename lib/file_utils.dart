import 'dart:io';

/// [replaceInFile] this method get a file address and tray replace old package name to new package name  in this file .
Future<void> replaceInFile(String path, oldPackage, newPackage) async {
  String? contents = await readFileAsString(path);
  if (contents == null) {
    print('ERROR:: file at $path not found');
    return;
  }
  contents = contents.replaceAll(oldPackage, newPackage);
  await writeFileFromString(path, contents);
}

/// [replaceInFileRegex] this method get a file address and tray replace specific regex to specific string value .
Future<void> replaceInFileRegex(String path, regex, replacement) async {
  String? contents = await readFileAsString(path);
  if (contents == null) {
    print('ERROR:: file at $path not found');
    return;
  }
  contents = contents.replaceAll(RegExp(regex), replacement);
  await writeFileFromString(path, contents);
}

/// [readFileAsString] this method return file content as an string value .
Future<String?> readFileAsString(String path) async {
  var file = File(path);
  String? contents;

  if (await file.exists()) {
    contents = await file.readAsString();
  }
  return contents;
}

/// [writeFileFromString] this method write specific content to specific file .
Future<void> writeFileFromString(String path, String contents) async {
  var file = File(path);
  await file.writeAsString(contents);
}
