/// API anahtarları derleme zamanında `--dart-define-from-file=env.json`
/// ile verilir. `env.json` git'e eklenmez; örnek için `env.example.json`.
class Env {
  static const geminiKey = String.fromEnvironment('GOOGLE_GEMINI_KEY');
  static const openWeatherKey = String.fromEnvironment('OPENWEATHER_API_KEY');
  static const googleMapsKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
}
