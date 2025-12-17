import 'package:flutter/material.dart';
import 'package:jisu_calendar/models/user.dart';
import 'package:jisu_calendar/services/auth_service.dart';
import 'package:jisu_calendar/services/avatar_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final AvatarService _avatarService = AvatarService();
  
  User? _user;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final userId = await _authService.getCurrentUserId();
      if (userId == null) {
        setState(() {
          _error = '未登录';
          _isLoading = false;
        });
        return;
      }

      // 获取用户信息，requesterId 传自己的 ID 以获取完整信息
      final response = await _authService.getUserInfo(userId, requesterId: userId);
      
      if (response.success && response.data != null) {
        setState(() {
          _user = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message ?? '获取用户信息失败';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

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
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadUserInfo,
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUserInfo,
      child: ListView(
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
                    backgroundImage: _user?.avatarUrl != null
                        ? NetworkImage(_avatarService.getAvatarUrl(_user?.avatarUrl))
                        : null,
                    child: _user?.avatarUrl == null
                        ? const Icon(Icons.person, color: Colors.white, size: 40)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ],
              ),
            ),
            _buildInfoTile(context, title: '名字', value: _user?.name ?? '未设置'),
            _buildInfoTile(context, title: '性别', value: _user?.genderText ?? '未知'),
            _buildInfoTile(context, title: '生日', value: _user?.birthday ?? '未填写'),
            _buildInfoTile(context, title: '个人简介', value: _user?.bio ?? '未填写'),
          ]),
          const SizedBox(height: 16),
          _buildSection([
            _buildInfoTile(context, title: '手机号', value: _maskPhone(_user?.phone)),
            _buildInfoTile(context, title: '邮箱', value: _user?.email ?? '未填写'),
          ]),
          const SizedBox(height: 16),
          _buildSection([
            _buildInfoTile(context, title: '注册方式', value: _user?.loginType == 'phone' ? '手机号注册' : '邮箱注册'),
            _buildInfoTile(context, title: '注册时间', value: _formatDate(_user?.createdAt)),
          ]),
        ],
      ),
    );
  }

  /// 手机号脱敏显示
  String _maskPhone(String? phone) {
    if (phone == null || phone.isEmpty) return '未绑定';
    if (phone.length == 11) {
      return '${phone.substring(0, 3)}****${phone.substring(7)}';
    }
    return phone;
  }

  /// 格式化日期
  String _formatDate(DateTime? date) {
    if (date == null) return '未知';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
