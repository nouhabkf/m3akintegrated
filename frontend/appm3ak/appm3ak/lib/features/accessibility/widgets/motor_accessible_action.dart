import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Wrapper MVP: élargit la zone tactile et propose un déclenchement au maintien.
class MotorAccessibleAction extends StatefulWidget {
  const MotorAccessibleAction({
    super.key,
    required this.child,
    required this.onActivate,
    required this.enabled,
    required this.magneticPadding,
    required this.dwellEnabled,
    required this.dwellMs,
  });

  final Widget child;
  final VoidCallback onActivate;
  final bool enabled;
  final double magneticPadding;
  final bool dwellEnabled;
  final int dwellMs;

  @override
  State<MotorAccessibleAction> createState() => _MotorAccessibleActionState();
}

class _MotorAccessibleActionState extends State<MotorAccessibleAction> {
  Timer? _dwellTimer;
  Timer? _tick;
  bool _holding = false;
  double _progress = 0;

  @override
  void dispose() {
    _cancelDwell();
    super.dispose();
  }

  void _cancelDwell() {
    _dwellTimer?.cancel();
    _tick?.cancel();
    _dwellTimer = null;
    _tick = null;
    if (!mounted) return;
    setState(() {
      _holding = false;
      _progress = 0;
    });
  }

  void _startDwell() {
    if (!widget.dwellEnabled) return;
    _cancelDwell();
    final start = DateTime.now();
    setState(() => _holding = true);
    _tick = Timer.periodic(const Duration(milliseconds: 40), (_) {
      if (!mounted) return;
      final elapsed = DateTime.now().difference(start).inMilliseconds;
      setState(() {
        _progress = (elapsed / widget.dwellMs).clamp(0, 1);
      });
    });
    _dwellTimer = Timer(Duration(milliseconds: widget.dwellMs), () {
      if (!mounted) return;
      HapticFeedback.selectionClick();
      widget.onActivate();
      _cancelDwell();
    });
  }

  @override
  Widget build(BuildContext context) {
    final extra = widget.enabled ? widget.magneticPadding : 0.0;
    final useGesture = widget.enabled && widget.dwellEnabled;

    Widget content = Stack(
      children: [
        widget.child,
        if (_holding && _progress > 0)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LinearProgressIndicator(value: _progress, minHeight: 2),
          ),
      ],
    );

    if (widget.enabled) {
      content = Padding(
        padding: EdgeInsets.all(extra),
        child: content,
      );
    }

    if (!useGesture) return content;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _startDwell(),
      onTapCancel: _cancelDwell,
      onTapUp: (_) => _cancelDwell(),
      child: content,
    );
  }
}
