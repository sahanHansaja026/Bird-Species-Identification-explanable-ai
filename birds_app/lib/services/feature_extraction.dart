class FeatureExtraction {
  List<List<List<List<double>>>> extractDummyFeatures() {
    // Shape: [1, 128, 128, 1]
    return List.generate(
      1,
      (_) => List.generate(128, (_) => List.generate(128, (_) => [0.0])),
    );
  }
}
