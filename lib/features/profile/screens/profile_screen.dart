import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('个人资料'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.black54),
          titleTextStyle: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        body: ListView(
          children: [
            const SizedBox(height: 16),
            _buildSection([
              _buildInfoTile(
                context,
                title: '头像',
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey.shade300,
                      child: const Icon(Icons.person, color: Colors.white, size: 40),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
              ),
              _buildInfoTile(context, title: '名字', value: '九号线'),
              _buildInfoTile(context, title: '性别', value: '男'),
              _buildInfoTile(context, title: '地区', value: '浙江 台州'),
            ]),
            const SizedBox(height: 16),
            _buildSection([
              _buildInfoTile(context, title: '手机号', value: '180****06'),
              _buildInfoTile(context, title: '邮箱', value: '未填写'),
              _buildInfoTile(context, title: '微信号', value: 'NEWYORK20050304'),
              _buildInfoTile(
                context,
                title: '我的二维码',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.qr_code, color: Colors.grey),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  ],
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, {required String title, String? value, Widget? trailing, EdgeInsetsGeometry? contentPadding}) {
    return ListTile(
      contentPadding: contentPadding,
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value ?? '', style: const TextStyle(color: Colors.grey, fontSize: 16)),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            ],
          ),
      onTap: () {
        // TODO: Navigate to the respective editing page
      },
    );
  }
}
