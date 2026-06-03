import 'package:hive_flutter/hive_flutter.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();

  factory HiveService() => _instance;
  HiveService._internal();

  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    await Hive.initFlutter();

    _isInitialized = true;
  }

  Future<void> initForTest(String path) async {
    if (_isInitialized) {
      await Hive.close();
      _isInitialized = false;
    }

    Hive.init(path);
    _isInitialized = true;
  }

  Future<void> resetForTest() async {
    if (_isInitialized) {
      await Hive.close();
    }
    _isInitialized = false;
  }

  Future<Box<T>> openBox<T>(String name) async {
    if (!_isInitialized) {
      await init();
    }

    return await Hive.openBox<T>(name);
  }

  Future<void> close() async {
    await Hive.close();
  }
}
