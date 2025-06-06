import 'package:flutter/material.dart';

class GameSetupProvider extends ChangeNotifier {
  DateTime _gameDate = DateTime.now();
  String _homeTeam = '';
  String _awayTeam = '';
  int _quarterMinutes = 15;
  bool _isCountdownTimer = true;

  DateTime get gameDate => _gameDate;
  String get homeTeam => _homeTeam;
  String get awayTeam => _awayTeam;
  int get quarterMinutes => _quarterMinutes;
  int get quarterMSec => _quarterMinutes * 60 * 1000;
  bool get isCountdownTimer => _isCountdownTimer;

  void setGameDate(DateTime date) {
    _gameDate = date;
    notifyListeners();
  }

  void setHomeTeam(String team) {
    _homeTeam = team;
    notifyListeners();
  }

  void setAwayTeam(String team) {
    _awayTeam = team;
    notifyListeners();
  }

  void setQuarterMinutes(int minutes) {
    _quarterMinutes = minutes;
    notifyListeners();
  }

  void setIsCountdownTimer(bool isCountdown) {
    _isCountdownTimer = isCountdown;
    notifyListeners();
  }

  void initializeWithDefaults(
      {int? defaultQuarterMinutes, bool? defaultIsCountdownTimer}) {
    _quarterMinutes = defaultQuarterMinutes ?? 15;
    _isCountdownTimer = defaultIsCountdownTimer ?? true;
    notifyListeners();
  }

  void reset(
      {int? defaultQuarterMinutes,
      bool? defaultIsCountdownTimer,
      String? favoriteTeam}) {
    setHomeTeam(favoriteTeam ?? '');
    setAwayTeam('');
    setGameDate(DateTime.now());
    setQuarterMinutes(defaultQuarterMinutes ?? 15);
    setIsCountdownTimer(defaultIsCountdownTimer ?? true);
    notifyListeners();
  }
}
