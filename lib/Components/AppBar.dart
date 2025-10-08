  import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackButton;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.actions,
    this.showBackButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      alignment: Alignment.bottomCenter,
      decoration: BoxDecoration(
      
        color: theme.colorScheme.background,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.border),
        ),
      ),
      child: Row(
        children: [
          if (showBackButton)
            ShadButton.ghost(
              onPressed: () => Navigator.of(context).pop(),
              size: ShadButtonSize.sm,
              child: const Icon(LucideIcons.arrowLeft, size: 20),
            ),
          if (showBackButton) const SizedBox(width: 8),

          /// Title
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.foreground,
              ),
            ),
          ),

          /// Actions (optional)
          if (actions != null) ...[
            const SizedBox(width: 8),
            Row(children: actions!),
          ],
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 8);
}
