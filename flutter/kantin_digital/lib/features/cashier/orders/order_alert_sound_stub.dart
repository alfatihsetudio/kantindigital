class OrderAlertSound {
  String soundType = 'dingdong';

  bool get isEnabled => false;

  void setSoundType(String type) {
    soundType = type;
  }

  Future<void> enableFromUserGesture({String? soundType}) async {}

  Future<void> play({String? soundType}) async {}

  void stop() {}

  void disable() {}

  void dispose() {}

  Future<void> preview(String soundType) async {}

  void stopPreview() {}
}
