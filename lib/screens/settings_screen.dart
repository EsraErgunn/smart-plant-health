import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/locale_provider.dart';
import '../l10n/gen/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localeProvider = Provider.of<LocaleProvider>(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(l10n.theme),
            secondary: const Icon(Icons.dark_mode),
            value: themeProvider.isDarkMode,
            onChanged: (value) {
              themeProvider.toggleTheme(value);
            },
          ),
          const Divider(),
          ListTile(
            title: Text(l10n.language),
            leading: const Icon(Icons.language),
            subtitle: Text(localeProvider.locale.languageCode == 'tr' ? "Türkçe" : "English"),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                localeProvider.setLocale(Locale(value));
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'en', child: Text("English")),
                const PopupMenuItem(value: 'tr', child: Text("Türkçe")),
              ],
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text("Version"),
            subtitle: Text("2.0.0"),
            leading: Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }
}
