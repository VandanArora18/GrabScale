import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _unit = 'mm';
  String _refObject = 'Credit Card';

  @override
  void initState() { super.initState(); _loadPrefs(); }

  Future<void> _loadPrefs() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      _unit = p.getString('unit_system') ?? 'mm';
      _refObject = p.getString('ref_object') ?? 'Credit Card';
    });
  }

  Future<void> _savePref(String key, dynamic value) async {
    final p = await SharedPreferences.getInstance();
    if (value is String) p.setString(key, value);
    if (value is bool) p.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.onSurface), onPressed: () => Navigator.pop(context)),
        title: Text('Settings', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
        centerTitle: true),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        _sectionHeader('MEASUREMENT'),
        _settingTile(Icons.straighten, 'Unit System', _unit, onTap: () {
          showModalBottomSheet(context: context, backgroundColor: AppColors.surfaceContainer,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            builder: (_) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final u in ['mm', 'cm', 'inches'])
                ListTile(title: Text(u, style: TextStyle(color: AppColors.onSurface)),
                  trailing: _unit == u ? const Icon(Icons.check, color: AppColors.electricCyan) : null,
                  onTap: () { setState(() => _unit = u); _savePref('unit_system', u); Navigator.pop(context); }),
            ])));
        }),
        _settingTile(Icons.credit_card, 'Reference Object', _refObject, onTap: () {
          showModalBottomSheet(context: context, backgroundColor: AppColors.surfaceContainer,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            builder: (_) => Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
              for (final r in ['Credit Card', 'A4 Paper', 'Coin ₹1', 'Custom'])
                ListTile(title: Text(r, style: TextStyle(color: AppColors.onSurface)),
                  trailing: _refObject == r ? const Icon(Icons.check, color: AppColors.electricCyan) : null,
                  onTap: () { setState(() => _refObject = r); _savePref('ref_object', r); Navigator.pop(context); }),
            ])));
        }),
        const SizedBox(height: 24),
        _sectionHeader('ACCOUNT'),
        _settingTile(Icons.person_outline, 'Profile', AuthService().currentUser?.email ?? ''),
        _settingTile(Icons.delete_outline, 'Clear Cache', 'Free up space', onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared'))); }),
        const SizedBox(height: 24),
        _sectionHeader('ABOUT'),
        _settingTile(Icons.info_outline, 'App Version', 'v10.0'),
      ]),
    );
  }

  Widget _sectionHeader(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700,
        letterSpacing: 1.5, color: AppColors.electricCyan)));

  Widget _settingTile(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: EdgeInsets.zero, dense: true,
      leading: Icon(icon, color: AppColors.onSurfaceVariant, size: 22),
      title: Text(title, style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface)),
      subtitle: subtitle.isNotEmpty ? Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)) : null,
      trailing: onTap != null ? const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant, size: 20) : null,
      onTap: onTap);
  }

  Widget _toggleTile(IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      contentPadding: EdgeInsets.zero, dense: true,
      leading: Icon(icon, color: AppColors.onSurfaceVariant, size: 22),
      title: Text(title, style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurface)),
      trailing: Switch.adaptive(value: value, onChanged: onChanged,
        activeColor: AppColors.electricCyan, activeTrackColor: AppColors.electricCyan.withOpacity(0.3)));
  }
}
