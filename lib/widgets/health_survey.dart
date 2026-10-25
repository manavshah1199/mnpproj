import 'package:flutter/material.dart';
import '../models/user_profile.dart';

/// The health questions, shared by onboarding and Settings.
class HealthSurvey extends StatelessWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const HealthSurvey({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Health survey',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text(
          'Check any that apply. Your answers help WeatherSafe warn you '
          'sooner, and they never leave this phone.',
        ),
        for (final q in healthQuestions.entries)
          CheckboxListTile(
            title: Text(q.value),
            value: selected.contains(q.key),
            onChanged: (checked) {
              final next = {...selected};
              if (checked == true) {
                next.add(q.key);
              } else {
                next.remove(q.key);
              }
              onChanged(next);
            },
          ),
      ],
    );
  }
}
