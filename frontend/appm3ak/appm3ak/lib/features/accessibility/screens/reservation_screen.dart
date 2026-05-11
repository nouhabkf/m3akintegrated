import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Modèle de réservation utilisé uniquement dans cet écran.
/// Sérialisation JSON compatible avec les autres écrans (clé [date] complète ISO).
class Reservation {
  Reservation({
    required this.id,
    required this.placeName,
    required this.date,
    required this.heure,
    required this.besoins,
    required this.note,
    required this.statut,
    required this.createdAt,
  });

  final String id;
  final String placeName;
  final DateTime date;
  final TimeOfDay heure;
  final List<String> besoins;
  final String? note;
  final String statut;
  final DateTime createdAt;

  /// Convertit au format persisté `{ id, placeName, date, heure, besoins, note, statut, createdAt }`.
  Map<String, dynamic> toPersistMap() {
    final dt = DateTime(
      date.year,
      date.month,
      date.day,
      heure.hour,
      heure.minute,
    );
    final heureStr =
        '${heure.hour.toString().padLeft(2, '0')}:${heure.minute.toString().padLeft(2, '0')}';
    return {
      'id': id,
      'placeName': placeName,
      'date': dt.toIso8601String(),
      'heure': heureStr,
      'besoins': besoins,
      'note': note,
      'statut': statut,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Sauve une réservation avec les autres sous la clé [prefsKey].
  static Future<void> appendToPrefs(Reservation r, {String prefsKey = 'reservations'}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(prefsKey);
    List<dynamic> list = [];
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List<dynamic>) list = decoded;
      } catch (_) {}
    }
    list.add(r.toPersistMap());
    await prefs.setString(prefsKey, jsonEncode(list));
  }
}

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({
    super.key,
    required this.placeName,
  });

  final String placeName;

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  static const Color _bg = Color(0xFF1A1A2E);
  static const Color _appBarBg = Color(0xFF16213E);

  static const List<String> _besoinsChoices = [
    'Accompagnement',
    'Rampe mobile',
    'Place réservée',
    'Interprète LSF',
    'Alerte audio',
    'Assistance admin',
  ];

  int _currentStep = 0;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  final List<String> _selectedBesoins = [];
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _selectedTime = TimeOfDay.fromDateTime(now);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _formatDate(BuildContext context) {
    final d = _selectedDate;
    return MaterialLocalizations.of(context).formatFullDate(d);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = DateTime(picked.year, picked.month, picked.day));
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _onConfirm() async {
    final r = Reservation(
      id: DateTime.now().toString(),
      placeName: widget.placeName.isEmpty ? 'Lieu' : widget.placeName,
      date: _selectedDate,
      heure: _selectedTime,
      besoins: List<String>.from(_selectedBesoins),
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      statut: 'confirmee',
      createdAt: DateTime.now(),
    );
    await Reservation.appendToPrefs(r);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Réservation confirmée !'),
        behavior: SnackBarBehavior.floating,
      ),
    );

    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onDark = theme.copyWith(
      canvasColor: _bg,
      scaffoldBackgroundColor: _bg,
      textTheme: theme.textTheme.apply(
        bodyColor: Colors.white70,
        displayColor: Colors.white,
      ),
      colorScheme: theme.colorScheme.copyWith(
        primary: Colors.white,
        onSurface: Colors.white,
        surface: _bg,
      ),
    );

    return Theme(
      data: onDark,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text('Réserver un accès adapté'),
          backgroundColor: _appBarBg,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: BackButton(
            onPressed: () => context.pop(),
          ),
        ),
        body: Stepper(
          type: StepperType.horizontal,
          currentStep: _currentStep,
          onStepTapped: (index) => setState(() => _currentStep = index.clamp(0, 2)),
          controlsBuilder: (context, details) => const SizedBox.shrink(),
          steps: [
            Step(
              title: const Text('Quand ?'),
              isActive: _currentStep == 0,
              state:
                  _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: _stepWhen(context),
            ),
            Step(
              title: const Text('Vos besoins'),
              isActive: _currentStep == 1,
              state: _currentStep > 1
                  ? StepState.complete
                  : (_currentStep < 1
                      ? StepState.disabled
                      : StepState.indexed),
              content: _stepBesoins(context),
            ),
            Step(
              title: const Text('Confirmation'),
              isActive: _currentStep == 2,
              state:
                  _currentStep == 2 ? StepState.complete : StepState.indexed,
              content: _stepConfirm(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepWhen(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: _appBarBg,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today_rounded),
                iconColor: Colors.white70,
                textColor: Colors.white,
                title: const Text('Date'),
                subtitle: Text(
                  _formatDate(context),
                  style: const TextStyle(color: Colors.white70),
                ),
                onTap: _pickDate,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.access_time_rounded),
                iconColor: Colors.white70,
                textColor: Colors.white,
                title: const Text('Heure'),
                subtitle: Text(
                  _selectedTime.format(context),
                  style: const TextStyle(color: Colors.white70),
                ),
                onTap: _pickTime,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => setState(() => _currentStep = 1),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF16213E),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
          child: const Text('Suivant'),
        ),
      ],
    );
  }

  Widget _stepBesoins(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Sélectionnez un ou plusieurs besoins',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _besoinsChoices.map((b) {
            final sel = _selectedBesoins.contains(b);
            return FilterChip(
              label: Text(b),
              selected: sel,
              selectedColor: const Color(0xFF6A1B9A).withValues(alpha: 0.55),
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(color: sel ? Colors.white : Colors.white70),
              onSelected: (v) {
                setState(() {
                  if (v) {
                    _selectedBesoins.add(b);
                  } else {
                    _selectedBesoins.remove(b);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _noteController,
          cursorColor: Colors.white,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Note optionnelle',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
            filled: true,
            fillColor: _appBarBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6A1B9A), width: 2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => _currentStep = 0),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white24,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Précédent'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _selectedBesoins.isEmpty
                    ? null
                    : () => setState(() => _currentStep = 2),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16213E),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Suivant'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _stepConfirm(BuildContext context) {
    final note = _noteController.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: _appBarBg,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.placeName.isEmpty ? 'Lieu' : widget.placeName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Date : ${_formatDate(context)}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 4),
                Text(
                  'Heure : ${_selectedTime.format(context)}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Text(
                  'Besoins : ${_selectedBesoins.isEmpty ? '—' : _selectedBesoins.join(', ')}',
                  style: const TextStyle(color: Colors.white70),
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Note : $note',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed:
              _selectedBesoins.isEmpty ? null : _onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A237E),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
          ),
          child: const Text('Confirmer'),
        ),
        const SizedBox(height: 8),
        Align(
          child: TextButton(
            onPressed: () => setState(() => _currentStep = 0),
            child: Text(
              'Modifier',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
            ),
          ),
        ),
      ],
    );
  }
}
