part of 'extensions.dart';

extension KotlinPackageNameEscaper on String {
  String escapeKotlinKeywords() {
    return this
        .split('.')
        .map((segment) {
      if (['is', 'in', 'as'].contains(segment)) {
        return '`$segment`';
      }
      return segment;
    })
        .join('.');
  }
}
