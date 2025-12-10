import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomTimePicker extends StatefulWidget {
  final DateTime initialDate;

  const CustomTimePicker({super.key, required this.initialDate});

  @override
  State<CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<CustomTimePicker> {
  late DateTime _selectedDate;
  late FixedExtentScrollController _dateController;
  late FixedExtentScrollController _periodController;
  late FixedExtentScrollController _hourController;
  late FixedExtentScrollController _minuteController;

  final List<DateTime> _dates =
      List.generate(1000, (index) => DateTime.now().add(Duration(days: index - 500)));
  final List<String> _periods = ['上午', '下午'];
  final List<int> _hours = List.generate(12, (index) => index + 1); // [1, 2, ..., 12]
  final List<int> _minutes = List.generate(60, (index) => index);

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;

    final initialDateIndex = _dates.indexWhere((date) =>
        date.year == _selectedDate.year &&
        date.month == _selectedDate.month &&
        date.day == _selectedDate.day);
    _dateController = FixedExtentScrollController(
        initialItem: initialDateIndex != -1 ? initialDateIndex : 500);

    _periodController =
        FixedExtentScrollController(initialItem: _selectedDate.hour < 12 ? 0 : 1);

    int initialHour24 = _selectedDate.hour; // 0-23
    int initialHour12;
    if (initialHour24 == 0) {
      initialHour12 = 12; // 12 AM
    } else if (initialHour24 > 12) {
      initialHour12 = initialHour24 - 12; // PM hours
    } else {
      initialHour12 = initialHour24; // AM hours
    }
    // _hours is 1-based, indexOf will work perfectly.
    _hourController = FixedExtentScrollController(initialItem: _hours.indexOf(initialHour12));

    _minuteController =
        FixedExtentScrollController(initialItem: _selectedDate.minute);
  }

  String get _formattedDate {
    final format = DateFormat('yyyy年M月d日 EEE', 'zh_CN');
    return format.format(_selectedDate);
  }

  void _onSelectedItemChanged() {
    final date = _dates[_dateController.selectedItem];
    final periodIndex = _periodController.selectedItem;
    final hour = _hours[_hourController.selectedItem];
    final minute = _minutes[_minuteController.selectedItem];

    int newHour = hour;
    if (periodIndex == 1) { // Afternoon
      if (hour != 12) { // 1 PM to 11 PM -> 13 to 23
        newHour += 12;
      }
    } else { // Morning
      if (hour == 12) { // 12 AM is 00:00
        newHour = 0;
      }
    }

    setState(() {
      _selectedDate =
          DateTime(date.year, date.month, date.day, newHour, minute);
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
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Container(
                //   height: 40,
                //   margin: const EdgeInsets.symmetric(horizontal: 16),
                //   decoration: BoxDecoration(
                //     color: Colors.grey.withOpacity(0.15),
                //     borderRadius: BorderRadius.circular(8),
                //   ),
                // ),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: CupertinoPicker(
                        scrollController: _dateController,
                        itemExtent: 40,
                        onSelectedItemChanged: (_) => _onSelectedItemChanged(),
                        backgroundColor: Colors.transparent,
                        selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(
                          background: Colors.transparent,
                        ),
                        children: _dates
                            .map((date) => Center(
                                child: Text(DateFormat('M月d日').format(date))))
                            .toList(),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: CupertinoPicker(
                        scrollController: _periodController,
                        itemExtent: 40,
                        onSelectedItemChanged: (_) => _onSelectedItemChanged(),
                        backgroundColor: Colors.transparent,
                        selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(
                          background: Colors.transparent,
                        ),
                        children:
                            _periods.map((p) => Center(child: Text(p))).toList(),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: CupertinoPicker(
                        scrollController: _hourController,
                        itemExtent: 40,
                        onSelectedItemChanged: (_) => _onSelectedItemChanged(),
                        backgroundColor: Colors.transparent,
                        selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(
                          background: Colors.transparent,
                        ),
                        children: _hours
                            .map((h) => Center(
                                child: Text(h.toString().padLeft(2, '0'))))
                            .toList(),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: CupertinoPicker(
                        scrollController: _minuteController,
                        itemExtent: 40,
                        onSelectedItemChanged: (_) => _onSelectedItemChanged(),
                        backgroundColor: Colors.transparent,
                        selectionOverlay: const CupertinoPickerDefaultSelectionOverlay(
                          background: Colors.transparent,
                        ),
                        children: _minutes
                            .map((m) => Center(
                                child: Text(m.toString().padLeft(2, '0'))))
                            .toList(),
                      ),
                    ),
                  ],
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
                  child: const Text('确定',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
