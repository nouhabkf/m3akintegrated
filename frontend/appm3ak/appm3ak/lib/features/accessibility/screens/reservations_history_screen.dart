import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../models/reservation.dart';
import '../services/reservation_service.dart';
import '../widgets/reservation_date_format.dart';
import '../widgets/reservation_need_catalog.dart';

/// Liste des réservations locales : onglets « À venir » / « Passées ».
class ReservationsHistoryScreen extends StatefulWidget {
  const ReservationsHistoryScreen({super.key, this.embedded = false});

  /// `true` : pas d’[AppBar] (intégration dans un onglet du module accessibilité).
  final bool embedded;

  @override
  State<ReservationsHistoryScreen> createState() =>
      _ReservationsHistoryScreenState();
}

class _ReservationsHistoryScreenState extends State<ReservationsHistoryScreen>
    with SingleTickerProviderStateMixin {
  static const Color _brandBlue = Color(0xFF1A237E);
  static const Color _brandViolet = Color(0xFF6A1B9A);

  late TabController _tabController;
  List<Reservation> _upcoming = [];
  List<Reservation> _past = [];
  bool _loading = true;
  bool _localeReady = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    await initializeDateFormatting('fr_FR');
    if (!mounted) return;
    setState(() => _localeReady = true);
    await _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final u = await ReservationService.getUpcoming();
    final p = await ReservationService.getPast();
    if (!mounted) return;
    setState(() {
      _upcoming = u;
      _past = p;
      _loading = false;
    });
  }

  Future<void> _cancel(Reservation r) async {
    await ReservationService.cancelReservation(r.id);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Réservation annulée.')),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: widget.embedded ? Colors.white : _brandBlue,
          child: TabBar(
            controller: _tabController,
            labelColor: widget.embedded ? _brandBlue : Colors.white,
            unselectedLabelColor:
                widget.embedded ? Colors.black54 : Colors.white70,
            indicatorColor:
                widget.embedded ? _brandViolet : Colors.white,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'À venir'),
              Tab(text: 'Passées'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildList(upcoming: true),
              _buildList(upcoming: false),
            ],
          ),
        ),
      ],
    );

    if (!_localeReady || _loading) {
      final loader = const Center(child: CircularProgressIndicator());
      if (widget.embedded) return loader;
      return Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () => context.pop(),
          ),
          title: const Text('Mes réservations'),
          backgroundColor: _brandBlue,
          foregroundColor: Colors.white,
        ),
        body: loader,
      );
    }

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.pop(),
        ),
        title: const Text('Mes réservations'),
        backgroundColor: _brandBlue,
        foregroundColor: Colors.white,
      ),
      body: content,
    );
  }

  Widget _buildList({required bool upcoming}) {
    final items = upcoming ? _upcoming : _past;
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 88,
                color: _brandViolet.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 16),
              Text(
                'Aucune réservation pour le moment',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _brandBlue,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                upcoming
                    ? 'Réservez un accès adapté depuis la fiche d’un lieu sur la carte.'
                    : 'Vos créneaux passés apparaîtront ici.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: _brandBlue,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final r = items[index];
          return _ReservationTile(
            reservation: r,
            showCancel: upcoming &&
                r.statut != Reservation.statutAnnulee &&
                r.statut != Reservation.statutTerminee,
            onCancel: upcoming ? () => _cancel(r) : null,
          );
        },
      ),
    );
  }
}

class _ReservationTile extends StatelessWidget {
  const _ReservationTile({
    required this.reservation,
    required this.showCancel,
    this.onCancel,
  });

  final Reservation reservation;
  final bool showCancel;
  final VoidCallback? onCancel;

  static const Color _brandBlue = Color(0xFF1A237E);

  ({Color bg, Color border, IconData icon}) _palette(String statut) {
    switch (statut) {
      case Reservation.statutEnAttente:
        return (
          bg: Colors.orange.shade50,
          border: Colors.orange.shade200,
          icon: Icons.pending_actions_rounded,
        );
      case Reservation.statutConfirmee:
        return (
          bg: Colors.green.shade50,
          border: Colors.green.shade200,
          icon: Icons.verified_rounded,
        );
      case Reservation.statutTerminee:
        return (
          bg: Colors.grey.shade100,
          border: Colors.grey.shade300,
          icon: Icons.flag_rounded,
        );
      case Reservation.statutAnnulee:
        return (
          bg: Colors.red.shade50,
          border: Colors.red.shade200,
          icon: Icons.cancel_rounded,
        );
      default:
        return (
          bg: Colors.blueGrey.shade50,
          border: Colors.blueGrey.shade200,
          icon: Icons.info_outline_rounded,
        );
    }
  }

  ({String label, Color fg, Color bg}) _badge(String statut) {
    switch (statut) {
      case Reservation.statutEnAttente:
        return (
          label: 'En attente',
          fg: const Color(0xFFE65100),
          bg: Colors.orange.shade100,
        );
      case Reservation.statutConfirmee:
        return (
          label: 'Confirmée',
          fg: const Color(0xFF1B5E20),
          bg: Colors.green.shade100,
        );
      case Reservation.statutTerminee:
        return (
          label: 'Terminée',
          fg: const Color(0xFF424242),
          bg: Colors.grey.shade300,
        );
      case Reservation.statutAnnulee:
        return (
          label: 'Annulée',
          fg: const Color(0xFFB71C1C),
          bg: Colors.red.shade100,
        );
      default:
        return (
          label: statut,
          fg: Colors.black87,
          bg: Colors.grey.shade200,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette(reservation.statut);
    final b = _badge(reservation.statut);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: p.bg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: p.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(p.icon, size: 36, color: _brandBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              reservation.placeName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: b.bg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              b.label,
                              style: TextStyle(
                                color: b.fg,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 16,
                            color: Colors.grey.shade700,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              formatReservationFrenchDateTime(
                                reservation.scheduledAt,
                              ),
                              style: TextStyle(
                                color: Colors.grey.shade800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: reservation.besoins.map((need) {
                final icon = ReservationNeedCatalog.iconForLabel(need);
                return Chip(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  avatar: Icon(icon, size: 16, color: _brandBlue),
                  label: Text(need, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.white.withValues(alpha: 0.85),
                  side: BorderSide(color: Colors.purple.shade100),
                );
              }).toList(),
            ),
            if (reservation.note != null &&
                reservation.note!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Note : ${reservation.note}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
            if (showCancel && onCancel != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onCancel,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red.shade900,
                  ),
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Annuler'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
