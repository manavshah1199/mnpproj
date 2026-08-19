import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';

/// Collects the user's info, saves it, then hands the finished
/// profile back to the caller (which swaps this screen out for Home).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onComplete});

  final ValueChanged<UserProfile> onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  // These variables hold the user's answers as they fill the form.
  Mode _mode = Mode.resident;
  final _ageController = TextEditingController();
  bool _hasAC = true;
  bool _hasHeating = true;
  final Set<String> _conditions = {};
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  // Clean up controllers when the screen is destroyed (good habit).
  @override
  void dispose() {
    _ageController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  // Runs when the user taps "Finish setup".
  Future<void> _finish() async {
    final profile = UserProfile(
      mode: _mode,
      age: int.tryParse(_ageController.text), // null if blank/not a number
      hasAC: _hasAC,
      hasHeating: _hasHeating,
      conditions: _conditions.toList(),
      contactName: _contactNameController.text.trim(),
      contactPhone: _contactPhoneController.text.trim(),
    );
    await StorageService.saveProfile(profile);
    if (!mounted) return; // safety check after an await
    widget.onComplete(profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set up WeatherGuard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('How will you use WeatherGuard?',
              style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<Mode>(
            value: _mode,
            isExpanded: true,
            onChanged: (value) {
              if (value != null) setState(() => _mode = value);
            },
            items: const [
              DropdownMenuItem(value: Mode.resident, child: Text('Resident')),
              DropdownMenuItem(
                  value: Mode.outdoorWorker, child: Text('Outdoor Worker')),
              DropdownMenuItem(value: Mode.driver, child: Text('Driver')),
              DropdownMenuItem(value: Mode.caregiver, child: Text('Caregiver')),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Age (optional)'),
          ),
          const SizedBox(height: 8),

          SwitchListTile(
            title: const Text('I have air conditioning'),
            value: _hasAC,
            onChanged: (v) => setState(() => _hasAC = v),
          ),
          SwitchListTile(
            title: const Text('I have reliable heating'),
            value: _hasHeating,
            onChanged: (v) => setState(() => _hasHeating = v),
          ),
          const SizedBox(height: 16),

          const Text('Health conditions',
              style: TextStyle(fontWeight: FontWeight.bold)),
          _conditionCheckbox('heart', 'Heart condition'),
          _conditionCheckbox('respiratory', 'Respiratory (asthma/COPD)'),
          _conditionCheckbox('diabetes', 'Diabetes'),
          const SizedBox(height: 16),

          TextField(
            controller: _contactNameController,
            decoration: const InputDecoration(labelText: 'Trusted contact name'),
          ),
          TextField(
            controller: _contactPhoneController,
            keyboardType: TextInputType.phone,
            decoration:
                const InputDecoration(labelText: 'Trusted contact phone'),
          ),
          const SizedBox(height: 24),

          FilledButton(
            onPressed: _finish,
            child: const Text('Finish setup'),
          ),
        ],
      ),
    );
  }

  // A reusable checkbox row for one health condition.
  Widget _conditionCheckbox(String code, String label) {
    return CheckboxListTile(
      title: Text(label),
      value: _conditions.contains(code),
      onChanged: (checked) {
        setState(() {
          if (checked == true) {
            _conditions.add(code);
          } else {
            _conditions.remove(code);
          }
        });
      },
    );
  }
}
