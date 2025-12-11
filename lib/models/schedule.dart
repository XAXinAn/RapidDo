import 'package:flutter/material.dart';

class Schedule {
  final String id;
  final String title;
  final String location;
  final DateTime time;
  final Color color;
  final String? notes;
  final List<String>? attachments;

  Schedule({
    required this.id,
    required this.title,
    required this.location,
    required this.time,
    required this.color,
    this.notes,
    this.attachments,
  });
}
