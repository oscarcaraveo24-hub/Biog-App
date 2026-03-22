import 'package:flutter/material.dart';

/// Smoothly interpolates between numeric values with a count-up/down effect.
///
/// Parses the leading numeric portion of [value] (e.g. "24.5 °C" → 24.5)
/// and animates from the previous value. The non-numeric suffix is preserved.
class AnimatedValueText extends StatefulWidget {
  final String value;
  final TextStyle? style;
  final Duration duration;

  const AnimatedValueText({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 600),
  });

  @override
  State<AnimatedValueText> createState() => _AnimatedValueTextState();
}

class _AnimatedValueTextState extends State<AnimatedValueText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;

  double _oldNum = 0;
  double _newNum = 0;
  String _suffix = '';
  int _decimals = 0;
  bool _hasNumeric = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _parse(widget.value);
    _oldNum = _newNum;
    _animation = AlwaysStoppedAnimation(_newNum);
  }

  @override
  void didUpdateWidget(AnimatedValueText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _oldNum = _newNum;
      _parse(widget.value);

      if (_hasNumeric && _oldNum != _newNum) {
        _animation = Tween<double>(begin: _oldNum, end: _newNum).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
        );
        _controller
          ..reset()
          ..forward();
      }
    }
  }

  void _parse(String raw) {
    final match = RegExp(r'^([+-]?\d+\.?\d*)(.*)$').firstMatch(raw.trim());
    if (match != null) {
      _newNum = double.tryParse(match.group(1)!) ?? 0;
      _suffix = match.group(2) ?? '';
      final dot = match.group(1)!.indexOf('.');
      _decimals = dot == -1 ? 0 : match.group(1)!.length - dot - 1;
      _hasNumeric = true;
    } else {
      _suffix = raw;
      _hasNumeric = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasNumeric) {
      return Text(widget.value, style: widget.style);
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final display = _animation.value.toStringAsFixed(_decimals);
        return Text('$display$_suffix', style: widget.style);
      },
    );
  }
}
