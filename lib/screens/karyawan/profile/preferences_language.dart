import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile/services/translation_service.dart';

class PreferencesLanguageScreenKaryawan extends StatefulWidget {
  const PreferencesLanguageScreenKaryawan({super.key});

  @override
  State<PreferencesLanguageScreenKaryawan> createState() => _PreferencesLanguageScreenKaryawanState();
}

class _PreferencesLanguageScreenKaryawanState extends State<PreferencesLanguageScreenKaryawan> {
  final Color navyColor = const Color(0xFF0C4B8E);
  final Color cyanColor = const Color(0xFF42C6D4);

  // Preference states
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _orderStatusUpdates = true;
  bool _darkTheme = false;
  bool _soundEffects = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('pref_push_notif') ?? true;
      _emailNotifications = prefs.getBool('pref_email_notif') ?? false;
      _orderStatusUpdates = prefs.getBool('pref_status_notif') ?? true;
      _darkTheme = prefs.getBool('pref_dark_theme') ?? false;
      _soundEffects = prefs.getBool('pref_sound_fx') ?? true;
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: navyColor.withOpacity(0.6),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildLanguageTile({
    required String title,
    required String code,
    required String flag,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? cyanColor : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: navyColor,
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded, color: cyanColor, size: 22)
            else
              Icon(Icons.circle_outlined, color: Colors.grey.shade300, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cyanColor.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: cyanColor, size: 20),
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: navyColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
        trailing: Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: cyanColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: TranslationService.languageNotifier,
      builder: (context, lang, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFBCEFF2), // Soft Cyan Signature
          extendBody: true,
          body: Column(
            children: [
              // Header Header
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          icon: Icon(Icons.arrow_back_ios_new_rounded, color: navyColor, size: 20),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Text(
                        TranslationService.translate('preferences'),
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: navyColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // White Content Card Sheet
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFC),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 15,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 30, 24, 100),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(TranslationService.translate('language_bahasa')),
                          _buildLanguageTile(
                            title: 'English (US)',
                            code: 'en',
                            flag: '🇺🇸',
                            isSelected: lang == 'en',
                            onTap: () {
                              TranslationService.setLanguage('en');
                            },
                          ),
                          _buildLanguageTile(
                            title: 'Bahasa Indonesia',
                            code: 'id',
                            flag: '🇮🇩',
                            isSelected: lang == 'id',
                            onTap: () {
                              TranslationService.setLanguage('id');
                            },
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1),
                          const SizedBox(height: 16),

                          _buildSectionHeader(TranslationService.translate('notifications')),
                          _buildSwitchTile(
                            title: TranslationService.translate('push_notif'),
                            subtitle: TranslationService.translate('push_notif_sub'),
                            icon: Icons.notifications_none_rounded,
                            value: _pushNotifications,
                            onChanged: (val) {
                              setState(() => _pushNotifications = val);
                              _savePreference('pref_push_notif', val);
                            },
                          ),
                          _buildSwitchTile(
                            title: TranslationService.translate('email_notif'),
                            subtitle: TranslationService.translate('email_notif_sub'),
                            icon: Icons.alternate_email_rounded,
                            value: _emailNotifications,
                            onChanged: (val) {
                              setState(() => _emailNotifications = val);
                              _savePreference('pref_email_notif', val);
                            },
                          ),
                          _buildSwitchTile(
                            title: TranslationService.translate('status_notif'),
                            subtitle: TranslationService.translate('status_notif_sub'),
                            icon: Icons.local_laundry_service_outlined,
                            value: _orderStatusUpdates,
                            onChanged: (val) {
                              setState(() => _orderStatusUpdates = val);
                              _savePreference('pref_status_notif', val);
                            },
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1),
                          const SizedBox(height: 16),

                          _buildSectionHeader(TranslationService.translate('app_settings')),
                          _buildSwitchTile(
                            title: TranslationService.translate('dark_theme'),
                            subtitle: TranslationService.translate('dark_theme_sub'),
                            icon: Icons.dark_mode_outlined,
                            value: _darkTheme,
                            onChanged: (val) {
                              setState(() => _darkTheme = val);
                              _savePreference('pref_dark_theme', val);
                            },
                          ),
                          _buildSwitchTile(
                            title: TranslationService.translate('sound_effects'),
                            subtitle: TranslationService.translate('sound_effects_sub'),
                            icon: Icons.volume_up_outlined,
                            value: _soundEffects,
                            onChanged: (val) {
                              setState(() => _soundEffects = val);
                              _savePreference('pref_sound_fx', val);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
