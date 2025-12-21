import 'package:flutter/material.dart';
import 'package:jisu_calendar/models/schedule.dart';
import 'package:jisu_calendar/services/schedule_service.dart';
import 'dart:collection';

class ScheduleProvider with ChangeNotifier {
  final ScheduleService _scheduleService = ScheduleService();
  
  final Map<DateTime, List<Schedule>> _schedules = {};
  
  bool _isLoading = false;
  String? _error;
  
  // 已加载的月份缓存
  final Set<String> _loadedMonths = {};

  bool get isLoading => _isLoading;
  String? get error => _error;

  UnmodifiableListView<Schedule> getSchedulesForDay(DateTime day) {
    final dayUtc = DateTime.utc(day.year, day.month, day.day);
    return UnmodifiableListView(_schedules[dayUtc] ?? []);
  }

  /// 检查指定日期是否有日程
  bool hasSchedulesForDay(DateTime day) {
    final dayUtc = DateTime.utc(day.year, day.month, day.day);
    return _schedules[dayUtc]?.isNotEmpty ?? false;
  }

  /// 加载指定月份的日程
  Future<void> loadSchedulesForMonth(int year, int month, {bool forceRefresh = false}) async {
    final monthKey = '$year-$month';
    
    // 如果已加载且不强制刷新，跳过
    if (_loadedMonths.contains(monthKey) && !forceRefresh) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _scheduleService.getSchedulesByMonth(
        year: year,
        month: month,
      );

      if (response.success && response.data != null) {
        // 清除该月份的旧数据
        _clearMonthSchedules(year, month);
        
        // 添加新数据
        for (final schedule in response.data!) {
          _addScheduleToCache(schedule);
        }
        
        _loadedMonths.add(monthKey);
        _error = null;
      } else {
        _error = response.message;
      }
    } catch (e) {
      _error = '加载日程失败: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 添加日程（调用API）
  Future<bool> addSchedule(Schedule schedule) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _scheduleService.createSchedule(schedule);

      if (response.success && response.data != null) {
        _addScheduleToCache(response.data!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = '创建日程失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 更新日程（调用API）
  Future<bool> updateSchedule(Schedule schedule) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _scheduleService.updateSchedule(schedule);

      if (response.success && response.data != null) {
        // 先删除旧的
        _removeScheduleFromCache(schedule.id);
        // 再添加新的
        _addScheduleToCache(response.data!);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = '更新日程失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 删除日程（调用API）
  Future<bool> deleteSchedule(String scheduleId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _scheduleService.deleteSchedule(scheduleId);

      if (response.success) {
        _removeScheduleFromCache(scheduleId);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = '删除日程失败: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// 刷新当前月份的日程
  Future<void> refreshCurrentMonth(DateTime date) async {
    await loadSchedulesForMonth(date.year, date.month, forceRefresh: true);
  }

  /// 清除错误
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 清除所有缓存数据（退出登录时调用）
  void clearAll() {
    _schedules.clear();
    _loadedMonths.clear();
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  // ========== 私有方法 ==========

  void _addScheduleToCache(Schedule schedule) {
    final dayUtc = DateTime.utc(
      schedule.scheduleDate.year,
      schedule.scheduleDate.month,
      schedule.scheduleDate.day,
    );
    
    if (_schedules[dayUtc] == null) {
      _schedules[dayUtc] = [];
    }
    _schedules[dayUtc]!.add(schedule);
    
    // 按开始时间排序
    _schedules[dayUtc]!.sort((a, b) {
      final aTime = a.startTime;
      final bTime = b.startTime;
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return (aTime.hour * 60 + aTime.minute).compareTo(bTime.hour * 60 + bTime.minute);
    });
  }

  void _removeScheduleFromCache(String scheduleId) {
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
  }

  void _clearMonthSchedules(int year, int month) {
    final keysToRemove = <DateTime>[];
    _schedules.forEach((key, _) {
      if (key.year == year && key.month == month) {
        keysToRemove.add(key);
      }
    });
    for (final key in keysToRemove) {
      _schedules.remove(key);
    }
  }
}
