import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/theme/theme_provider.dart';
import 'settings_service.dart';

class SettingsState {
  final bool soundEnabled;
  final bool hapticsEnabled;
  final AppThemeMode themeMode;

  const SettingsState({
    this.soundEnabled = true,
    this.hapticsEnabled = true,
    this.themeMode = AppThemeMode.classicLight,
  });

  SettingsState copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
    AppThemeMode? themeMode,
  }) {
    return SettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SettingsService _service;
  final StateController<AppThemeMode> _themeController;

  SettingsNotifier({
    required SettingsService service,
    required StateController<AppThemeMode> themeController,
    SettingsState initial = const SettingsState(),
  })  : _service = service,
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
    final key = mode == AppThemeMode.classicDark ? 'dark' : 'light';
    await _service.setThemeMode(key);
  }
}

final settingsServiceProvider = Provider<SettingsService>((_) => SettingsService());

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final service = ref.read(settingsServiceProvider);
  final themeController = ref.read(themeProvider.notifier);
  return SettingsNotifier(
    service: service,
    themeController: themeController,
    initial: _initialSettings ?? const SettingsState(),
  );
});

/// Initial settings data loaded at startup (before providers are available).
SettingsState? _initialSettings;

void setInitialSettings(SettingsState settings) {
  _initialSettings = settings;
}

SettingsState? getInitialSettings() => _initialSettings;
