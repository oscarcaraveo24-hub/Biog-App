import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HistoryRangeSelector extends StatefulWidget {
  const HistoryRangeSelector({
    super.key,
    this.selectedIndex,
    this.onChanged,
  });

  /// 0=24h, 1=7d, 2=30d, 3=Todo
  final int? selectedIndex;
  final ValueChanged<int>? onChanged;

  @override
  State<HistoryRangeSelector> createState() => _HistoryRangeSelectorState();
}

class _HistoryRangeSelectorState extends State<HistoryRangeSelector> {
  int _selected = 1; // ✅ default 7d

  @override
  void initState() {
    super.initState();
    if (widget.selectedIndex != null) _selected = widget.selectedIndex!;
  }

  @override
  void didUpdateWidget(covariant HistoryRangeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != null && widget.selectedIndex != _selected) {
      _selected = widget.selectedIndex!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selectedIndex ?? _selected;

    return _RangePillBar(
      selectedIndex: selected,
      onSelect: (i) {
        if (selected == i) return;
        HapticFeedback.selectionClick();

        // ✅ controlado por padre
        if (widget.onChanged != null) {
          widget.onChanged!(i);
          return;
        }

        // ✅ legacy local
        setState(() => _selected = i);
      },
    );
  }
}

class _RangePillBar extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _RangePillBar({
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  State<_RangePillBar> createState() => _RangePillBarState();
}

class _RangePillBarState extends State<_RangePillBar> {
  final _rowKey = GlobalKey();

  // keys SOLO para los 4 pills (no divider)
  final List<GlobalKey> _pillKeys = List.generate(4, (_) => GlobalKey());

  double _pillLeft = 0;
  double _pillWidth = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recalcPill());
  }

  @override
  void didUpdateWidget(covariant _RangePillBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _recalcPill());
    }
  }

  void _recalcPill() {
    final rowCtx = _rowKey.currentContext;
    final tabCtx = _pillKeys[widget.selectedIndex].currentContext;
    if (rowCtx == null || tabCtx == null) return;

    final rowBox = rowCtx.findRenderObject() as RenderBox;
    final tabBox = tabCtx.findRenderObject() as RenderBox;

    final tabPos = tabBox.localToGlobal(Offset.zero, ancestor: rowBox);
    final left = tabPos.dx;
    final width = tabBox.size.width;

    if (!mounted) return;
    setState(() {
      _pillLeft = left;
      _pillWidth = width;
    });
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(26);
    final tabRadius = BorderRadius.circular(22);

    return Align(
      alignment: Alignment.centerLeft,
      child: IntrinsicWidth(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.08),
                blurRadius: 18,
                offset: const Offset(0, 10),
                spreadRadius: 0,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.95),
                  borderRadius: radius,
                  border: Border.all(color: Colors.white.withValues(alpha:0.80)),
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    // ✅ PILL DESLIZABLE (solo uno)
                    if (_pillWidth > 0)
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 260),
                        curve: Curves.easeOutCubic,
                        left: _pillLeft,
                        top: 0,
                        bottom: 0,
                        child: Container(
                          width: _pillWidth,
                          decoration: BoxDecoration(
                            borderRadius: tabRadius,

                            // ✅ BRAND GRADIENT (TOP sólido para que NO se lave)
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF40BB5F), // top sólido (RGB de tu ARGB)
                                Color(0xFF3FAF6E), // mid
                                Color.fromARGB(137, 43, 126, 101), // base
                              ],
                            ),

                            border: Border.all(
                              color: Colors.white.withValues(alpha:0.55),
                              width: 1,
                            ),

                            // ✅ Glow verde + profundidad (premium)
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF40BB5F).withValues(alpha:0.22),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                                spreadRadius: 0,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha:0.08),
                                blurRadius: 14,
                                offset: const Offset(0, 10),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: tabRadius,
                            child: IgnorePointer(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: tabRadius,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.center,
                                    colors: [
                                      // ✅ antes 0.28 (lavaba el color)
                                      Colors.white.withValues(alpha:0.14),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // ✅ FILA (MISMO ESPACIADO QUE TU VISTA)
                    Row(
                      key: _rowKey,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _TapPill(
                            key: _pillKeys[0],
                            onTap: () => widget.onSelect(0),
                            child: _PillText(
                              label: '24h',
                              selected: widget.selectedIndex == 0,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _TapPill(
                            key: _pillKeys[1],
                            onTap: () => widget.onSelect(1),
                            child: _PillText(
                              label: '7d',
                              selected: widget.selectedIndex == 1,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _TapPill(
                            key: _pillKeys[2],
                            onTap: () => widget.onSelect(2),
                            child: _PillText(
                              label: '30d',
                              selected: widget.selectedIndex == 2,
                            ),
                          ),
                        ),

                        const _DividerPill(),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: _TapPill(
                            key: _pillKeys[3],
                            onTap: () => widget.onSelect(3),
                            child: _PillText(
                              label: 'Todo',
                              selected: widget.selectedIndex == 3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TapPill extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _TapPill({
    super.key,
    required this.onTap,
    required this.child,
  });

  @override
  State<_TapPill> createState() => _TapPillState();
}

class _TapPillState extends State<_TapPill> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(22);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: r,
        splashColor: Colors.black.withValues(alpha:0.035),
        highlightColor: Colors.black.withValues(alpha:0.02),
        onHighlightChanged: (v) {
          if (_pressed == v) return;
          setState(() => _pressed = v);
        },
        child: AnimatedScale(
          scale: _pressed ? 0.992 : 1.0,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOutCubic,
          child: widget.child,
        ),
      ),
    );
  }
}

class _PillText extends StatelessWidget {
  final String label;
  final bool selected;

  const _PillText({
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: selected ? Colors.white : Colors.black87,
          height: 1.0,
        ),
      ),
    );
  }
}

class _DividerPill extends StatelessWidget {
  const _DividerPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Colors.black.withValues(alpha:0.12),
    );
  }
}
