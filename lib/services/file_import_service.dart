import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../models/question.dart';

class FileImportService {
  Future<(List<Question>, String)?> pickAndParseWithName() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    final String content;

    if (file.bytes != null) {
      content = utf8.decode(file.bytes!);
    } else if (file.path != null) {
      content = await File(file.path!).readAsString();
    } else {
      throw Exception('Cannot read file');
    }

    return (Question.parseList(content), file.name);
  }
}
