import 'package:flutter/material.dart';
import 'package:jisu_calendar/features/profile/screens/profile_screen.dart';
import 'package:jisu_calendar/features/authentication/screens/login_screen.dart';
import 'package:jisu_calendar/models/user.dart';
import 'package:jisu_calendar/providers/schedule_provider.dart';
import 'package:jisu_calendar/providers/ai_chat_provider.dart';
import 'package:jisu_calendar/services/auth_service.dart';
import 'package:jisu_calendar/services/avatar_service.dart';
import 'package:provider/provider.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final AuthService _authService = AuthService();
  final AvatarService _avatarService = AvatarService();
  
  User? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    try {
      final userId = await _authService.getCurrentUserId();
      if (userId != null) {
        final response = await _authService.getUserInfo(userId, requesterId: userId);
        if (response.success && response.data != null) {
          setState(() {
            _user = response.data;
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      print('加载用户信息失败: $e');
    }
    
    // 尝试从本地存储获取用户名
    final userName = await _authService.getCurrentUserName();
    setState(() {
      _user = userName != null ? User(id: '', name: userName) : null;
      _isLoading = false;
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // 清除所有 Provider 缓存
      if (mounted) {
        context.read<ScheduleProvider>().clearAll();
        context.read<AiChatProvider>().reset();
      }
      
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // A helper to create list items
    Widget buildListTile({required IconData icon, required String title, VoidCallback? onTap, Color? iconColor}) {
      return ListTile(
        leading: Icon(icon, color: iconColor ?? Colors.grey.shade700),
        title: Text(title, style: const TextStyle(fontSize: 15)),
        onTap: onTap ?? () => Navigator.pop(context),
        dense: true,
      );
    }

    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () {
              Navigator.pop(context); // Close the drawer first
              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
            },
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/card1.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.white.withOpacity(0.3),
                          backgroundImage: _user?.avatarUrl != null
                              ? NetworkImage(_avatarService.getAvatarUrl(_user?.avatarUrl))
                              : null,
                          child: _user?.avatarUrl == null
                              ? const Icon(Icons.person, size: 36, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _user?.name ?? '用户',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
                          onPressed: () {},
                          tooltip: '通知',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Menu List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8.0),
              children: [
                buildListTile(
                  icon: Icons.workspace_premium_outlined,
                  title: '高级会员',
                  iconColor: Colors.amber.shade700,
                  onTap: () {
                    // TODO: Implement premium member action
                  },
                ),
                buildListTile(icon: Icons.calendar_today_outlined, title: '今天'),
                buildListTile(icon: Icons.note_alt_outlined, title: '个人备忘'),
              ],
            ),
          ),
          // Footer
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              children: [
                 buildListTile(
                  icon: Icons.switch_account_outlined,
                  title: '切换账号',
                  onTap: () {
                    // TODO: Implement account switching
                  },
                ),
                buildListTile(
                  icon: Icons.logout,
                  title: '退出账号',
                  iconColor: Colors.red.shade600,
                  onTap: _logout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
