// lib/shared_widgets/custom_app_bar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/state/auth_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showProfilePicture;

  const CustomAppBar({
    super.key,
    required this.title,
    this.actions,
    this.showProfilePicture = false,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        final hasAvatar =
            user?.avatarUrl != null &&
            user!.avatarUrl!.isNotEmpty &&
            user.avatarUrl != 'null';

        return AppBar(
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0.5,
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            if (showProfilePicture && user != null) ...[
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: hasAvatar
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: !hasAvatar
                          ? Icon(
                              Icons.person,
                              size: 20,
                              color: Colors.grey[600],
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ],
            if (actions != null) ...actions!,
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
