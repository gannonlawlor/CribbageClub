import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme/theme_provider.dart';
import 'settings_service.dart';

/// How much of the opponent's hand the table shows. Either way you can tell
/// how many cards they have left — this is only how it's drawn.
enum OpponentHandDisplay {
  /// A fan of card backs mirroring your own hand.
  cards,

  /// A single card back with the number of cards on it.
  count;

  String get storageKey => name;

  static OpponentHandDisplay fromStorage(String? key) =>
      OpponentHandDisplay.values.firstWhere(
        (v) => v.name == key,
        orElse: () => OpponentHandDisplay.cards,
      );
}

class SettingsState {
  final bool soundEnabled;
  final bool hapticsEnabled;
  final AppThemeMode themeMode;
  final bool autoDeal;
  final bool autoCut;
  final bool autoGo;
  final bool autoPlayAll;
  final bool autoPlayPegging;
  final double animationSpeed;

  /// Puzzles ask for the two cards you'd throw instead of the four you'd
  /// keep — same question, the way some players think about it.
  final bool puzzlePickDiscards;

  /// Whether the opponent's hand is drawn as cards or as a count.
  final OpponentHandDisplay opponentHandDisplay;

  const SettingsState({
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.themeMode = AppThemeMode.classicDark,
    this.autoDeal = true,
    this.autoCut = true,
    this.autoGo = true,
    this.autoPlayAll = false,
    this.autoPlayPegging = true,
    this.animationSpeed = 1.0,
    this.puzzlePickDiscards = false,
    this.opponentHandDisplay = OpponentHandDisplay.cards,
  });

  SettingsState copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
    AppThemeMode? themeMode,
    bool? autoDeal,
    bool? autoCut,
    bool? autoGo,
    bool? autoPlayAll,
    bool? autoPlayPegging,
    double? animationSpeed,
    bool? puzzlePickDiscards,
    OpponentHandDisplay? opponentHandDisplay,
  }) {
    return SettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      themeMode: themeMode ?? this.themeMode,
      autoDeal: autoDeal ?? this.autoDeal,
      autoCut: autoCut ?? this.autoCut,
      autoGo: autoGo ?? this.autoGo,
      autoPlayAll: autoPlayAll ?? this.autoPlayAll,
      autoPlayPegging: autoPlayPegging ?? this.autoPlayPegging,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      puzzlePickDiscards: puzzlePickDiscards ?? this.puzzlePickDiscards,
      opponentHandDisplay: opponentHandDisplay ?? this.opponentHandDisplay,
    );
  }

  /// Scale a base duration by the animation speed setting.
  /// Higher speed = shorter duration (duration / speed).
  Duration scaleDuration(Duration base) =>
      Duration(milliseconds: (base.inMilliseconds / animationSpeed).round());
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsService _service;
  final StateController<AppThemeMode> _themeController;

  SettingsNotifier({
    required SettingsService service,
    required StateController<AppThemeMode> themeController,
    SettingsState initial = const SettingsState(),
  }) : _service = service,
       _themeController = themeController,
       super(initial);

  Future<void> setSoundEnabled(bool enabled) async {
    state = state.copyWith(soundEnabled: enabled);
    await _service.setSoundEnabled(enabled);
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    state = state.copyWith(hapticsEnabled: enabled);
    await _service.setHapticsEnabled(enabled);
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    _themeController.state = mode;
    final key = switch (mode) {
      AppThemeMode.classicDark => 'dark',
      AppThemeMode.system => 'system',
      _ => 'light',
    };
    await _service.setThemeMode(key);
  }

  Future<void> setAutoDeal(bool enabled) async {
    state = state.copyWith(autoDeal: enabled);
    await _service.setAutoDeal(enabled);
  }

  Future<void> setAutoCut(bool enabled) async {
    state = state.copyWith(autoCut: enabled);
    await _service.setAutoCut(enabled);
  }

  Future<void> setAutoGo(bool enabled) async {
    state = state.copyWith(autoGo: enabled);
    await _service.setAutoGo(enabled);
  }

  Future<void> setAutoPlayAll(bool enabled) async {
    state = state.copyWith(autoPlayAll: enabled);
    await _service.setAutoPlayAll(enabled);
  }

  Future<void> setAutoPlayPegging(bool enabled) async {
    state = state.copyWith(autoPlayPegging: enabled);
    await _service.setAutoPlayPegging(enabled);
  }

  Future<void> setAnimationSpeed(double speed) async {
    state = state.copyWith(animationSpeed: speed);
    await _service.setAnimationSpeed(speed);
  }

  Future<void> setPuzzlePickDiscards(bool enabled) async {
    state = state.copyWith(puzzlePickDiscards: enabled);
    await _service.setPuzzlePickDiscards(enabled);
  }

  Future<void> setOpponentHandDisplay(OpponentHandDisplay display) async {
    state = state.copyWith(opponentHandDisplay: display);
    await _service.setOpponentHandDisplay(display.storageKey);
  }
}

final settingsServiceProvider = Provider<SettingsService>(
  (_) => SettingsService(),
);

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) {
    final service = ref.read(settingsServiceProvider);
    final themeController = ref.read(themeProvider.notifier);
    return SettingsNotifier(
      service: service,
      themeController: themeController,
      initial: _initialSettings ?? const SettingsState(),
    );
  },
);

/// Initial settings data loaded at startup (before providers are available).
SettingsState? _initialSettings;

void setInitialSettings(SettingsState settings) {
  _initialSettings = settings;
}

SettingsState? getInitialSettings() => _initialSettings;
