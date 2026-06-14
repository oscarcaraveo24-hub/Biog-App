import 'package:flutter/material.dart';

/// Selector de fecha tipo rueda (Día / Mes / Año) con estilo BIO-G.
///
/// Reemplazo visual directo de [CalendarDatePicker]: expone exactamente la
/// misma API ([initialDate], [firstDate], [lastDate] y [onDateChanged]) por lo
/// que NO cambia el flujo funcional. Internamente compone un [DateTime] a
/// partir de las tres ruedas y lo recorta al rango `[firstDate, lastDate]`
/// antes de notificarlo, igual que hacía el calendario.
///
/// Diseño:
/// - tres columnas: día, mes (en español) y año
/// - fila central resaltada con una banda verde claro
/// - valor seleccionado en verde
/// - resumen inferior opcional "Fecha seleccionada" con formato natural
///   (ej. "12 de junio de 2026")
class BioGWheelDatePicker extends StatefulWidget {
  const BioGWheelDatePicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDateChanged,
    this.showSelectedSummary = true,
  });

  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDateChanged;

  /// Muestra la tarjeta inferior "Fecha seleccionada".
  final bool showSelectedSummary;

  static const List<String> monthsLong = <String>[
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  /// Formato natural en español, ej. "12 de junio de 2026".
  static String formatNatural(DateTime date) {
    return '${date.day} de ${monthsLong[date.month - 1]} de ${date.year}';
  }

  @override
  State<BioGWheelDatePicker> createState() => _BioGWheelDatePickerState();
}

class _BioGWheelDatePickerState extends State<BioGWheelDatePicker> {
  static const Color _selectedColor = Color(0xFF2E7D32);
  static const Color _nearColor = Color(0xFF55646C);
  static const Color _farColor = Color(0xFFB4BBC0);
  static const Color _bandColor = Color(0xFFE7F1DC);

  static const double _itemExtent = 46;
  static const int _visibleRows = 5;

  late int _day;
  late int _month;
  late int _year;

  late int _firstYear;
  late int _lastYear;

  late FixedExtentScrollController _dayController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _yearController;

  @override
  void initState() {
    super.initState();
    _firstYear = widget.firstDate.year;
    _lastYear = widget.lastDate.year;

    final DateTime clamped = _clamp(widget.initialDate);
    _day = clamped.day;
    _month = clamped.month;
    _year = clamped.year;

    _dayController = FixedExtentScrollController(initialItem: _day - 1);
    _monthController = FixedExtentScrollController(initialItem: _month - 1);
    _yearController = FixedExtentScrollController(
      initialItem: _year - _firstYear,
    );
  }

  @override
  void didUpdateWidget(covariant BioGWheelDatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _firstYear = widget.firstDate.year;
    _lastYear = widget.lastDate.year;

    // Si el padre cambia la fecha inicial (por ejemplo al reabrir el wizard),
    // reflejamos esa selección sin emitir un nuevo onDateChanged.
    if (!_isSameDay(oldWidget.initialDate, widget.initialDate)) {
      final DateTime clamped = _clamp(widget.initialDate);
      if (!_isSameDay(_composeRaw(), clamped)) {
        _day = clamped.day;
        _month = clamped.month;
        _year = clamped.year;
        _syncControllers();
      }
    }
  }

  @override
  void dispose() {
    _dayController.dispose();
    _monthController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  DateTime _composeRaw() {
    final int maxDay = _daysInMonth(_year, _month);
    final int day = _day.clamp(1, maxDay);
    return DateTime(_year, _month, day);
  }

  DateTime _clamp(DateTime date) {
    if (date.isBefore(widget.firstDate)) return widget.firstDate;
    if (date.isAfter(widget.lastDate)) return widget.lastDate;
    return date;
  }

  static int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  void _syncControllers() {
    final int dayIndex = _day - 1;
    final int monthIndex = _month - 1;
    final int yearIndex = _year - _firstYear;
    if (_dayController.hasClients && _dayController.selectedItem != dayIndex) {
      _dayController.jumpToItem(dayIndex);
    }
    if (_monthController.hasClients &&
        _monthController.selectedItem != monthIndex) {
      _monthController.jumpToItem(monthIndex);
    }
    if (_yearController.hasClients &&
        _yearController.selectedItem != yearIndex) {
      _yearController.jumpToItem(yearIndex);
    }
  }

  void _handleChanged() {
    // El día puede quedar fuera de rango al cambiar de mes/año (p. ej. 31 ->
    // febrero). Lo recortamos y reposicionamos la rueda de días.
    final int maxDay = _daysInMonth(_year, _month);
    if (_day > maxDay) {
      _day = maxDay;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _dayController.hasClients) {
          _dayController.animateToItem(
            _day - 1,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }

    final DateTime composed = _clamp(_composeRaw());
    setState(() {});
    widget.onDateChanged(composed);
  }

  @override
  Widget build(BuildContext context) {
    final DateTime current = _clamp(_composeRaw());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          height: _itemExtent * _visibleRows,
          child: Stack(
            children: <Widget>[
              // Banda central resaltada.
              Center(
                child: Container(
                  height: _itemExtent,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: _bandColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  Expanded(
                    flex: 3,
                    child: _buildWheel(
                      controller: _dayController,
                      childCount: 31,
                      selectedIndex: _day - 1,
                      labelBuilder: (int index) => '${index + 1}',
                      onChanged: (int index) {
                        _day = index + 1;
                        _handleChanged();
                      },
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: _buildWheel(
                      controller: _monthController,
                      childCount: 12,
                      selectedIndex: _month - 1,
                      labelBuilder: (int index) =>
                          BioGWheelDatePicker.monthsLong[index],
                      onChanged: (int index) {
                        _month = index + 1;
                        _handleChanged();
                      },
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: _buildWheel(
                      controller: _yearController,
                      childCount: _lastYear - _firstYear + 1,
                      selectedIndex: _year - _firstYear,
                      labelBuilder: (int index) => '${_firstYear + index}',
                      onChanged: (int index) {
                        _year = _firstYear + index;
                        _handleChanged();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (widget.showSelectedSummary) ...<Widget>[
          const SizedBox(height: 14),
          _SelectedDateSummary(date: current),
        ],
      ],
    );
  }

  Widget _buildWheel({
    required FixedExtentScrollController controller,
    required int childCount,
    required int selectedIndex,
    required String Function(int index) labelBuilder,
    required ValueChanged<int> onChanged,
  }) {
    return ListWheelScrollView.useDelegate(
      controller: controller,
      itemExtent: _itemExtent,
      physics: const FixedExtentScrollPhysics(),
      perspective: 0.004,
      diameterRatio: 1.7,
      overAndUnderCenterOpacity: 0.85,
      onSelectedItemChanged: onChanged,
      childDelegate: ListWheelChildBuilderDelegate(
        childCount: childCount,
        builder: (BuildContext context, int index) {
          final int distance = (index - selectedIndex).abs();
          final bool isSelected = index == selectedIndex;
          final Color color = isSelected
              ? _selectedColor
              : (distance == 1 ? _nearColor : _farColor);
          return Center(
            child: Text(
              labelBuilder(index),
              style: TextStyle(
                fontSize: isSelected ? 22 : 18,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SelectedDateSummary extends StatelessWidget {
  const _SelectedDateSummary({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3E8EA)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFE7F1DC),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_rounded,
              size: 20,
              color: Color(0xFF6E9A57),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Fecha seleccionada',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  BioGWheelDatePicker.formatNatural(date),
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_rounded,
            size: 24,
            color: Color(0xFF89B368),
          ),
        ],
      ),
    );
  }
}
