// lib/widgets/dashboard/irrigation_evidence_note.dart
//
// La línea que explica por qué el Panel dice lo que dice.
//
// Criterio de aceptación del plan de cierre: "toda recomendación indica qué
// pronóstico utilizó y hasta cuándo es válida", y "con clima vencido o
// ubicación dudosa, el sistema reduce confianza o devuelve revisar; no inventa
// certeza". Esta nota es donde eso se ve.
//
// Es deliberadamente discreta: una franja bajo la tarjeta de riego, no otra
// tarjeta. El agricultor quiere saber qué hacer; el porqué está disponible sin
// competir por su atención.

import 'package:flutter/material.dart';

import 'package:bio_g/core/agro/irrigation/irrigation_types.dart';

class IrrigationEvidenceNote extends StatelessWidget {
  const IrrigationEvidenceNote({super.key, required this.decision});

  final IrrigationDecision decision;

  static const Color _ink = Color(0xFF2F3A2C);
  static const Color _muted = Color(0xFF63705E);
  static const Color _warn = Color(0xFF8A5A00);
  static const Color _warnBg = Color(0xFFFDF3DC);

  @override
  Widget build(BuildContext context) {
    final lines = <String>[];

    // Motivo principal: el primero es siempre el que más pesó.
    final observations = decision.observations;
    if (observations.isNotEmpty) {
      lines.add(observations.first.textEs);
    }

    // Clima usado y su antigüedad real.
    final weather = decision.weather;
    if (weather != null && !weather.isUnavailable) {
      lines.add(weather.freshnessLabelEs(decision.decidedAt));
    }

    // Vigencia de la propia decisión.
    final validUntil = decision.validUntil;
    if (validUntil != null) {
      final hours = validUntil.difference(decision.decidedAt).inHours;
      if (hours > 0) {
        lines.add('Válida las próximas $hours h');
      }
    }

    final limitations = decision.limitations;
    final needsAttention =
        decision.requiresConfirmation || decision.requiresHumanReview;

    if (lines.isEmpty && limitations.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: BoxDecoration(
        color: needsAttention ? _warnBg : Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: needsAttention
              ? _warn.withValues(alpha: 0.28)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                needsAttention
                    ? Icons.help_outline_rounded
                    : Icons.info_outline_rounded,
                size: 15,
                color: needsAttention ? _warn : _muted,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  '${decision.confidenceLabelEs()} · '
                  '${decision.action.labelEs}',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: needsAttention ? _warn : _muted,
                  ),
                ),
              ),
            ],
          ),
          if (lines.isNotEmpty) ...<Widget>[
            const SizedBox(height: 5),
            Text(
              lines.join(' · '),
              style: const TextStyle(
                fontSize: 12,
                height: 1.35,
                color: _ink,
              ),
            ),
          ],
          if (limitations.isNotEmpty) ...<Widget>[
            const SizedBox(height: 5),
            // Lo que el sistema reconoce NO saber. El Fundacional exige
            // declararlo, no disimularlo.
            Text(
              limitations.map((l) => l.textEs).join(' '),
              style: TextStyle(
                fontSize: 11.5,
                height: 1.35,
                fontStyle: FontStyle.italic,
                color: _muted.withValues(alpha: 0.95),
              ),
            ),
          ],
          if (decision.requiresConfirmation) ...<Widget>[
            const SizedBox(height: 6),
            const Text(
              'Confirma en campo antes de aplicar.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.3,
                fontWeight: FontWeight.w800,
                color: _warn,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
