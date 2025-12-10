import 'package:flutter/material.dart';

class AddScheduleScreen extends StatefulWidget {
  const AddScheduleScreen({super.key});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
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
              const ListTile(
                leading: Icon(Icons.access_time, color: Colors.grey),
                title: Text('选择时间'),
                contentPadding: EdgeInsets.zero,
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
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
