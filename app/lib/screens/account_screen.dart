import 'package:flutter/material.dart';
import '../utils/storage_service.dart';
import 'welcome_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String? userEmail = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final email = await StorageService.getUserEmail();
    setState(() {
      userEmail = email;
    });
  }

  Future<void> _handleLogout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await StorageService.clearAuthData();
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const WelcomeScreen(),
                    ),
                  );
                }
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Account',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // User Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                ),
                child: const Icon(Icons.person, size: 40, color: Colors.grey),
              ),
              const SizedBox(height: 16),

              // User Email
              Text(
                userEmail ?? 'User',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),

              // Account Menu
              _buildMenuTile(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                onTap: () {},
              ),
              _buildMenuTile(
                icon: Icons.location_on_outlined,
                title: 'Addresses',
                onTap: () {},
              ),
              _buildMenuTile(
                icon: Icons.favorite_outline,
                title: 'Wishlist',
                onTap: () {},
              ),
              _buildMenuTile(
                icon: Icons.shopping_bag_outlined,
                title: 'My Orders',
                onTap: () {},
              ),
              _buildMenuTile(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () {},
              ),
              _buildMenuTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {},
              ),
              const SizedBox(height: 30),

              // Logout Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleLogout,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: Colors.grey[600]),
          title: Text(title, style: const TextStyle(fontSize: 16)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: onTap,
        ),
        Divider(color: Colors.grey[200]),
      ],
    );
  }
}
