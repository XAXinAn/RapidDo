import 'package:flutter/material.dart';
import 'package:jisu_calendar/features/profile/screens/profile_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

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
                          child: const Icon(
                            Icons.person,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          '九号线', // Placeholder name
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
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
                  onTap: () {
                    // TODO: Implement logout
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
