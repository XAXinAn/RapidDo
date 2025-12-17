
import 'package:flutter/material.dart';
import 'package:jisu_calendar/models/schedule.dart';
import 'package:intl/intl.dart';
import 'package:jisu_calendar/features/schedule/screens/add_schedule_screen.dart';
import 'package:jisu_calendar/providers/schedule_provider.dart';
import 'package:provider/provider.dart';

class ScheduleDetailSheet extends StatefulWidget {
  final Schedule schedule;

  const ScheduleDetailSheet({super.key, required this.schedule});

  @override
  State<ScheduleDetailSheet> createState() => _ScheduleDetailSheetState();
}

class _ScheduleDetailSheetState extends State<ScheduleDetailSheet> {
  bool _isDeleting = false;

  Future<void> _deleteSchedule(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('确认删除'),
          content: const Text('您确定要删除此日程吗？'),
          actions: [
            TextButton(
              child: const Text('取消'),
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            TextButton(
              child: const Text('删除', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    final success = await scheduleProvider.deleteSchedule(widget.schedule.id);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(); // Close the bottom sheet
    } else {
      setState(() {
        _isDeleting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(scheduleProvider.error ?? '删除失败')),
      );
    }
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
                  widget.schedule.title,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              Row(
                children: [
                  _isDeleting
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteSchedule(context),
                        ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: _isDeleting ? null : () {
                      Navigator.of(context).pop(); // Dismiss the bottom sheet
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => AddScheduleScreen(schedule: widget.schedule),
                      ));
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Details Section
          _buildDetailRow(Icons.calendar_today_outlined, dateFormat.format(widget.schedule.scheduleDate)),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.access_time_outlined, widget.schedule.timeRangeText),
          const SizedBox(height: 16),
          _buildDetailRow(Icons.location_on_outlined, widget.schedule.location ?? '未设置'),
          if (widget.schedule.notes != null && widget.schedule.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailRow(Icons.notes_outlined, widget.schedule.notes!),
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
