import 'package:flutter/material.dart';

/// 日程重复类型
enum RepeatType {
  none('none', '不重复'),
  daily('daily', '每天'),
  weekly('weekly', '每周'),
  monthly('monthly', '每月'),
  yearly('yearly', '每年');

  final String value;
  final String displayName;
  const RepeatType(this.value, this.displayName);

  static RepeatType fromString(String? value) {
    if (value == null) return RepeatType.none;
    return RepeatType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RepeatType.none,
    );
  }
}

/// 日程附件
class ScheduleAttachment {
  final String? id;
  final String fileName;
  final String fileUrl;
  final String? fileType;
  final int? fileSize;
  final DateTime? createdAt;

  ScheduleAttachment({
    this.id,
    required this.fileName,
    required this.fileUrl,
    this.fileType,
    this.fileSize,
    this.createdAt,
  });

  factory ScheduleAttachment.fromJson(Map<String, dynamic> json) {
    return ScheduleAttachment(
      id: json['id']?.toString(),
      fileName: json['fileName'] as String? ?? json['file_name'] as String? ?? '',
      fileUrl: json['fileUrl'] as String? ?? json['file_url'] as String? ?? '',
      fileType: json['fileType'] as String? ?? json['file_type'] as String?,
      fileSize: json['fileSize'] as int? ?? json['file_size'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'fileName': fileName,
      'fileUrl': fileUrl,
      if (fileType != null) 'fileType': fileType,
      if (fileSize != null) 'fileSize': fileSize,
    };
  }
}

/// 日程模型
/// 对应后端 schedules 表
class Schedule {
  final String id;
  final String? userId;
  final String? groupId;
  final String title;
  final DateTime scheduleDate;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final String? location;
  final bool isAllDay;
  final Color color;
  final String? notes;
  final int? reminderMinutes;
  final RepeatType repeatType;
  final DateTime? repeatEndDate;
  final List<ScheduleAttachment> attachments;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Schedule({
    required this.id,
    this.userId,
    this.groupId,
    required this.title,
    required this.scheduleDate,
    this.startTime,
    this.endTime,
    this.location,
    this.isAllDay = false,
    this.color = const Color(0xFF4AC4CF),
    this.notes,
    this.reminderMinutes,
    this.repeatType = RepeatType.none,
    this.repeatEndDate,
    this.attachments = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// 从后端 JSON 创建 Schedule
  factory Schedule.fromJson(Map<String, dynamic> json) {
    // 解析颜色
    Color color = const Color(0xFF4AC4CF);
    if (json['color'] != null) {
      final colorStr = json['color'] as String;
      if (colorStr.startsWith('#')) {
        color = Color(int.parse('FF${colorStr.substring(1)}', radix: 16));
      }
    }

    // 解析开始时间
    TimeOfDay? startTime;
    if (json['startTime'] != null || json['start_time'] != null) {
      final timeStr = (json['startTime'] ?? json['start_time']) as String;
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }

    // 解析结束时间
    TimeOfDay? endTime;
    if (json['endTime'] != null || json['end_time'] != null) {
      final timeStr = (json['endTime'] ?? json['end_time']) as String;
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        endTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
      }
    }

    // 解析附件
    List<ScheduleAttachment> attachments = [];
    if (json['attachments'] != null) {
      attachments = (json['attachments'] as List)
          .map((e) => ScheduleAttachment.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return Schedule(
      id: json['scheduleId'] ?? json['schedule_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? json['user_id'] as String?,
      groupId: json['groupId'] ?? json['group_id'] as String?,
      title: json['title'] as String? ?? '',
      scheduleDate: DateTime.parse(
        json['scheduleDate'] ?? json['schedule_date'] ?? DateTime.now().toIso8601String(),
      ),
      startTime: startTime,
      endTime: endTime,
      location: json['location'] as String?,
      isAllDay: (json['isAllDay'] ?? json['is_all_day'] ?? 0) == 1,
      color: color,
      notes: json['notes'] as String?,
      reminderMinutes: json['reminderMinutes'] ?? json['reminder_minutes'] as int?,
      repeatType: RepeatType.fromString(json['repeatType'] ?? json['repeat_type']),
      repeatEndDate: json['repeatEndDate'] != null || json['repeat_end_date'] != null
          ? DateTime.tryParse((json['repeatEndDate'] ?? json['repeat_end_date']).toString())
          : null,
      attachments: attachments,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  /// 转换为后端 JSON
  Map<String, dynamic> toJson() {
    String? formatTime(TimeOfDay? time) {
      if (time == null) return null;
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }

    String formatColor(Color c) {
      return '#${c.value.toRadixString(16).substring(2).toUpperCase()}';
    }

    return {
      'scheduleId': id,
      if (userId != null) 'userId': userId,
      if (groupId != null) 'groupId': groupId,
      'title': title,
      'scheduleDate': scheduleDate.toIso8601String().split('T')[0],
      if (startTime != null) 'startTime': formatTime(startTime),
      if (endTime != null) 'endTime': formatTime(endTime),
      if (location != null) 'location': location,
      'isAllDay': isAllDay ? 1 : 0,
      'color': formatColor(color),
      if (notes != null) 'notes': notes,
      if (reminderMinutes != null) 'reminderMinutes': reminderMinutes,
      'repeatType': repeatType.value,
      if (repeatEndDate != null) 'repeatEndDate': repeatEndDate!.toIso8601String().split('T')[0],
      if (attachments.isNotEmpty) 'attachments': attachments.map((a) => a.toJson()).toList(),
    };
  }

  /// 获取格式化的时间范围字符串
  String get timeRangeText {
    if (isAllDay) return '全天';
    
    String formatTimeOfDay(TimeOfDay t) {
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    
    if (startTime != null && endTime != null) {
      return '${formatTimeOfDay(startTime!)} - ${formatTimeOfDay(endTime!)}';
    } else if (startTime != null) {
      return formatTimeOfDay(startTime!);
    }
    return '';
  }

  /// 复制并修改部分字段
  Schedule copyWith({
    String? id,
    String? userId,
    String? groupId,
    String? title,
    DateTime? scheduleDate,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    String? location,
    bool? isAllDay,
    Color? color,
    String? notes,
    int? reminderMinutes,
    RepeatType? repeatType,
    DateTime? repeatEndDate,
    List<ScheduleAttachment>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Schedule(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      scheduleDate: scheduleDate ?? this.scheduleDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      isAllDay: isAllDay ?? this.isAllDay,
      color: color ?? this.color,
      notes: notes ?? this.notes,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      repeatType: repeatType ?? this.repeatType,
      repeatEndDate: repeatEndDate ?? this.repeatEndDate,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
