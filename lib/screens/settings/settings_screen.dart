import 'package:flutter/material.dart';

// Convert to StatefulWidget to manage settings state
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // State variables for settings
  bool _soundEffectsEnabled = true; // Default value
  bool _backgroundMusicEnabled = true; // Default value
  String _selectedTheme = 'Default'; // Only option for now

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS'),
        // Optional: Add back button automatically handled by Navigator
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Sound Effects Toggle
          SwitchListTile(
            secondary: const Icon(Icons.volume_up),
            title: const Text('Sound Effects'),
            value: _soundEffectsEnabled,
            onChanged: (bool value) {
              setState(() {
                _soundEffectsEnabled = value;
                // TODO: Add logic to actually enable/disable sound effects
              });
            },
            activeColor: Theme.of(context).colorScheme.secondary, // Use theme color
          ),
          // Background Music Toggle
          SwitchListTile(
            secondary: const Icon(Icons.music_note),
            title: const Text('Background Music'),
            value: _backgroundMusicEnabled,
            onChanged: (bool value) {
              setState(() {
                _backgroundMusicEnabled = value;
                // TODO: Add logic to actually enable/disable background music
              });
            },
             activeColor: Theme.of(context).colorScheme.secondary, // Use theme color
          ),
          // Theme Selection (Placeholder Menu)
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: const Text('Theme'),
            trailing: Text(_selectedTheme), // Display current selection
            onTap: () {
              // TODO: Implement theme selection dialog/menu later
              // For now, just show a snackbar or do nothing
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Theme selection coming soon!')),
              );
            },
          ),
          const Divider(),
          // About Tile (remains the same)
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('About'),
            // Navigate to an About page later
          ),
        ],
      ),
    );
  }
}
