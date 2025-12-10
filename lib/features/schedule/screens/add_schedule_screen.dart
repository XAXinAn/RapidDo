import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  final List<PlatformFile> _pickedFiles = [];

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
                Expanded(
                  // Use Expanded to fill the remaining space
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

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() {
        _pickedFiles.addAll(result.files);
      });
    }
  }

  Widget _buildFileIcon(PlatformFile file) {
    final extension = file.extension?.toLowerCase();
    switch (extension) {
      case 'pdf':
        return const FaIcon(FontAwesomeIcons.filePdf, color: Colors.red);
      case 'doc':
      case 'docx':
        return const FaIcon(FontAwesomeIcons.fileWord, color: Colors.blue);
      case 'xls':
      case 'xlsx':
        return const FaIcon(FontAwesomeIcons.fileExcel, color: Colors.green);
      case 'ppt':
      case 'pptx':
        return const FaIcon(FontAwesomeIcons.filePowerpoint, color: Colors.orange);
      default:
        return const Icon(Icons.insert_drive_file_outlined, color: Colors.grey);
    }
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
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('添加日程', style: TextStyle(color: Colors.black, fontSize: 18)),
        centerTitle: false,
        titleSpacing: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.black54),
            onPressed: () {
              // TODO: Implement save schedule logic
              Navigator.of(context).pop();
            },
          ),
        ],
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
              Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.attachment_outlined, color: Colors.grey),
                    title: const Text('添加附件'),
                    contentPadding: EdgeInsets.zero,
                    onTap: _pickFiles,
                  ),
                  if (_pickedFiles.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _pickedFiles.length,
                      itemBuilder: (context, index) {
                        final file = _pickedFiles[index];
                        final isImage = ['jpg', 'jpeg', 'png'].contains(file.extension?.toLowerCase());

                        return ListTile(
                          leading: isImage && file.path != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8.0),
                                  child: Image.file(
                                    File(file.path!),
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : _buildFileIcon(file),
                          title: Text(file.name, overflow: TextOverflow.ellipsis),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _pickedFiles.removeAt(index);
                              });
                            },
                          ),
                          contentPadding: EdgeInsets.zero,
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
