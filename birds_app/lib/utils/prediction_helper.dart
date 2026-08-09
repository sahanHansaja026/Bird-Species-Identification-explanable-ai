import 'constants.dart';

class PredictionHelper {
  String getBirdName(List<double> output) {
    int maxIndex = 0;
    double maxValue = output[0];

    for (int i = 1; i < output.length; i++) {
      if (output[i] > maxValue) {
        maxValue = output[i];
        maxIndex = i;
      }
    }

    return AppConstants.labels[maxIndex];
  }
}
