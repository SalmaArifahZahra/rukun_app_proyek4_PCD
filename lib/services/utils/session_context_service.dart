import 'package:rukun_app_proyek4/services/utils/hive_service.dart';

class SessionContext {
  const SessionContext({required this.rtId, required this.rtLabel});

  final int rtId;
  final String rtLabel;
}

class SessionContextService {
  static const String _boxName = 'session_context';
  static const String _rtIdKey = 'rt_id';
  static const String _rtLabelKey = 'rt_label';

  Future<void> setRTContext({
    required int rtId,
    required String rtLabel,
  }) async {
    final box = await HiveService().openBox<dynamic>(_boxName);
    await box.put(_rtIdKey, rtId);
    await box.put(_rtLabelKey, rtLabel);
  }

  Future<SessionContext> getRTContext() async {
    final box = await HiveService().openBox<dynamic>(_boxName);
    final rtId = (box.get(_rtIdKey) as int?) ?? 1;
    final rtLabel = (box.get(_rtLabelKey) as String?) ?? 'RT 001';
    return SessionContext(rtId: rtId, rtLabel: rtLabel);
  }
}
