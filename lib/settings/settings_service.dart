import 'package:hive/hive.dart';

class SettingsService {
  static const _boxName = 'settings';
  static const _kFrom = 'translate_from';
  static const _kTo = 'translate_to';

  Box get _box => Hive.box(_boxName);

  String getFromCode({String fallback = 'en'}) {
    return (_box.get(_kFrom, defaultValue: fallback) as String);
  }

  String getToCode({String fallback = 'ru'}) {
    return (_box.get(_kTo, defaultValue: fallback) as String);
  }

  Future<void> setFromCode(String code) => _box.put(_kFrom, code);
  Future<void> setToCode(String code) => _box.put(_kTo, code);
}
