/// One cooling/warming center. Named "HelpCenter" (not "Center") on purpose —
/// Flutter already has a widget called Center, and we don't want a clash.
class HelpCenter {
  final String name;
  final String address;
  final String type; // 'cooling' | 'warming' | 'both'
  final double lat;
  final double lon;
  final int openHour;  // 24-hour, e.g. 9 = 9am
  final int closeHour; // e.g. 20 = 8pm

  HelpCenter({
    required this.name,
    required this.address,
    required this.type,
    required this.lat,
    required this.lon,
    this.openHour = 9,
    this.closeHour = 17,
  });

  factory HelpCenter.fromJson(Map<String, dynamic> json) {
    return HelpCenter(
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      type: json['type'] ?? 'both',
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      openHour: json['openHour'] ?? 9,
      closeHour: json['closeHour'] ?? 17,
    );
  }

  /// A simple "likely open now" check based on the current hour.
  bool get isOpenNow {
    final hour = DateTime.now().hour;
    return hour >= openHour && hour < closeHour;
  }
}
