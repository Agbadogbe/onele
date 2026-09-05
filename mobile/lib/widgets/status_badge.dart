import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Pastille de statut : pastille colorée + libellé, comme sur l'espace web.
class StatusBadge extends StatelessWidget {
  final String statut;
  final bool compact;

  const StatusBadge({super.key, required this.statut, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final couleur = statutColor(statut);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 9 : 11,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: statutColorSoft(statut),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: statutColorLine(statut)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            statutLabel(statut),
            style: TextStyle(
              color: couleur,
              fontSize: compact ? 11 : 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
