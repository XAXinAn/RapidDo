
import 'package:flutter/material.dart';
import 'package:jisu_calendar/models/schedule.dart';
import 'package:intl/intl.dart';
import 'package:jisu_calendar/features/schedule/screens/add_schedule_screen.dart';
import 'package:jisu_calendar/providers/schedule_provider.dart';
import 'package:provider/provider.dart';

class ScheduleDetailSheet extends StatelessWidget {
  final Schedule schedule;

  const ScheduleDetailSheet({super.key, required this.schedule});

  void _deleteSchedule(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('确认删除'),
          content: const Text('您确定要删除此日程吗？'),
          actions: [
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
            TextButton(
              child: const Text('删除', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Provider.of<ScheduleProvider>(context, listen: false).deleteSchedule(schedule.id);
                Navigator.of(ctx).pop(); // Close the dialog
                Navigator.of(context).pop(); // Close the bottom sheet
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('M月d日');
    final timeFormat = DateFormat('HH:mm');

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Title and Action Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  schedule.title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _deleteSchedule(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () {
                      Navigator.of(context).pop(); // Dismiss the bottom sheet
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => AddScheduleScreen(schedule: schedule),
                      ));
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Details Section
          _buildDetailRow(Icons.calendar_today_outlined, dateFormat.format(schedule.time)),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.access_time_outlined, timeFormat.format(schedule.time)),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.location_on_outlined, schedule.location),
          if (schedule.notes != null && schedule.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailRow(Icons.notes_outlined, schedule.notes!),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
