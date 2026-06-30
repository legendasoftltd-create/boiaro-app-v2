import 'package:flutter_epub_viewer/flutter_epub_viewer.dart';
import 'dart:io';

void main() {
  print(EpubSource.fromFile(File('path')).runtimeType);
}
