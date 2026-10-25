import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../widgets/health_survey.dart';

class OnboardingScreen extends StatefulWidget {
  final ValueChanged<UserProfile> onComplete;
  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  static const _totalSteps = 5;

  Mode _mode = Mode.resident;
  final _ageController = TextEditingController();
  JobType _jobType = JobType.notWorking;
  bool _hasAC = true;
  bool _hasHeating = true;
  Set<String> _conditions = {};
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
      jobType: _jobType,
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
            const Text('How will you use WeatherSafe?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            RadioGroup<Mode>(
              groupValue: _mode,
              onChanged: (v) => setState(() => _mode = v!),
              child: Column(
                children: [
                  for (final m in Mode.values)
                    RadioListTile<Mode>(
                      title: Text(m.label),
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
            const Text('About you',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age (optional)',
                helperText: 'Older adults and young children face more risk.',
              ),
            ),
            const SizedBox(height: 16),
            const Text('What kind of work do you do?',
                style: TextStyle(fontWeight: FontWeight.bold)),
            RadioGroup<JobType>(
              groupValue: _jobType,
              onChanged: (v) => setState(() => _jobType = v!),
              child: Column(
                children: [
                  for (final j in JobType.values)
                    RadioListTile<JobType>(
                      title: Text(j.label),
                      value: j,
                    ),
                ],
              ),
            ),
          ],
        );
      case 2:
        return ListView(
          children: [
            const Text('Your home',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
      case 3:
        return ListView(
          children: [
            HealthSurvey(
              selected: _conditions,
              onChanged: (next) => setState(() => _conditions = next),
            ),
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
}
