import 'package:flutter/material.dart';
import 'package:jisu_calendar/models/schedule.dart';
import 'dart:collection';

class ScheduleProvider with ChangeNotifier {
  final Map<DateTime, List<Schedule>> _schedules = {};

  UnmodifiableListView<Schedule> getSchedulesForDay(DateTime day) {
    final dayUtc = DateTime.utc(day.year, day.month, day.day);
    return UnmodifiableListView(_schedules[dayUtc] ?? []);
  }

  void addSchedule(Schedule schedule) {
    final dayUtc = DateTime.utc(schedule.time.year, schedule.time.month, schedule.time.day);
    if (_schedules[dayUtc] == null) {
      _schedules[dayUtc] = [];
    }
    _schedules[dayUtc]!.add(schedule);
    _schedules[dayUtc]!.sort((a, b) => a.time.compareTo(b.time));
    notifyListeners();
  }

  void updateSchedule(Schedule schedule) {
    // First, remove the old schedule if its date has changed
    deleteSchedule(schedule.id);
    // Then, add the updated schedule
    addSchedule(schedule);
    // Listeners are already notified in delete and add
  }

  void deleteSchedule(String scheduleId) {
    DateTime? keyToRemoveFrom;
    _schedules.forEach((key, scheduleList) {
      final initialLength = scheduleList.length;
      scheduleList.removeWhere((s) => s.id == scheduleId);
      if (scheduleList.length < initialLength) {
        keyToRemoveFrom = key;
      }
    });

    if (keyToRemoveFrom != null && _schedules[keyToRemoveFrom]!.isEmpty) {
      _schedules.remove(keyToRemoveFrom);
    }
    
    notifyListeners();
  }
}
