import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  final UserProfile profile;
  final ValueChanged<UserProfile> onProfileChanged;
  final VoidCallback onReset;

  const SettingsScreen({
    super.key,
    required this.profile,
    required this.onProfileChanged,
    required this.onReset,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Mode _mode;
  late TextEditingController _ageController;
  late bool _hasAC;
  late bool _hasHeating;
  late Set<String> _conditions;
  late TextEditingController _contactNameController;
  late TextEditingController _contactPhoneController;

  @override
  void initState() {
    super.initState();
    // Pre-fill every field from the existing profile.
    final p = widget.profile;
    _mode = p.mode;
    _ageController = TextEditingController(text: p.age?.toString() ?? '');
    _hasAC = p.hasAC;
    _hasHeating = p.hasHeating;
    _conditions = p.conditions.toSet();
    _contactNameController = TextEditingController(text: p.contactName);
    _contactPhoneController = TextEditingController(text: p.contactPhone);
  }

  @override
  void dispose() {
    _ageController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  void _save() {
    final updated = UserProfile(
      mode: _mode,
      age: int.tryParse(_ageController.text),
      hasAC: _hasAC,
      hasHeating: _hasHeating,
      conditions: _conditions.toList(),
      contactName: _contactNameController.text.trim(),
      contactPhone: _contactPhoneController.text.trim(),
    );
    widget.onProfileChanged(updated); // hand it to AppState — it saves + rebuilds
    Navigator.of(context).pop(); // close settings, back to the app
  }

  Future<void> _reset() async {
    await StorageService.clearAll();
    if (!mounted) return;
    widget.onReset(); // tell AppState to go back to onboarding
    Navigator.of(context).pop();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Mode', style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<Mode>(
            value: _mode,
            isExpanded: true,
            onChanged: (v) {
              if (v != null) setState(() => _mode = v);
            },
            items: const [
              DropdownMenuItem(value: Mode.resident, child: Text('Resident')),
              DropdownMenuItem(
                  value: Mode.outdoorWorker, child: Text('Outdoor Worker')),
              DropdownMenuItem(value: Mode.driver, child: Text('Driver')),
              DropdownMenuItem(value: Mode.caregiver, child: Text('Caregiver')),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Age'),
          ),
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
          const SizedBox(height: 8),
          const Text('Health conditions',
              style: TextStyle(fontWeight: FontWeight.bold)),
          _conditionCheckbox('heart', 'Heart condition'),
          _conditionCheckbox('respiratory', 'Respiratory (asthma/COPD)'),
          _conditionCheckbox('diabetes', 'Diabetes'),
          const SizedBox(height: 8),
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
          FilledButton(onPressed: _save, child: const Text('Save changes')),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _reset,
            child: const Text('Reset app & clear data'),
          ),
        ],
      ),
    );
  }
}