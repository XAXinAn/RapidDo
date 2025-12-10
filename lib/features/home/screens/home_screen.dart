import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jisu_calendar/common/widgets/custom_date_picker.dart';
import 'package:jisu_calendar/features/schedule/screens/add_schedule_screen.dart';
import 'package:jisu_calendar/features/schedule/screens/schedule_detail_screen.dart';
import 'package:jisu_calendar/models/schedule.dart';
import 'package:jisu_calendar/features/home/widgets/schedule_card.dart';
import 'package:table_calendar/table_calendar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  late final Timer _hintTimer;
  int _currentHintIndex = 0;
  final List<String> _hints = [
    '输入文字生成日程',
    '模糊时间精准识别',
    '智能检测时间冲突',
    '复制文本一键添加',
    '复杂通知秒变日程',
  ];

  // Mock data for schedules
  final Map<DateTime, List<Schedule>> _schedulesByDay = {
    DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day): [
      Schedule(
        id: '1',
        title: '计算机网络',
        location: '@教学楼 138(新校区)',
        startTime: DateTime.now().copyWith(hour: 8, minute: 0),
        endTime: DateTime.now().copyWith(hour: 9, minute: 40),
        color: Colors.pink.shade300,
        notes: '带电脑，复习上节课内容。',
      ),
      Schedule(
        id: '2',
        title: '编译原理',
        location: '@教学楼 335(新校区)',
        startTime: DateTime.now().copyWith(hour: 10, minute: 0),
        endTime: DateTime.now().copyWith(hour: 11, minute: 40),
        color: Colors.pink.shade300,
      ),
      Schedule(
        id: '3',
        title: '网络应用开发技术',
        location: '@公共实验楼 3-1号机房',
        startTime: DateTime.now().copyWith(hour: 14, minute: 30),
        endTime: DateTime.now().copyWith(hour: 16, minute: 0),
        color: Colors.blue.shade300,
        notes: '完成实验报告。',
      ),
    ],
    DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day + 1): [
      Schedule(
        id: '4',
        title: '操作系统',
        location: '@教学楼 203(新校区)',
        startTime: DateTime.now().add(const Duration(days: 1)).copyWith(hour: 10, minute: 0),
        endTime: DateTime.now().add(const Duration(days: 1)).copyWith(hour: 11, minute: 40),
        color: Colors.orange.shade300,
      ),
    ],
  };

  List<Schedule> _getSchedulesForDay(DateTime day) {
    final dayUtc = DateTime.utc(day.year, day.month, day.day);
    return _schedulesByDay[dayUtc] ?? [];
  }

  @override
  void initState() {
    super.initState();
    _hintTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _currentHintIndex = (_currentHintIndex + 1) % _hints.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _hintTimer.cancel();
    super.dispose();
  }

  Future<void> _jumpToDate() async {
    final DateTime? picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: CustomDatePicker(initialDate: _focusedDay),
        );
      },
    );
    if (picked != null && picked != _focusedDay) {
      setState(() {
        _focusedDay = picked;
        _selectedDay = picked;
      });
    }
  }

  void _jumpToToday() {
    setState(() {
      _focusedDay = DateTime.now();
      _selectedDay = DateTime.now();
    });
  }

  PopupMenuItem<String> _buildPopupMenuItem(String title, String value) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Center(
        child: Text(title, style: const TextStyle(fontSize: 16)),
      ),
    );
  }

  Widget _buildAiInputBox() {
    return Expanded(
      child: Container(
        height: 40,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF64D8D8), Color(0xFF8A78F2)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.5),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.auto_awesome, color: Colors.grey, size: 20),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Text(
                  _hints[_currentHintIndex],
                  key: ValueKey<String>(_hints[_currentHintIndex]),
                  style: const TextStyle(color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final headerText = DateFormat.yM('zh_CN').format(_focusedDay);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.black54),
            onPressed: () {
              setState(() {
                _focusedDay = _focusedDay.subtract(const Duration(days: 7));
              });
            },
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          Expanded(
            child: Text(
              headerText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.black54),
            onPressed: () {
              setState(() {
                _focusedDay = _focusedDay.add(const Duration(days: 7));
              });
            },
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedSchedules = _getSchedulesForDay(_selectedDay ?? DateTime.now());

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple[50]!,
              Colors.blue[50]!,
              Colors.white,
            ],
            stops: const [0.0, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Container(
                height: 56,
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.person_outline),
                      iconSize: 28,
                      color: Colors.black54,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    _buildAiInputBox(),
                    IconButton(
                      onPressed: () {
                        // Navigate to the new schedule screen
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const AddScheduleScreen(),
                        ));
                      },
                      icon: const Icon(Icons.add),
                      iconSize: 28,
                      color: Colors.black54,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'jump_to_date') {
                          _jumpToDate();
                        } else if (value == 'jump_to_today') {
                          _jumpToToday();
                        }
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      offset: const Offset(0, 40),
                      color: Colors.white.withOpacity(0.8),
                      itemBuilder: (BuildContext context) {
                        return [
                          _buildPopupMenuItem('跳转到指定日期', 'jump_to_date'),
                          const PopupMenuDivider(height: 1),
                          _buildPopupMenuItem('跳转到今天', 'jump_to_today'),
                          const PopupMenuDivider(height: 1),
                          _buildPopupMenuItem('更多', 'more'),
                        ];
                      },
                      icon: const Icon(Icons.more_horiz, color: Colors.black54),
                      padding: EdgeInsets.zero,
                      splashRadius: 1,
                    ),
                  ],
                ),
              ),
              _buildCalendarHeader(),
              TableCalendar(
                locale: 'zh_CN',
                headerVisible: false,
                calendarFormat: CalendarFormat.week,
                firstDay: DateTime.utc(2010, 10, 16),
                lastDay: DateTime.utc(2030, 3, 14),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onPageChanged: (focusedDay) {
                  setState(() {
                    _focusedDay = focusedDay;
                  });
                },
                calendarBuilders: CalendarBuilders(
                  dowBuilder: (context, day) {
                    const List<String> weekdays = ['一', '二', '三', '四', '五', '六', '日'];
                    final text = weekdays[day.weekday - 1];
                    return Center(
                      child: Text(
                        text,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    );
                  },
                ),
                calendarStyle: CalendarStyle(
                  defaultTextStyle: const TextStyle(),
                  weekendTextStyle: const TextStyle(),
                  outsideTextStyle: const TextStyle(color: Colors.grey),
                  todayDecoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.75),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: selectedSchedules.length,
                  itemBuilder: (context, index) {
                    final schedule = selectedSchedules[index];
                    return ScheduleCard(
                      schedule: schedule,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ScheduleDetailScreen(schedule: schedule),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
