import 'package:flutter/material.dart';
import '../models/user_profile.dart';

class OnboardingScreen extends StatefulWidget {
  final ValueChanged<UserProfile> onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  static const _totalSteps = 4;

  Mode _mode = Mode.resident;
  final _ageController = TextEditingController();
  bool _hasAC = true;
  bool _hasHeating = true;
  final Set<String> _conditions = {};
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  @override
  void dispose() {
    _ageController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < _totalSteps - 1) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  void _finish() {
    final profile = UserProfile(
      mode: _mode,
      age: int.tryParse(_ageController.text),
      hasAC: _hasAC,
      hasHeating: _hasHeating,
      conditions: _conditions.toList(),
      contactName: _contactNameController.text.trim(),
      contactPhone: _contactPhoneController.text.trim(),
    );
    // Hand the finished profile to AppState — it saves it and shows the app.
    widget.onComplete(profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Set up (${_step + 1}/$_totalSteps)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LinearProgressIndicator(value: (_step + 1) / _totalSteps),
            const SizedBox(height: 16),
            Expanded(child: _buildStep()),
            Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _back,
                      child: const Text('Back'),
                    ),
                  ),
                if (_step > 0) const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _next,
                    child: Text(_step == _totalSteps - 1 ? 'Finish' : 'Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return ListView(
          children: [
            const Text('How will you use WeatherGuard?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            RadioGroup<Mode>(
              groupValue: _mode,
              onChanged: (v) => setState(() => _mode = v!),
              child: Column(
                children: [
                  for (final m in Mode.values)
                    RadioListTile<Mode>(
                      title: Text(_modeLabel(m)),
                      value: m,
                    ),
                ],
              ),
            ),
          ],
        );
      case 1:
        return ListView(
          children: [
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age (optional)'),
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
          ],
        );
      case 2:
        return ListView(
          children: [
            const Text('Health conditions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _conditionCheckbox('heart', 'Heart condition'),
            _conditionCheckbox('respiratory', 'Respiratory (asthma/COPD)'),
            _conditionCheckbox('diabetes', 'Diabetes'),
          ],
        );
      default:
        return ListView(
          children: [
            const Text('Trusted contact',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _contactNameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: _contactPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
          ],
        );
    }
  }

  String _modeLabel(Mode m) {
    switch (m) {
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