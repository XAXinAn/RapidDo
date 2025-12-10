import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:intl/intl.dart';
import 'package:jisu_calendar/common/widgets/custom_time_picker.dart';

class AddScheduleScreen extends StatefulWidget {
  const AddScheduleScreen({super.key});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  DateTime? _selectedTime;
  Color _selectedColor = Colors.blue;

  Future<void> _selectTime(BuildContext context) async {
    final DateTime? picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: CustomTimePicker(initialDate: _selectedTime ?? DateTime.now()),
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _selectColor() {
    Color pickerColor = _selectedColor;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            height: 500, // Set a fixed height
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('选择颜色', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                Expanded( // Use Expanded to fill the remaining space
                  child: SingleChildScrollView(
                    child: ColorPicker(
                      pickerColor: pickerColor,
                      onColorChanged: (Color color) {
                        pickerColor = color;
                      },
                      hexInputBar: true,
                      pickerAreaHeightPercent: 0.7,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      TextButton(
                        child: const Text('取消', style: TextStyle(fontSize: 16)),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(height: 30, child: VerticalDivider()),
                      TextButton(
                        child: const Text('保存', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          setState(() => _selectedColor = pickerColor);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 24.0, top: 16.0, bottom: 8.0),
          child: Text(title, style: const TextStyle(color: Colors.grey)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: content,
        ),
      ],
    );
  }

  Widget _buildTextField({required IconData icon, required String hint}) {
    return TextField(
      decoration: InputDecoration(
        icon: Icon(icon, color: Colors.grey),
        hintText: hint,
        border: InputBorder.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy年M月d日 EEE HH:mm', 'zh_CN');
    final String timeText = _selectedTime != null ? dateFormat.format(_selectedTime!) : '选择时间';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('添加日程'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              '基本信息',
              Column(
                children: [
                  _buildTextField(icon: Icons.title, hint: '标题'),
                  const Divider(),
                  _buildTextField(icon: Icons.location_on_outlined, hint: '地点'),
                ],
              ),
            ),
            _buildSection(
              '时间',
              ListTile(
                leading: const Icon(Icons.access_time, color: Colors.grey),
                title: Text(timeText),
                contentPadding: EdgeInsets.zero,
                onTap: () => _selectTime(context),
              ),
            ),
            _buildSection(
              '颜色',
              ListTile(
                leading: const Icon(Icons.colorize, color: Colors.grey),
                title: const Text('选择颜色'),
                trailing: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    shape: BoxShape.circle,
                  ),
                ),
                contentPadding: EdgeInsets.zero,
                onTap: _selectColor,
              ),
            ),
            _buildSection(
              '备注',
              const TextField(
                decoration: InputDecoration(
                  hintText: '添加备注信息 (选填)',
                  border: InputBorder.none,
                ),
                maxLines: 4,
              ),
            ),
            _buildSection(
              '附件',
              ListTile(
                leading: const Icon(Icons.attachment_outlined, color: Colors.grey),
                title: const Text('添加附件'),
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  // TODO: implement attachment picking logic
                },
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
