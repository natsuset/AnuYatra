/// How the app sources its data.
enum DataSource {
  /// Hive local storage with seed data — no backend required.
  local,

  /// Go REST API backend.
  remote,
}

/// Runtime configuration resolved before the widget tree boots.
///
/// Switch between [DataSource.local] and [DataSource.remote] to toggle
/// the app between offline-first seed-data mode and live API mode.
/// The rest of the app (screens, providers, routing) is unaware of
/// which source is active — all data flows through repository interfaces.
class AppConfig {
  final DataSource dataSource;

  /// Base URL for the API server (only used when [dataSource] is [DataSource.remote]).
  ///
  /// Defaults to `http://10.0.2.2:8080` for Android emulator,
  /// `http://localhost:8080` for iOS simulator / desktop.
  final String apiBaseUrl;

  const AppConfig({
    this.dataSource = DataSource.local,
    this.apiBaseUrl = 'http://localhost:8080',
  });

  bool get isRemote => dataSource == DataSource.remote;
  bool get isLocal => dataSource == DataSource.local;

  /// Android emulator preset.
  static const androidEmulator = AppConfig(
    dataSource: DataSource.remote,
    apiBaseUrl: 'http://10.0.2.2:8080',
  );

  /// iOS simulator / macOS desktop preset.
  static const iosSimulator = AppConfig(
    dataSource: DataSource.remote,
    apiBaseUrl: 'http://localhost:8080',
  );
}
