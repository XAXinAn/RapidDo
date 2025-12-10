import 'package:flutter/material.dart';

class Schedule {
  final String id;
  final String title;
  final String location;
  final DateTime startTime;
  final DateTime endTime;
  final Color color;
  final String? notes;
  final List<String>? attachments;

  Schedule({
    required this.id,
    required this.title,
    required this.location,
    required this.startTime,
    required this.endTime,
    required this.color,
    this.notes,
    this.attachments,
  });
}
