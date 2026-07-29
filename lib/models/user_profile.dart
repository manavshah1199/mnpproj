enum Mode {resident, outdoorWorker, driver, caregiver }
class UserProfile {
    final Mode mode; 
    final int? age; 
    final bool hasAC;
    final bool hasHeating; 
    final List<String> conditions; 
    final String contactName; 
    final String contactPhone;
    final String careRecipientName;

    UserProfile({
    this.mode = Mode.resident,
    this.age,
    this.hasAC = true,
    this.hasHeating = true,
    this.conditions = const [],
    this.contactName = '',
    this.contactPhone = '',
    this.careRecipientName = '',
  });

  /// Turn this profile into a Map we can save as JSON.
  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,          // enum -> its text name, e.g. "driver"
      'age': age,
      'hasAC': hasAC,
      'hasHeating': hasHeating,
      'conditions': conditions,
      'contactName': contactName,
      'contactPhone': contactPhone,
      'careRecipientName': careRecipientName,
    };
  }

  /// Rebuild a profile from saved JSON.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      mode: Mode.values.byName(json['mode'] ?? 'resident'),
      age: json['age'] as int?,
      hasAC: json['hasAC'] ?? true,
      hasHeating: json['hasHeating'] ?? true,
      conditions: List<String>.from(json['conditions'] ?? []),
      contactName: json['contactName'] ?? '',
      contactPhone: json['contactPhone'] ?? '',
      careRecipientName: json['careRecipientName'] ?? '',
    );
  }
}