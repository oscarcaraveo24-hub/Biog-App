import 'package:flutter/material.dart';

import 'package:bio_g/widgets/onboarding/onboarding_asset_badge.dart';
import 'package:bio_g/widgets/shared/bio_g_glass_card.dart';
import 'package:bio_g/widgets/onboarding/onboarding_header.dart';
import 'package:bio_g/widgets/onboarding/onboarding_primary_button.dart';
import 'package:bio_g/widgets/onboarding/onboarding_shell.dart';

class CropDateStep extends StatelessWidget {
  final DateTime? selectedDate;
  final bool useFlexibleDate;
  final String? stage;
  final ValueChanged<DateTime>? onDateChanged;
  final ValueChanged<bool>? onFlexibleChanged;
  final VoidCallback? onContinue;
  final bool showScaffold;
  final bool showContinueButton;

  const CropDateStep({
    super.key,
    this.selectedDate,
    this.useFlexibleDate = false,
    this.stage,
    this.onDateChanged,
    this.onFlexibleChanged,
    this.onContinue,
    this.showScaffold = true,
    this.showContinueButton = true,
  });

  bool get _canContinue => useFlexibleDate || selectedDate != null;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime initialDate = selectedDate ?? now;
    final String title = _titleForStage(stage);
    final String toggleLabel = _toggleLabelForStage(stage);
    final String helperText = _helperTextForStage(stage);

    final Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        OnboardingHeader(
          logoAsset: OnboardingUiAssets.logo,
          title: title,
        ),
        const SizedBox(height: 24),
        BioGGlassCard(
          radius: 22,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                _formatMonthTitle(initialDate),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF526169),
                ),
              ),
              const SizedBox(height: 8),
              Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: const Color(0xFF8CAB72),
                    onPrimary: Colors.white,
                    onSurface: const Color(0xFF55646C),
                  ),
                ),
                child: CalendarDatePicker(
                  initialDate: initialDate,
                  firstDate: DateTime(now.year - 5),
                  lastDate: DateTime(now.year + 5),
                  currentDate: now,
                  onDateChanged: (DateTime value) {
                    onDateChanged?.call(value);
                    onFlexibleChanged?.call(false);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BioGGlassCard(
          radius: 22,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => onFlexibleChanged?.call(!useFlexibleDate),
            child: Row(
              children: <Widget>[
                Icon(
                  useFlexibleDate
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 28,
                  color: const Color(0xFF89B368),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    toggleLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF4F5A60),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        BioGGlassCard(
          radius: 22,
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              OnboardingAssetBadge(
                assetPath: OnboardingUiAssets.assetForStage(stage),
                size: 40,
                imageScale: 0.88,
                borderRadius: BorderRadius.circular(12),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  helperText,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.6,
                    color: Color(0xFF66737A),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (!showScaffold) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          content,
          if (showContinueButton) ...<Widget>[
            const SizedBox(height: 26),
            OnboardingPrimaryButton(
              label: 'Continuar',
              onPressed: _canContinue ? onContinue : null,
              enabled: _canContinue,
            ),
          ],
        ],
      );
    }

    return OnboardingShell(
      bottomAction: showContinueButton
          ? OnboardingPrimaryButton(
              label: 'Continuar',
              onPressed: _canContinue ? onContinue : null,
              enabled: _canContinue,
            )
          : null,
      child: content,
    );
  }

  static String _titleForStage(String? stage) {
    if (stage == 'planned') {
      return '¿Tienes una fecha estimada para sembrar?';
    }
    if (stage == 'newly_planted' ||
        stage == 'growing_tree' ||
        stage == 'near_production' ||
        stage == 'productive') {
      return '¿Recuerdas aproximadamente cuándo plantaste?';
    }
    if (stage == 'fallow' || stage == 'dormant') {
      return '¿Recuerdas aproximadamente cuándo cosechaste?';
    }
    return '¿Recuerdas aproximadamente cuándo sembraste?';
  }

  static String _toggleLabelForStage(String? stage) {
    if (stage == 'planned') {
      return 'No tengo fecha aún';
    }
    return 'No lo recuerdo muy bien';
  }

  static String _helperTextForStage(String? stage) {
    if (stage == 'planned') {
      return 'Indicar una fecha nos ayuda a ajustar mejor las recomendaciones de Bio-G. Puede cambiarse en cualquier momento.';
    }
    if (stage == 'fallow' || stage == 'dormant') {
      return 'Indicar una fecha nos ayuda a interpretar mejor el cierre del ciclo. Si no la recuerdas bien, puedes dejarla aproximada y cambiarla más adelante.';
    }
    return 'Indicar una fecha nos ayuda a ajustar mejor las recomendaciones de Bio-G. Si no lo recuerdas, coloca una fecha aproximada para darte los mejores resultados.';
  }

  static String _formatMonthTitle(DateTime date) {
    const List<String> months = <String>[
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }
}
