import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/status_bar_controller.dart';
import '../../domain/entities/status_bar_menu_item.dart';

class StatusBarMenu extends StatelessWidget {
  const StatusBarMenu({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<StatusBarController>(context);
    final theme = Theme.of(context);

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const Divider(height: 1),
          ...controller.menuItems
              .map((item) => _buildMenuItem(context, item))
              .toList(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Image.asset(
            'assets/images/app_icon.png',
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                Icons.screenshot_monitor,
                size: 24,
                color: Theme.of(context).primaryColor,
              );
            },
          ),
          const SizedBox(width: 12),
          Text(
            'Snipwise',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            onPressed: () {
              // TODO: Open settings
            },
            tooltip: 'Settings',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, StatusBarMenuItem item) {
    if (item.isDivider) {
      return const Divider(height: 1);
    }

    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Row(
          children: [
            if (item.icon != null)
              Icon(item.icon,
                  size: 20, color: Theme.of(context).iconTheme.color),
            if (item.icon != null) const SizedBox(width: 12),
            Text(
              item.title,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Spacer(),
            if (item.shortcut != null)
              Text(
                item.shortcut!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.color
                          ?.withOpacity(0.6),
                    ),
              ),
            if (item.hasSubMenu)
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: Theme.of(context).iconTheme.color?.withOpacity(0.6),
              ),
          ],
        ),
      ),
    );
  }
}
