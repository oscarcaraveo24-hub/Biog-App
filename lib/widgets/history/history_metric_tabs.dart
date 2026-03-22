import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HistoryMetricTabs extends StatefulWidget {
  const HistoryMetricTabs({
    super.key,
    this.selectedIndex,
    this.onChanged,
  });

  /// ✅ si viene, el padre controla la selección
  final int? selectedIndex;

  /// ✅ callback al padre (cuando tocas una tab)
  final ValueChanged<int>? onChanged;

  @override
  State<HistoryMetricTabs> createState() => _HistoryMetricTabsState();
}

class _HistoryMetricTabsState extends State<HistoryMetricTabs> {
  int _selectedIndex = 0; // ✅ default Humedad
  static const _labels = ['Humedad', 'pH', 'RT', 'Temp', 'NPK'];

  @override
  void initState() {
    super.initState();
    if (widget.selectedIndex != null) _selectedIndex = widget.selectedIndex!;
  }

  @override
  void didUpdateWidget(covariant HistoryMetricTabs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != null && widget.selectedIndex != _selectedIndex) {
      _selectedIndex = widget.selectedIndex!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selectedIndex ?? _selectedIndex;

    return _PillBar(
      labels: _labels,
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
        setState(() => _selectedIndex = i);
      },
    );
  }
}

class _PillBar extends StatefulWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelect;

  const _PillBar({
    required this.labels,
    required this.selectedIndex,
    required this.onSelect,
  });

  @override
  State<_PillBar> createState() => _PillBarState();
}

class _PillBarState extends State<_PillBar> {
  final _rowKey = GlobalKey();
  late final List<GlobalKey> _tabKeys =
      List.generate(widget.labels.length, (_) => GlobalKey());

  double _pillLeft = 0;
  double _pillWidth = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _recalcPill());
  }

  @override
  void didUpdateWidget(covariant _PillBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex ||
        oldWidget.labels.length != widget.labels.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _recalcPill());
    }
  }

  void _recalcPill() {
    final rowCtx = _rowKey.currentContext;
    final tabCtx = _tabKeys[widget.selectedIndex].currentContext;
    if (rowCtx == null || tabCtx == null) return;

    final rowBox = rowCtx.findRenderObject() as RenderBox;
    final tabBox = tabCtx.findRenderObject() as RenderBox;

    final tabPos = tabBox.localToGlobal(Offset.zero, ancestor: rowBox);

    final double left = tabPos.dx;
    final double width = tabBox.size.width;

    // ✅ sobresalir un poco
    const double extra = 6.0;
    const double inset = 3.0;

    final double rowWidth = rowBox.size.width;
    final double expandedWidth = width + (extra * 2);
    final double expandedLeft = left - extra;

    final double clampedLeft =
        expandedLeft.clamp(inset, rowWidth - expandedWidth - inset).toDouble();

    if (!mounted) return;
    setState(() {
      _pillLeft = clampedLeft;
      _pillWidth = expandedWidth;
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
                  border: Border.all(color: Colors.white.withValues(alpha:0.55)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // ✅ highlight deslizable
                      if (_pillWidth > 0)
                        AnimatedPositioned(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          left: _pillLeft,
                          top: 0,
                          bottom: 0,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            width: _pillWidth,
                            decoration: BoxDecoration(
                              borderRadius: tabRadius,
                              gradient: const LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    Color(0xFF40BB5F), // top sólido (mismo RGB)
    Color(0xFF3FAF6E), // mid
    Color.fromARGB(162, 43, 126, 101), // base
  ],
),

                              border: Border.all(
                                color: Colors.white.withValues(alpha:0.55),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha:0.12),
                                  blurRadius: 14,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: tabRadius,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius: tabRadius,
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.center,
                                            colors: [
                                              Colors.white.withValues(alpha:0.20),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned.fill(
                                    child: IgnorePointer(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius: tabRadius,
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.center,
                                            colors: [
                                              Colors.black.withValues(alpha:0.06),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // ✅ tabs
                      Row(
                        key: _rowKey,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 6),

                          ...List.generate(widget.labels.length, (i) {
                            final selected = i == widget.selectedIndex;

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              child: _TapTab(
                                key: _tabKeys[i],
                                onTap: () => widget.onSelect(i),
                                child: _MetricTabText(
                                  label: widget.labels[i],
                                  selected: selected,
                                ),
                              ),
                            );
                          }),

                          const SizedBox(width: 10),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TapTab extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _TapTab({
    super.key,
    required this.onTap,
    required this.child,
  });

  @override
  State<_TapTab> createState() => _TapTabState();
}

class _TapTabState extends State<_TapTab> {
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
          scale: _pressed ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOutCubic,
          child: AnimatedOpacity(
            opacity: _pressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 110),
            curve: Curves.easeOutCubic,
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _MetricTabText extends StatelessWidget {
  final String label;
  final bool selected;

  const _MetricTabText({
    required this.label,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: selected ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}
