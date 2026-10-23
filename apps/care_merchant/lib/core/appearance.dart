import 'package:care_ui/care_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The chosen appearance: theme mode and accent colour. (Phase 5)
class AppAppearance {
  const AppAppearance({this.mode = ThemeMode.system, this.accent});

  /// Follow the device's light/dark setting by default.
  final ThemeMode mode;

  /// null keeps the app's brand colour (teal in Care-Flash, indigo in
  /// Care-Merchant).
  final AppAccent? accent;

  static const AppAppearance defaults = AppAppearance();

  /// A short label such as `System · Brand` for the profile subtitle.
  String get label {
    final modeLabel = switch (mode) {
      ThemeMode.system => 'System',
      ThemeMode.light => 'Light',
      ThemeMode.dark => 'Dark',
    };
    return '$modeLabel · ${accent?.label ?? 'Brand'}';
  }
}

/// Loads and saves the appearance in `shared_preferences` so the choice
/// survives a restart. (AGENTS.md §5: persist small things)
class AppearanceController extends Notifier<AppAppearance> {
  static const _modeKey = 'appearance.themeMode';
  static const _accentKey = 'appearance.accent';

  @override
  AppAppearance build() {
    _load();
    return AppAppearance.defaults;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mode = ThemeMode.values.asNameMap()[prefs.getString(_modeKey)];
      final accent = AppAccent.values.asNameMap()[prefs.getString(_accentKey)];
      state = AppAppearance(mode: mode ?? ThemeMode.system, accent: accent);
    } catch (_) {
      // Preferences unavailable (or the provider was disposed first): keep the
      // defaults.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    state = AppAppearance(mode: mode, accent: state.accent);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_modeKey, mode.name);
    } catch (_) {}
  }

  Future<void> setAccent(AppAccent? accent) async {
    state = AppAppearance(mode: state.mode, accent: accent);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (accent == null) {
        await prefs.remove(_accentKey);
      } else {
        await prefs.setString(_accentKey, accent.name);
      }
    } catch (_) {}
  }
}

final appearanceProvider =
    NotifierProvider<AppearanceController, AppAppearance>(
        AppearanceController.new);
