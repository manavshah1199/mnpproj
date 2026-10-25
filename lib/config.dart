/// OpenWeatherMap API key for the temperature map layer.
/// Pass it when you run the app (keeps the key out of GitHub):
///   flutter run --dart-define=OWM_API_KEY=your_key_here
/// Without a key the map still works — it just has no temperature colors.
const openWeatherMapKey = String.fromEnvironment('OWM_API_KEY');
