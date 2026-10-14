import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

class PreferencesService {
  final SharedPreferences _prefs;

  PreferencesService(this._prefs);

  static Future<PreferencesService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesService(prefs);
  }

  bool get isBiometricEnabled =>
      _prefs.getBool(AppConstants.keyBiometricEnabled) ?? false;

  Future<bool> setBiometricEnabled(bool value) =>
      _prefs.setBool(AppConstants.keyBiometricEnabled, value);

  bool get hasPin => _prefs.getBool(AppConstants.keyHasPin) ?? false;

  Future<bool> setHasPin(bool value) =>
      _prefs.setBool(AppConstants.keyHasPin, value);

  String? get savedUsername => _prefs.getString(AppConstants.keyUsername);

  Future<bool> setSavedUsername(String username) =>
      _prefs.setString(AppConstants.keyUsername, username);

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
