enum Mode {resident, outdoorWorker, driver, caregiver }

/// What kind of work the user does — changes how much weather they're exposed to.
enum JobType { indoor, outdoor, mixed, driving, notWorking }

extension ModeLabel on Mode {
  String get label {
    switch (this) {
      case Mode.resident:
        return 'Resident';
      case Mode.outdoorWorker:
        return 'Outdoor Worker';
      case Mode.driver:
        return 'Driver';
      case Mode.caregiver:
        return 'Caregiver';
    }
  }
}

extension JobTypeLabel on JobType {
  String get label {
    switch (this) {
      case JobType.indoor:
        return 'Indoors (office, store, school)';
      case JobType.outdoor:
        return 'Outdoors (construction, landscaping, delivery on foot)';
      case JobType.mixed:
        return 'Both indoors and outdoors';
      case JobType.driving:
        return 'Driving (rideshare, trucking, delivery)';
      case JobType.notWorking:
        return 'Not working / retired / student';
    }
  }
}

/// The health survey: condition code -> question shown to the user.
/// Codes are what get saved in [UserProfile.conditions].
const healthQuestions = <String, String>{
  'heart': 'Heart disease or high blood pressure',
  'respiratory': 'Asthma, COPD, or other breathing problems',
  'diabetes': 'Diabetes',
  'kidney': 'Kidney disease',
  'pregnant': 'Currently pregnant',
  'heatMeds':
      'Take medicine that affects heat tolerance (e.g. diuretics, beta blockers)',
  'mobility': 'Limited mobility — hard to leave home quickly',
  'livesAlone': 'Live alone',
};

/// Survey answers that make the body itself more sensitive to heat.
const _heatSensitiveCodes = {
  'heart', 'respiratory', 'diabetes', 'kidney', 'pregnant', 'heatMeds'};

class UserProfile {
    final Mode mode;
    final int? age;
    final JobType jobType;
    final bool hasAC;
    final bool hasHeating;
    final List<String> conditions;
    final String contactName;
    final String contactPhone;
    final String careRecipientName;

    UserProfile({
    this.mode = Mode.resident,
    this.age,
    this.jobType = JobType.notWorking,
    this.hasAC = true,
    this.hasHeating = true,
    this.conditions = const [],
    this.contactName = '',
    this.contactPhone = '',
    this.careRecipientName = '',
  });

  /// Spends real time outside for work (from mode or job type).
  bool get worksOutdoors =>
      mode == Mode.outdoorWorker ||
      jobType == JobType.outdoor ||
      jobType == JobType.mixed;

  /// Drives for work or chose Driver mode — road hazards matter most.
  bool get drives => mode == Mode.driver || jobType == JobType.driving;

  /// Older adults (65+) and young children (4 and under) are hit hardest.
  bool get isAtRiskAge => age != null && (age! >= 65 || age! <= 4);

  bool get hasHeatSensitiveCondition =>
      conditions.any(_heatSensitiveCodes.contains);

  /// Turn this profile into a Map we can save as JSON.
  Map<String, dynamic> toJson() {
    return {
      'mode': mode.name,          // enum -> its text name, e.g. "driver"
      'age': age,
      'jobType': jobType.name,
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
      jobType: JobType.values.byName(json['jobType'] ?? 'notWorking'),
      hasAC: json['hasAC'] ?? true,
      hasHeating: json['hasHeating'] ?? true,
      conditions: List<String>.from(json['conditions'] ?? []),
      contactName: json['contactName'] ?? '',
      contactPhone: json['contactPhone'] ?? '',
      careRecipientName: json['careRecipientName'] ?? '',
    );
  }
}
