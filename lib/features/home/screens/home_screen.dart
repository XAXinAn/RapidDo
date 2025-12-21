import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jisu_calendar/common/widgets/custom_date_picker.dart';
import 'package:jisu_calendar/features/ai/screens/ai_chat_screen.dart';
import 'package:jisu_calendar/features/home/widgets/app_drawer.dart';
import 'package:jisu_calendar/features/schedule/screens/add_schedule_screen.dart';
import 'package:jisu_calendar/features/schedule/screens/schedule_detail_screen.dart';
import 'package:jisu_calendar/models/schedule.dart';
import 'package:jisu_calendar/features/home/widgets/schedule_card.dart';
import 'package:jisu_calendar/providers/schedule_provider.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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

  @override
  void initState() {
    super.initState();
    // 监听应用生命周期
    WidgetsBinding.instance.addObserver(this);
    
    _hintTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _currentHintIndex = (_currentHintIndex + 1) % _hints.length;
        });
      }
    });
    
    // 加载当前月份的日程
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSchedulesForCurrentMonth();
    });
  }

  void _loadSchedulesForCurrentMonth() {
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    // 始终强制刷新，确保从服务器获取最新数据
    scheduleProvider.loadSchedulesForMonth(_focusedDay.year, _focusedDay.month, forceRefresh: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 当应用从后台恢复到前台时，刷新日程（处理悬浮窗添加日程的场景）
    if (state == AppLifecycleState.resumed && mounted) {
      _loadSchedulesForCurrentMonth();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
      padding: const EdgeInsets.symmetric(horizontal: 16), // Adjust padding
      child: Text(title, style: const TextStyle(fontSize: 16)),
    );
  }

  Widget _buildAiInputBox() {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          await Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => const AiChatScreen(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 1000),
              reverseTransitionDuration: const Duration(milliseconds: 1000),
            ),
          );
          // 从 AI 聊天页面返回后，强制刷新当前聚焦月份的日程
          if (mounted) {
            _loadSchedulesForCurrentMonth();
          }
        },
        child: Hero(
          tag: 'ai-chat-box',
          child: Material(
            color: Colors.transparent,
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
    final scheduleProvider = Provider.of<ScheduleProvider>(context);
    final selectedSchedules = scheduleProvider.getSchedulesForDay(_selectedDay ?? DateTime.now());

    return Scaffold(
      key: _scaffoldKey,
      drawer: SizedBox(
        width: MediaQuery.of(context).size.width * 3 / 4,
        child: const AppDrawer(),
      ),
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
              // Fixed top action bar
              Container(
                height: 56,
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () {
                        _scaffoldKey.currentState?.openDrawer();
                      },
                      icon: const Icon(Icons.person_outline),
                      iconSize: 28,
                      color: Colors.black54,
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                    ),
                    _buildAiInputBox(),
                    IconButton(
                      onPressed: () {
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
                      color: Colors.white,
                      itemBuilder: (BuildContext context) {
                        return <PopupMenuEntry<String>>[
                          _buildPopupMenuItem('跳转到指定日期', 'jump_to_date'),
                          const PopupMenuDivider(height: 1, indent: 16, endIndent: 16),
                          _buildPopupMenuItem('跳转到今天', 'jump_to_today'),
                          const PopupMenuDivider(height: 1, indent: 16, endIndent: 16),
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
              // Scrollable content area
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildCalendarHeader(),
                      TableCalendar(
                        locale: 'zh_CN',
                        headerVisible: false,
                        calendarFormat: CalendarFormat.week,
                        firstDay: DateTime.utc(2010, 10, 16),
                        lastDay: DateTime.utc(2030, 3, 14),
                        focusedDay: _focusedDay,
                        eventLoader: scheduleProvider.getSchedulesForDay,
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
                          // 加载新月份的日程（强制刷新）
                          final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
                          scheduleProvider.loadSchedulesForMonth(focusedDay.year, focusedDay.month, forceRefresh: true);
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
                           markerBuilder: (context, day, events) {
                            final isSelected = isSameDay(_selectedDay, day);
                            final isToday = isSameDay(day, DateTime.now());
                            final hasEvents = events.isNotEmpty;

                            if (!hasEvents) return null;

                            Color markerColor = Colors.grey.shade700;
                            if (isSelected) {
                              markerColor = Colors.white;
                            } else if (isToday) {
                              markerColor = theme.colorScheme.primary;
                            }

                            return Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: markerColor,
                                  shape: BoxShape.circle,
                                ),
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
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: selectedSchedules.length,
                        itemBuilder: (context, index) {
                          final schedule = selectedSchedules[index];
                          return ScheduleCard(
                            schedule: schedule,
                            onTap: () {
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                builder: (context) {
                                  return ScheduleDetailSheet(schedule: schedule);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
