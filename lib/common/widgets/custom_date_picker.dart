import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDatePicker extends StatefulWidget {
  final DateTime initialDate;

  const CustomDatePicker({super.key, required this.initialDate});

  @override
  State<CustomDatePicker> createState() => _CustomDatePickerState();
}

class _CustomDatePickerState extends State<CustomDatePicker> {
  late DateTime _selectedDate;
  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;

  final List<int> _years = List.generate(201, (index) => 1950 + index);
  final List<int> _months = List.generate(12, (index) => index + 1);
  late List<int> _days;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _days = List.generate(_getDaysInMonth(_selectedDate.year, _selectedDate.month), (index) => index + 1);

    _yearController = FixedExtentScrollController(initialItem: _years.indexOf(_selectedDate.year));
    _monthController = FixedExtentScrollController(initialItem: _selectedDate.month - 1);
    _dayController = FixedExtentScrollController(initialItem: _selectedDate.day - 1);
  }

  int _getDaysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  String get _formattedDate {
    final format = DateFormat('yyyy年M月d日 EEE', 'zh_CN');
    return format.format(_selectedDate);
  }

  void _onSelectedItemChanged() {
    final year = _years[_yearController.selectedItem];
    final month = _months[_monthController.selectedItem];
    final day = _dayController.selectedItem + 1;

    final newDaysInMonth = _getDaysInMonth(year, month);
    int newDay = day;
    if (newDay > newDaysInMonth) {
      newDay = newDaysInMonth;
    }

    setState(() {
      _selectedDate = DateTime(year, month, newDay);
      if (_days.length != newDaysInMonth) {
        _days = List.generate(newDaysInMonth, (index) => index + 1);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _dayController.hasClients && _dayController.selectedItem != newDay - 1) {
            _dayController.jumpToItem(newDay - 1);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(20)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _formattedDate,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _yearController,
                    itemExtent: 40,
                    looping: false,
                    onSelectedItemChanged: (index) => _onSelectedItemChanged(),
                    backgroundColor: Colors.transparent,
                    selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(background: Colors.transparent),
                    children: _years.map((y) => Center(child: Text(y.toString()))).toList(),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _monthController,
                    itemExtent: 40,
                    looping: false,
                    onSelectedItemChanged: (index) => _onSelectedItemChanged(),
                    backgroundColor: Colors.transparent,
                    selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(background: Colors.transparent),
                    children: _months.map((m) => Center(child: Text(m.toString()))).toList(),
                  ),
                ),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: _dayController,
                    itemExtent: 40,
                    looping: false,
                    onSelectedItemChanged: (index) => _onSelectedItemChanged(),
                    backgroundColor: Colors.transparent,
                    selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(background: Colors.transparent),
                    children: _days.map((d) => Center(child: Text(d.toString()))).toList(),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('取消', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 30, child: VerticalDivider()),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(_selectedDate),
                  child: const Text('确定', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
