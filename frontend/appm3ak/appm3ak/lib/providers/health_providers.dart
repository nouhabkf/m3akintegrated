import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _prefsKey = 'health_dashboard_v1';

class GlucoseReading {
  GlucoseReading({required this.at, required this.mgDl});

  final DateTime at;
  final double mgDl;

  Map<String, dynamic> toJson() => {
        'at': at.toIso8601String(),
        'mgDl': mgDl,
      };

  static GlucoseReading fromJson(Map<String, dynamic> j) => GlucoseReading(
        at: DateTime.tryParse(j['at'] as String? ?? '') ?? DateTime.now(),
        mgDl: (j['mgDl'] as num?)?.toDouble() ?? 0,
      );
}

class MedicationReminder {
  MedicationReminder({
    required this.id,
    required this.name,
    required this.hour,
    required this.minute,
    this.weekdays = const [1, 2, 3, 4, 5, 6, 7],
  });

  final String id;
  final String name;
  final int hour;
  final int minute;
  final List<int> weekdays;

  TimeOfDay get timeOfDay => TimeOfDay(hour: hour, minute: minute);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'hour': hour,
        'minute': minute,
        'weekdays': weekdays,
      };

  static MedicationReminder fromJson(Map<String, dynamic> j) =>
      MedicationReminder(
        id: j['id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        hour: j['hour'] as int? ?? 8,
        minute: j['minute'] as int? ?? 0,
        weekdays: (j['weekdays'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            const [1, 2, 3, 4, 5, 6, 7],
      );
}

class HealthDashboardState {
  const HealthDashboardState({
    this.glucose = const [],
    this.medications = const [],
    this.fastingForAnalysis = true,
  });

  final List<GlucoseReading> glucose;
  final List<MedicationReminder> medications;
  final bool fastingForAnalysis;

  GlucoseReading? get latestGlucose =>
      glucose.isEmpty ? null : glucose.reduce((a, b) => a.at.isAfter(b.at) ? a : b);

  HealthDashboardState copyWith({
    List<GlucoseReading>? glucose,
    List<MedicationReminder>? medications,
    bool? fastingForAnalysis,
  }) {
    return HealthDashboardState(
      glucose: glucose ?? this.glucose,
      medications: medications ?? this.medications,
      fastingForAnalysis: fastingForAnalysis ?? this.fastingForAnalysis,
    );
  }
}

class HealthDashboardNotifier extends StateNotifier<HealthDashboardState> {
  HealthDashboardNotifier() : super(const HealthDashboardState()) {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    final raw = p.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final g = (map['glucose'] as List<dynamic>?)
              ?.map((e) => GlucoseReading.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [];
      final m = (map['medications'] as List<dynamic>?)
              ?.map(
                (e) => MedicationReminder.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [];
      final fasting = map['fasting'] as bool? ?? true;
      state = HealthDashboardState(
        glucose: g,
        medications: m,
        fastingForAnalysis: fasting,
      );
    } catch (_) {}
  }

  Future<void> _persist() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
      _prefsKey,
      jsonEncode({
        'glucose': state.glucose.map((e) => e.toJson()).toList(),
        'medications': state.medications.map((e) => e.toJson()).toList(),
        'fasting': state.fastingForAnalysis,
      }),
    );
  }

  Future<void> addGlucose(double mgDl) async {
    var next = [
      ...state.glucose,
      GlucoseReading(at: DateTime.now(), mgDl: mgDl),
    ];
    if (next.length > 24) {
      next = next.sublist(next.length - 24);
    }
    state = state.copyWith(glucose: next);
    await _persist();
  }

  Future<void> setFasting(bool value) async {
    state = state.copyWith(fastingForAnalysis: value);
    await _persist();
  }

  Future<void> addMedication(String name, TimeOfDay time) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final med = MedicationReminder(
      id: id,
      name: name.trim(),
      hour: time.hour,
      minute: time.minute,
    );
    state = state.copyWith(medications: [...state.medications, med]);
    await _persist();
  }

  Future<void> removeMedication(String id) async {
    state = state.copyWith(
      medications: state.medications.where((m) => m.id != id).toList(),
    );
    await _persist();
  }
}

final healthDashboardProvider =
    StateNotifierProvider<HealthDashboardNotifier, HealthDashboardState>((ref) {
  return HealthDashboardNotifier();
});
