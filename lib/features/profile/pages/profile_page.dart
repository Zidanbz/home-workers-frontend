// Lokasi file: lib/features/profile/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:home_workers_fe/features/notifications/pages/notification_page.dart';
import 'package:home_workers_fe/features/profile/pages/address_management_page.dart';
import 'package:home_workers_fe/features/profile/pages/edit_profile_page.dart';
import 'package:provider/provider.dart';
import '../../../core/state/auth_provider.dart';

// TODO: Buat file-file ini di lokasi yang sesuai
// import 'edit_profile_page.dart';
// import 'address_management_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // --- PERUBAHAN 1: Logika untuk menampilkan gambar profil ---
        // Cek apakah user memiliki avatarUrl
        final bool hasAvatar =
            user.avatarUrl != null && user.avatarUrl!.isNotEmpty;
        final ImageProvider profileImage = hasAvatar
            ? NetworkImage(user.avatarUrl!)
            : const NetworkImage(
                'https://i.pravatar.cc/150?img=32',
              ); // Gambar default

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Profil',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            elevation: 0.5,
            automaticallyImplyLeading: false,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            children: [
              Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      // TODO: Navigasi ke halaman ganti foto profil
                    },
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: profileImage,
                      child: Align(
                        alignment: Alignment.bottomRight,
                        child: CircleAvatar(
                          radius: 15,
                          backgroundColor: Colors.grey.shade200,
                          child: const Icon(
                            Icons.camera_alt,
                            size: 18,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.nama,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user.email,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const Divider(),

              // --- PERUBAHAN 2: Menambahkan navigasi pada menu ---
              _buildProfileMenuItem(
                icon: Icons.person_outline,
                title: 'Edit Profil',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => EditProfilePage(user: user),
                    ),
                  );
                },
              ),
              _buildProfileMenuItem(
                icon: Icons.location_on_outlined,
                title: 'Alamat Tersimpan',
                onTap: () {
                  // --- PERUBAHAN UTAMA: Navigasi ke halaman alamat ---
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddressManagementPage(),
                    ),
                  );
                },
              ),
              _buildProfileMenuItem(
                icon: Icons.notifications_outlined,
                title: 'Notifikasi',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const NotificationPage(),
                    ),
                  );
                },
              ),
              _buildProfileMenuItem(
                icon: Icons.lock_outline,
                title: 'Keamanan',
                onTap: () {},
              ),
              const Divider(),
              _buildProfileMenuItem(
                icon: Icons.help_outline,
                title: 'Pusat Bantuan',
                onTap: () {},
              ),
              _buildProfileMenuItem(
                icon: Icons.logout,
                title: 'Logout',
                textColor: Colors.red,
                onTap: () async {
                  await Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  ).logout();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color textColor = Colors.black87,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor),
      title: Text(
        title,
        style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
