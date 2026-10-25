import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../services/weather_sim.dart';
import '../widgets/health_survey.dart';

class SettingsScreen extends StatefulWidget {
  final UserProfile profile;
  final String accountLabel; // "Name (email)" of who is signed in
  final ValueChanged<UserProfile> onProfileChanged;
  final VoidCallback onReset;
  final VoidCallback onSignOut;

  const SettingsScreen({
    super.key,
    required this.profile,
    required this.accountLabel,
    required this.onProfileChanged,
    required this.onReset,
    required this.onSignOut,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Mode _mode;
  late TextEditingController _ageController;
  late JobType _jobType;
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
    _jobType = p.jobType;
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
      jobType: _jobType,
      hasAC: _hasAC,
      hasHeating: _hasHeating,
      conditions: _conditions.toList(),
      contactName: _contactNameController.text.trim(),
      contactPhone: _contactPhoneController.text.trim(),
      careRecipientName: widget.profile.careRecipientName,
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

  void _signOut() {
    widget.onSignOut(); // AppState shows the login screen
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Signed in as'),
              subtitle: Text(widget.accountLabel),
              trailing: TextButton(
                onPressed: _signOut,
                child: const Text('Log out'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Mode', style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<Mode>(
            value: _mode,
            isExpanded: true,
            onChanged: (v) {
              if (v != null) setState(() => _mode = v);
            },
            items: [
              for (final m in Mode.values)
                DropdownMenuItem(value: m, child: Text(m.label)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Age'),
          ),
          const SizedBox(height: 16),
          const Text('Type of job', style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<JobType>(
            value: _jobType,
            isExpanded: true,
            onChanged: (v) {
              if (v != null) setState(() => _jobType = v);
            },
            items: [
              for (final j in JobType.values)
                DropdownMenuItem(
                  value: j,
                  child: Text(j.label, overflow: TextOverflow.ellipsis),
                ),
            ],
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
          HealthSurvey(
            selected: _conditions,
            onChanged: (next) => setState(() => _conditions = next),
          ),
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
          const Text('Demo: weather simulator',
              style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButton<SimPreset>(
            value: WeatherSim.active,
            isExpanded: true,
            onChanged: (p) {
              if (p != null) setState(() => WeatherSim.active = p);
            },
            items: SimPreset.values
                .map((p) => DropdownMenuItem(
                      value: p,
                      child: Text(WeatherSim.label(p)),
                    ))
                .toList(),
          ),
          const Text(
            'After changing this, go to the Today tab and tap refresh (↻).',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
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
