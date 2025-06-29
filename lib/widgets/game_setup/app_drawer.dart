import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:scorecard/providers/user_preferences_provider.dart';
import 'package:scorecard/screens/team_list.dart';
import 'package:scorecard/screens/game_history.dart';

/// A shared app drawer widget that includes navigation and settings
class AppDrawer extends StatelessWidget {
  final String currentRoute;

  const AppDrawer({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    final userPreferences = Provider.of<UserPreferencesProvider>(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // App Header
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Score Card',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Theme.of(context).colorScheme.onPrimary,
                    BlendMode.srcIn,
                  ),
                  child: Image.asset(
                    'assets/icon/app_icon_masked.png',
                    width: 64,
                    height: 64,
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ),

          // Favorite Team
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: const Text('Favorite Team'),
            subtitle: Text(
              userPreferences.favoriteTeam.isEmpty
                  ? 'Not set'
                  : userPreferences.favoriteTeam,
            ),
            trailing:
                userPreferences.favoriteTeam.isNotEmpty
                    ? IconButton(
                      onPressed: () => userPreferences.setFavoriteTeam(''),
                      icon: const Icon(Icons.clear_outlined),
                      tooltip: 'Clear favorite team',
                    )
                    : null,
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push<String>(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => TeamList(
                        title: 'Select Favorite Team',
                        onTeamSelected: (teamName) {
                          userPreferences.setFavoriteTeam(teamName);
                        },
                      ),
                ),
              );
            },
          ),

          // Navigation Items
          if (currentRoute != 'game_history')
            ListTile(
              leading: const Icon(Icons.history_outlined),
              title: const Text('Game History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const GameHistoryScreen(),
                  ),
                );
              },
            ),

          // Theme Mode
          GestureDetector(
            onTapDown:
                (TapDownDetails details) => _showThemeModeMenu(
                  context,
                  userPreferences,
                  details.globalPosition,
                ),
            child: ListTile(
              leading: Icon(_getThemeModeIcon(userPreferences.themeMode)),
              title: Text(_getThemeModeText(userPreferences.themeMode)),
              trailing: const Icon(Icons.keyboard_arrow_down),
            ),
          ),

          // Color Theme
          GestureDetector(
            onTapDown:
                (TapDownDetails details) => _showColorThemeMenu(
                  context,
                  userPreferences,
                  details.globalPosition,
                ),
            child: ListTile(
              leading: Icon(
                Icons.palette_outlined,
                color:
                    userPreferences.colorTheme == 'adaptive'
                        ? Theme.of(context).colorScheme.primary
                        : userPreferences.getThemeColor(),
              ),
              title: Text(_getColorThemeText(userPreferences.colorTheme)),
              trailing: const Icon(Icons.keyboard_arrow_down),
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeModeText(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  IconData _getThemeModeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }

  String _getColorThemeText(String theme) {
    switch (theme) {
      case 'adaptive':
        return 'Adaptive';
      case 'blue':
        return 'Blue';
      case 'green':
        return 'Green';
      case 'purple':
        return 'Purple';
      case 'orange':
        return 'Orange';
      default:
        return 'Adaptive';
    }
  }

  void _showThemeModeMenu(
    BuildContext context,
    UserPreferencesProvider provider,
    Offset tapPosition,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(tapPosition, tapPosition),
      Offset.zero & overlay.size,
    );

    showMenu<ThemeMode>(
      context: context,
      position: position,
      items: [
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.light,
          child: Row(
            children: [
              const Icon(Icons.light_mode_outlined),
              const SizedBox(width: 12),
              const Text('Light'),
              if (provider.themeMode == ThemeMode.light) ...[
                const Spacer(),
                Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
              ],
            ],
          ),
        ),
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.dark,
          child: Row(
            children: [
              const Icon(Icons.dark_mode_outlined),
              const SizedBox(width: 12),
              const Text('Dark'),
              if (provider.themeMode == ThemeMode.dark) ...[
                const Spacer(),
                Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
              ],
            ],
          ),
        ),
        PopupMenuItem<ThemeMode>(
          value: ThemeMode.system,
          child: Row(
            children: [
              const Icon(Icons.brightness_auto_outlined),
              const SizedBox(width: 12),
              const Text('System'),
              if (provider.themeMode == ThemeMode.system) ...[
                const Spacer(),
                Icon(Icons.check, color: Theme.of(context).colorScheme.primary),
              ],
            ],
          ),
        ),
      ],
    ).then((ThemeMode? result) {
      if (result != null) {
        provider.setThemeMode(result);
      }
    });
  }

  void _showColorThemeMenu(
    BuildContext context,
    UserPreferencesProvider provider,
    Offset tapPosition,
  ) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(tapPosition, tapPosition),
      Offset.zero & overlay.size,
    );

    final colorOptions = <Map<String, dynamic>>[
      // Show adaptive only if device supports it
      if (provider.supportsDynamicColors)
        {
          'value': 'adaptive',
          'label': 'Adaptive',
          'color': const Color(0xFF6750A4), // Material 3 baseline for adaptive
        },
      {'value': 'blue', 'label': 'Blue', 'color': const Color(0xFF1565C0)},
      {'value': 'green', 'label': 'Green', 'color': const Color(0xFF4CAF50)},
      {'value': 'purple', 'label': 'Purple', 'color': const Color(0xFF9C27B0)},
      {'value': 'orange', 'label': 'Orange', 'color': const Color(0xFFFF9800)},
    ];

    showMenu<String>(
      context: context,
      position: position,
      items:
          colorOptions.map((option) {
            return PopupMenuItem<String>(
              value: option['value'] as String,
              child: Row(
                children: [
                  Icon(
                    Icons.palette_outlined,
                    size: 16,
                    color:
                        option['value'] == 'adaptive'
                            ? Theme.of(context).colorScheme.primary
                            : option['color'] as Color,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(option['label'] as String)),
                  if (provider.colorTheme == option['value']) ...[
                    const SizedBox(width: 8),
                    Icon(
                      Icons.check,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
    ).then((String? result) {
      if (result != null) {
        provider.setColorTheme(result);
      }
    });
  }
}
