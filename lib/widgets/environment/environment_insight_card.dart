import 'package:flutter/material.dart';
import 'package:bio_g/models/environment_models.dart';
import 'package:bio_g/widgets/environment/environment_asset_icon.dart';

class EnvironmentInsightCard extends StatelessWidget {
  final String text;
  final EnvInsightLevel level;

  const EnvironmentInsightCard({
    super.key,
    required this.text,
    required this.level,
  });

  Color get _bg {
    switch (level) {
      case EnvInsightLevel.ok:
        return const Color(0xFFE7F3EB);
      case EnvInsightLevel.warn:
        return const Color(0xFFFFF1D6);
      case EnvInsightLevel.critical:
        return const Color(0xFFFFE1E1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconPath = EnvironmentIconMapper.iconForInsightLevel(level);

    return Container(
      decoration: BoxDecoration(
        color: _bg.withValues(alpha:0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha:0.65)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.08),
            blurRadius: 18,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(
          children: [
            Transform.scale(
              scale: 2.6,
              child: EnvironmentAssetIcon(
                assetPath: iconPath,
                width: 16,
                height: 16,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13.8,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0E1A16),
                  height: 1.15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
