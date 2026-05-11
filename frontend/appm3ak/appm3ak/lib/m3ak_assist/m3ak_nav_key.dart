import 'package:flutter/material.dart';

/// Navigator key global pour déclencher M3AK
/// sans dépendre d'un BuildContext local (plus robuste).
final GlobalKey<NavigatorState> m3akRootNavigatorKey =
    GlobalKey<NavigatorState>();

