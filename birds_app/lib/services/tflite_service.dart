import 'package:tflite_flutter/tflite_flutter.dart';

class TFLiteService {
  Interpreter? _interpreter;

  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('model.tflite');
    print("✅ Model loaded");
  }

  List<double> predict(List input) {
    var output = List.filled(1 * 10, 0.0).reshape([1, 10]);

    _interpreter!.run(input, output);

    return List<double>.from(output[0]);
  }
}
