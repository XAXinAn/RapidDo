import 'package:flutter/material.dart';
import 'package:jisu_calendar/models/schedule.dart';
import 'package:intl/intl.dart';

class ScheduleDetailScreen extends StatelessWidget {
  final Schedule schedule;

  const ScheduleDetailScreen({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('yyyy年M月d日 HH:mm');

    return Scaffold(
      appBar: AppBar(
        title: Text(schedule.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('标题: ${schedule.title}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('地点: ${schedule.location}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('开始时间: ${timeFormat.format(schedule.startTime)}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('结束时间: ${timeFormat.format(schedule.endTime)}', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            Text('备注: ${schedule.notes ?? '无'}', style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
