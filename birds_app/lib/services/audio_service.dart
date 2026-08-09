import 'dart:io';
import 'package:file_picker/file_picker.dart';

class AudioService {
  Future<File?> pickAudio() async {
    FilePickerResult? result = await FilePicker.pickFiles(type: FileType.audio);

    if (result != null) {
      return File(result.files.single.path!);
    }
    return null;
  }
}
