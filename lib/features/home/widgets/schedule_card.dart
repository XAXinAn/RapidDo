import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jisu_calendar/models/schedule.dart';

class ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback onTap;

  const ScheduleCard({
    super.key,
    required this.schedule,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final startTime = DateFormat('HH:mm').format(schedule.startTime);
    final endTime = DateFormat('HH:mm').format(schedule.endTime);

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: schedule.color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12.0),
          border: Border(
            left: BorderSide(
              color: schedule.color,
              width: 4.0,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              schedule.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4.0),
                Text(
                  schedule.location,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                const Icon(Icons.access_time_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 4.0),
                Text(
                  '$startTime - $endTime',
                   style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
