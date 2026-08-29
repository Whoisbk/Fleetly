import 'package:flutter/material.dart';
import '../../../core/theme/app_text_styles.dart';
import 'admin_menu_button.dart';

class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    this.title,
    this.subtitle,
    this.trailing,
    this.showMenu = true,
    this.subtitleFirst = false,
  });

  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final bool showMenu;
  final bool subtitleFirst;

  @override
  Widget build(BuildContext context) {
    final titleWidget = title != null ? Text(title!, style: AppTextStyles.pageTitle()) : null;
    final subtitleWidget = subtitle != null
        ? Text(subtitle!, style: AppTextStyles.body(color: Colors.grey))
        : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showMenu) ...[
          const AdminMenuButton(),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (subtitleFirst && subtitleWidget != null) ...[
                subtitleWidget,
                if (titleWidget != null) const SizedBox(height: 4),
              ],
              if (titleWidget != null) titleWidget,
              if (!subtitleFirst && subtitleWidget != null) ...[
                if (titleWidget != null) const SizedBox(height: 4),
                subtitleWidget,
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
