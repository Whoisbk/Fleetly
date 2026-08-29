import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class AdminMenuButton extends StatelessWidget {
  const AdminMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: () => Scaffold.of(context).openDrawer(),
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.menu, size: 22),
        ),
      ),
    );
  }
}
