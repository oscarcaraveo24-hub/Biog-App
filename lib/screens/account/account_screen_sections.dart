import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:bio_g/models/biog_telemetry.dart';
import 'package:bio_g/screens/account/account_screen_presenter.dart';
import 'package:bio_g/widgets/shared/bio_g_button.dart';

class AccountReveal extends StatelessWidget {
  final AnimationController controller;
  final double intervalStart;
  final double intervalEnd;
  final double yOffset;
  final double beginScale;
  final double shadowOpacityBegin;
  final double shadowOpacityEnd;
  final Widget child;

  const AccountReveal({
    super.key,
    required this.controller,
    required this.intervalStart,
    required this.intervalEnd,
    required this.child,
    this.yOffset = 12,
    this.beginScale = 1.0,
    this.shadowOpacityBegin = 0.0,
    this.shadowOpacityEnd = 0.08,
  });

  static const Curve _motionCurve = Cubic(0.22, 1.0, 0.36, 1.0);
  static const Curve _opacityCurve = Cubic(0.18, 0.84, 0.24, 1.0);

  @override
  Widget build(BuildContext context) {
    final motion = CurvedAnimation(
      parent: controller,
      curve: Interval(intervalStart, intervalEnd, curve: _motionCurve),
    );

    final opacityMotion = CurvedAnimation(
      parent: controller,
      curve: Interval(
        intervalStart,
        intervalStart + ((intervalEnd - intervalStart) * 0.84),
        curve: _opacityCurve,
      ),
    );

    final opacity = Tween<double>(begin: 0.0, end: 1.0).animate(opacityMotion);
    final translateY = Tween<double>(begin: yOffset, end: 0.0).animate(motion);
    final shadowOpacity = Tween<double>(
      begin: shadowOpacityBegin,
      end: shadowOpacityEnd,
    ).animate(motion);
    final shadowBlur = Tween<double>(begin: 0.0, end: 26.0).animate(motion);
    final shadowDy = Tween<double>(begin: 0.0, end: 16.0).animate(motion);

    return FadeTransition(
      opacity: opacity,
      child: AnimatedBuilder(
        animation: controller,
        child: child,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, translateY.value),
            child: Transform.scale(
              scale: beginScale,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: shadowOpacity.value.clamp(0.0, 0.20),
                      ),
                      blurRadius: shadowBlur.value,
                      offset: Offset(0, shadowDy.value),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }
}

class AccountSoftBackground extends StatelessWidget {
  const AccountSoftBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFFF6FAF8),
            Color(0xFFEFF6F2),
            Color(0xFFF6FAF8),
          ],
        ),
      ),
      child: const Stack(
        children: <Widget>[
          Positioned(
            top: -120,
            left: -80,
            child: _GlowBlob(size: 260, opacity: 0.18),
          ),
          Positioned(
            top: 160,
            right: -110,
            child: _GlowBlob(size: 300, opacity: 0.14),
          ),
          Positioned(
            bottom: -160,
            left: -120,
            child: _GlowBlob(size: 340, opacity: 0.16),
          ),
        ],
      ),
    );
  }
}

class AccountTopHeaderSection extends StatelessWidget {
  const AccountTopHeaderSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const <Widget>[
          Text(
            'Cuenta',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: Color(0xFF0E1A16),
            ),
          ),
          SizedBox(height: 6),
          Row(
            children: <Widget>[
              Text(
                'Administra tu perfil, tus Bio-G y el cultivo activo',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 6),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: Colors.black54,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AccountUserCardSection extends StatelessWidget {
  final String name;
  final String email;
  final String? avatarPath;
  final bool syncActive;
  final VoidCallback onEditTap;

  const AccountUserCardSection({
    super.key,
    required this.name,
    required this.email,
    required this.avatarPath,
    required this.syncActive,
    required this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
      child: _GlassCard(
        radius: 22,
        child: Row(
          children: <Widget>[
            _AvatarCircle(size: 56, filePath: avatarPath),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0E1A16),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _SyncPill(active: syncActive),
                ],
              ),
            ),
            const SizedBox(width: 10),
            _PillButton(label: 'Editar', onTap: onEditTap),
          ],
        ),
      ),
    );
  }
}

class AccountSectionHeader extends StatelessWidget {
  final String title;

  const AccountSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: Row(
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0E1A16),
            ),
          ),
          const Spacer(),
          const Icon(Icons.chevron_right_rounded, color: Colors.black38),
        ],
      ),
    );
  }
}

class AccountMyBioGCardSection extends StatelessWidget {
  final String deviceIconAsset;
  final String errorIconAsset;
  final List<AccountMyBioGItem> items;
  final VoidCallback onAddBioGTap;

  const AccountMyBioGCardSection({
    super.key,
    required this.deviceIconAsset,
    required this.errorIconAsset,
    required this.items,
    required this.onAddBioGTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      child: _GlassCard(
        radius: 22,
        child: Column(
          children: <Widget>[
            if (items.isEmpty) ...<Widget>[
              _DeviceRow(
                deviceIconAsset: deviceIconAsset,
                deviceIconTint: Colors.black38,
                title: 'Aún no tienes Bio-G agregados',
                subtitle: 'Agrega uno con QR o Bluetooth',
                trailingText: '',
                trailingColor: Colors.black54,
                errorIconAsset: errorIconAsset,
                onTap: () {},
              ),
            ] else ...<Widget>[
              for (int i = 0; i < items.length; i++) ...<Widget>[
                _LiveDeviceRow(
                  deviceIconAsset: deviceIconAsset,
                  errorIconAsset: errorIconAsset,
                  item: items[i],
                ),
                if (i != items.length - 1) const _DividerLine(),
              ],
            ],
            const SizedBox(height: 14),
            BioGButton(label: 'Agregar Bio-G', onTap: onAddBioGTap),
          ],
        ),
      ),
    );
  }
}

class AccountPreferencesCardSection extends StatelessWidget {
  final String configureCropAssetPath;
  final String notificationAssetPath;
  final String temperatureAssetPath;
  final bool notifications;
  final bool useCelsius;
  final VoidCallback onConfigureCropTap;
  final ValueChanged<bool> onNotificationsChanged;
  final ValueChanged<bool> onUseCelsiusChanged;

  const AccountPreferencesCardSection({
    super.key,
    required this.configureCropAssetPath,
    required this.notificationAssetPath,
    required this.temperatureAssetPath,
    required this.notifications,
    required this.useCelsius,
    required this.onConfigureCropTap,
    required this.onNotificationsChanged,
    required this.onUseCelsiusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      child: _GlassCard(
        radius: 22,
        child: Column(
          children: <Widget>[
            _NavRow(
              assetPath: configureCropAssetPath,
              scale: 2.6,
              title: 'Configurar cultivo',
              onTap: onConfigureCropTap,
            ),
            const _DividerLine(),
            _SettingRow(
              assetPath: notificationAssetPath,
              scale: 2.2,
              title: 'Notificaciones',
              trailing: Switch(
                value: notifications,
                onChanged: onNotificationsChanged,
                activeThumbColor: AccountScreenPresenter.kBrandMid,
                activeTrackColor: AccountScreenPresenter.kBrandMid.withValues(
                  alpha: 0.34,
                ),
              ),
            ),
            const _DividerLine(),
            _SettingRow(
              assetPath: temperatureAssetPath,
              scale: 2.2,
              title: 'Unidades: °C / °F',
              trailing: _SegmentedMini(
                left: '°C',
                right: '°F',
                leftSelected: useCelsius,
                onToggle: onUseCelsiusChanged,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AccountSupportCardSection extends StatelessWidget {
  final String helpAssetPath;
  final String manualAssetPath;
  final String contactAssetPath;
  final VoidCallback onHelpTap;
  final VoidCallback onContactTap;
  final VoidCallback onManualTap;

  const AccountSupportCardSection({
    super.key,
    required this.helpAssetPath,
    required this.manualAssetPath,
    required this.contactAssetPath,
    required this.onHelpTap,
    required this.onContactTap,
    required this.onManualTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      child: _GlassCard(
        radius: 22,
        child: Column(
          children: <Widget>[
            _NavRow(
              assetPath: helpAssetPath,
              scale: 2.2,
              title: 'Centro de ayuda',
              onTap: onHelpTap,
            ),
            const _DividerLine(),
            _NavRow(
              assetPath: contactAssetPath,
              scale: 2.0,
              title: 'Contactar soporte',
              onTap: onContactTap,
            ),
            const _DividerLine(),
            _NavRow(
              assetPath: manualAssetPath,
              scale: 2.0,
              title: 'Manual rápido Bio-G',
              onTap: onManualTap,
            ),
          ],
        ),
      ),
    );
  }
}

class AccountMyBioGItem {
  final AccountDeviceCardUiModel uiModel;
  final VoidCallback onTap;

  /// Per-device live telemetry. When provided, the row recomputes its
  /// uiModel on every tick using [liveUiModelBuilder] so battery / signal
  /// state stays in sync with real Supabase data.
  final Stream<BioGTelemetry?>? liveTelemetryStream;

  /// Builds the latest uiModel from a real telemetry reading. Required
  /// when [liveTelemetryStream] is provided.
  final AccountDeviceCardUiModel Function(BioGTelemetry? live)?
  liveUiModelBuilder;

  const AccountMyBioGItem({
    required this.uiModel,
    required this.onTap,
    this.liveTelemetryStream,
    this.liveUiModelBuilder,
  });
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final double opacity;

  const _GlowBlob({required this.size, required this.opacity});

  static const Color _brandMid = Color(0xFF3FAF6E);

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 34, sigmaY: 34),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _brandMid.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;

  const _GlassCard({required this.child, this.radius = 20});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 30,
            offset: const Offset(0, 18),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.62),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.55),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _AvatarCircle extends StatelessWidget {
  final double size;
  final String? filePath;

  const _AvatarCircle({required this.size, required this.filePath});

  @override
  Widget build(BuildContext context) {
    final path = (filePath ?? '').trim();
    final hasFile = path.isNotEmpty && File(path).existsSync();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.65),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.75),
          width: 1,
        ),
      ),
      child: ClipOval(
        child: hasFile
            ? Image.file(File(path), fit: BoxFit.cover)
            : const Icon(Icons.person_rounded, color: Colors.black54),
      ),
    );
  }
}

class _SyncPill extends StatelessWidget {
  final bool active;

  const _SyncPill({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? AccountScreenPresenter.kBrandMid : Colors.black38;
    return Row(
      children: <Widget>[
        Icon(Icons.check_circle_rounded, size: 16, color: color),
        const SizedBox(width: 6),
        Text(
          'Sincronización: ${active ? 'Activa' : 'Inactiva'}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.black.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _PillButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _PillButton({required this.label, required this.onTap});

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: widget.onTap,
          child: AnimatedOpacity(
            opacity: _pressed ? 0.92 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1,
                ),
              ),
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AccountScreenPresenter.kBrandMid,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      child: Container(
        height: 1,
        width: double.infinity,
        color: Colors.black.withValues(alpha: 0.06),
      ),
    );
  }
}

class _AssetIcon extends StatelessWidget {
  final String assetPath;
  final double size;
  final double scale;

  const _AssetIcon({
    required this.assetPath,
    required this.size,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    if (assetPath.trim().isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Transform.scale(
          scale: scale,
          child: Image.asset(assetPath, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

class _TintedAssetIcon extends StatelessWidget {
  final String assetPath;
  final Color tint;
  final double size;
  final double scale;

  const _TintedAssetIcon({
    required this.assetPath,
    required this.tint,
    required this.size,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    if (assetPath.trim().isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Transform.scale(
          scale: scale,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(tint, BlendMode.srcIn),
            child: Image.asset(assetPath, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String assetPath;
  final double scale;
  final String title;
  final Widget trailing;

  const _SettingRow({
    required this.assetPath,
    required this.scale,
    required this.title,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          _AssetIcon(assetPath: assetPath, size: 34, scale: scale),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0E1A16),
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}

class _NavRow extends StatefulWidget {
  final String assetPath;
  final double scale;
  final String title;
  final VoidCallback onTap;

  const _NavRow({
    required this.assetPath,
    required this.scale,
    required this.title,
    required this.onTap,
  });

  @override
  State<_NavRow> createState() => _NavRowState();
}

class _NavRowState extends State<_NavRow> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.992 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: AnimatedOpacity(
            opacity: _pressed ? 0.94 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: <Widget>[
                  _AssetIcon(
                    assetPath: widget.assetPath,
                    size: 34,
                    scale: widget.scale,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0E1A16),
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black26,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LiveDeviceRow extends StatelessWidget {
  final String deviceIconAsset;
  final String errorIconAsset;
  final AccountMyBioGItem item;

  const _LiveDeviceRow({
    required this.deviceIconAsset,
    required this.errorIconAsset,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final stream = item.liveTelemetryStream;
    final builder = item.liveUiModelBuilder;

    if (stream == null || builder == null) {
      return _DeviceRow(
        deviceIconAsset: deviceIconAsset,
        deviceIconTint: item.uiModel.deviceIconTint,
        title: item.uiModel.title,
        subtitle: item.uiModel.subtitle,
        trailingText: item.uiModel.trailingText,
        trailingColor: item.uiModel.trailingColor,
        errorIconAsset: errorIconAsset,
        onTap: item.onTap,
      );
    }

    return StreamBuilder<BioGTelemetry?>(
      stream: stream,
      builder: (context, snapshot) {
        final bool waiting =
            snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;
        final BioGTelemetry? telemetry = snapshot.data;
        final AccountDeviceCardUiModel ui = waiting
            ? _loadingUiModel(item.uiModel)
            : (telemetry == null ? item.uiModel : builder(telemetry));

        return _DeviceRow(
          deviceIconAsset: deviceIconAsset,
          deviceIconTint: ui.deviceIconTint,
          title: ui.title,
          subtitle: ui.subtitle,
          trailingText: ui.trailingText,
          trailingColor: ui.trailingColor,
          errorIconAsset: errorIconAsset,
          onTap: item.onTap,
        );
      },
    );
  }

  AccountDeviceCardUiModel _loadingUiModel(AccountDeviceCardUiModel base) {
    return AccountDeviceCardUiModel(
      title: base.title,
      subtitle: base.subtitle,
      trailingText: base.trailingText.isEmpty ? '' : '...',
      trailingColor: Colors.black38,
      deviceIconTint: base.deviceIconTint,
    );
  }
}

class _DeviceRow extends StatefulWidget {
  final String deviceIconAsset;
  final Color deviceIconTint;
  final String title;
  final String subtitle;
  final String trailingText;
  final Color trailingColor;
  final String? errorIconAsset;
  final VoidCallback onTap;

  const _DeviceRow({
    required this.deviceIconAsset,
    required this.deviceIconTint,
    required this.title,
    required this.subtitle,
    required this.trailingText,
    required this.trailingColor,
    required this.onTap,
    this.errorIconAsset,
  });

  @override
  State<_DeviceRow> createState() => _DeviceRowState();
}

class _DeviceRowState extends State<_DeviceRow> {
  bool _pressed = false;

  bool _isErrorText(String value) {
    final text = value.trim().toLowerCase();
    return text.contains('sin señal') ||
        text.contains('sin senal') ||
        text.contains('error');
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final hasErrorAsset = (widget.errorIconAsset ?? '').trim().isNotEmpty;
    final useErrorAsMain =
        hasErrorAsset &&
        (_isErrorText(widget.subtitle) || _isErrorText(widget.trailingText));

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.993 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: widget.onTap,
          child: AnimatedOpacity(
            opacity: _pressed ? 0.95 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: <Widget>[
                  if (useErrorAsMain)
                    _AssetIcon(
                      assetPath: widget.errorIconAsset!,
                      size: 34,
                      scale: 2.2,
                    )
                  else
                    TweenAnimationBuilder<Color?>(
                      tween: ColorTween(end: widget.deviceIconTint),
                      duration: const Duration(milliseconds: 360),
                      curve: Curves.easeOut,
                      builder: (context, color, _) {
                        return _TintedAssetIcon(
                          assetPath: widget.deviceIconAsset,
                          tint: color ?? widget.deviceIconTint,
                          size: 34,
                          scale: 0.7,
                        );
                      },
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          widget.title,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0E1A16),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (widget.trailingText.isNotEmpty)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: TweenAnimationBuilder<Color?>(
                        key: ValueKey<String>(widget.trailingText),
                        tween: ColorTween(end: widget.trailingColor),
                        duration: const Duration(milliseconds: 360),
                        curve: Curves.easeOut,
                        builder: (context, color, _) {
                          return Text(
                            widget.trailingText,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: color ?? widget.trailingColor,
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.black26,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SegmentedMini extends StatelessWidget {
  final String left;
  final String right;
  final bool leftSelected;
  final ValueChanged<bool> onToggle;

  const _SegmentedMini({
    required this.left,
    required this.right,
    required this.leftSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _SegChip(
            label: left,
            selected: leftSelected,
            onTap: () => onToggle(true),
          ),
          _SegChip(
            label: right,
            selected: !leftSelected,
            onTap: () => onToggle(false),
          ),
        ],
      ),
    );
  }
}

class _SegChip extends StatefulWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SegChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  State<_SegChip> createState() => _SegChipState();
}

class _SegChipState extends State<_SegChip> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: InkWell(
          borderRadius: BorderRadius.circular(11),
          onTap: widget.onTap,
          child: Container(
            width: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: widget.selected
                  ? AccountScreenPresenter.kBrandMid.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: widget.selected
                    ? AccountScreenPresenter.kBrandMid
                    : Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
