import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/measurement.dart';
import '../widgets/action_card.dart';
import '../widgets/measurement_card.dart';
import 'camera_flow_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'instructions_screen.dart';
import 'results_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  final _auth = AuthService();
  final _firestore = FirestoreService();

  String get _userName => _auth.currentUser?.displayName ?? 'User';
  String get _uid => _auth.currentUser?.uid ?? '';

  void _onNav(int i) {
    if (i == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
    else if (i == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
    else setState(() => _navIndex = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      drawer: _buildDrawer(),
      body: Stack(
        children: [
          Positioned(top: -120, right: -80, child: Container(width: 300, height: 300,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [AppColors.electricCyan.withOpacity(0.06), Colors.transparent])))),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(children: [
                    Builder(builder: (ctx) => GestureDetector(
                      onTap: () => Scaffold.of(ctx).openDrawer(),
                      child: Container(width: 40, height: 40, decoration: BoxDecoration(
                        color: AppColors.glassBackground, borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder)),
                        child: const Icon(Icons.menu, color: AppColors.onSurfaceVariant, size: 20)))),
                    const Spacer(),
                    Text('ScaleGrab', style: GoogleFonts.plusJakartaSans(
                        fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.electricCyan)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
                      child: Container(width: 40, height: 40, decoration: BoxDecoration(
                        color: AppColors.glassBackground, borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.glassBorder)),
                        child: const Icon(Icons.settings_outlined, color: AppColors.onSurfaceVariant, size: 20))),
                  ]),
                  const SizedBox(height: 28),
                  Text('Hello, $_userName 👋', style: GoogleFonts.plusJakartaSans(
                      fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
                  const SizedBox(height: 4),
                  Text('What will you measure today?', style: GoogleFonts.inter(
                      fontSize: 14, color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 28),
                  
                  Row(children: [
                    Expanded(child: ActionCard(icon: Icons.camera_alt_outlined, title: 'Open\nCamera',
                      subtitle: 'Take photos', onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CameraFlowScreen(mode: 'camera'))))),
                    const SizedBox(width: 16),
                    Expanded(child: ActionCard(icon: Icons.photo_library_outlined, title: 'Upload\nPhotos',
                      subtitle: 'From gallery', onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const CameraFlowScreen(mode: 'upload'))))),
                  ]),
                  const SizedBox(height: 28),
                 
                  Row(children: [
                    Text('Recent Measurements', style: GoogleFonts.plusJakartaSans(
                        fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                    const Spacer(),
                    GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                      child: Text('VIEW ALL', style: GoogleFonts.inter(
                          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.electricCyan, letterSpacing: 1))),
                  ]),
                  const SizedBox(height: 16),
                  
                  Expanded(
                    child: _uid.isEmpty
                      ? const Center(child: Text('Sign in to see measurements', style: TextStyle(color: AppColors.onSurfaceVariant)))
                      : StreamBuilder<List<Measurement>>(
                        stream: _firestore.getMeasurements(_uid, limit: 5),
                        builder: (context, snap) {
                          if (snap.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: AppColors.electricCyan));
                          }
                          final items = snap.data ?? [];
                          if (items.isEmpty) {
                            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              Icon(Icons.straighten, size: 48, color: AppColors.onSurfaceVariant.withOpacity(0.3)),
                              const SizedBox(height: 12),
                              Text('No measurements yet', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)),
                              const SizedBox(height: 4),
                              Text('Start by taking photos!', style: GoogleFonts.inter(fontSize: 13, color: AppColors.outline)),
                            ]));
                          }
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: items.length,
                            itemBuilder: (_, i) => MeasurementCard(measurement: items[i],
                              onTap: () => Navigator.push(context, MaterialPageRoute(
                                builder: (_) => ResultsScreen(measurement: items[i])))),
                          );
                        },
                      ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(color: AppColors.surfaceContainerLow,
          border: Border(top: BorderSide(color: AppColors.glassBorder))),
        child: BottomNavigationBar(
          currentIndex: _navIndex, onTap: _onNav,
          backgroundColor: Colors.transparent, elevation: 0,
          selectedItemColor: AppColors.electricCyan, unselectedItemColor: AppColors.onSurfaceVariant,
          selectedLabelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: AppColors.surfaceContainerLow,
      child: SafeArea(
        child: Column(children: [
          const SizedBox(height: 24),
          CircleAvatar(radius: 32, backgroundColor: AppColors.surfaceContainerHigh,
            child: Text(_userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                style: GoogleFonts.plusJakartaSans(fontSize: 24, color: AppColors.electricCyan))),
          const SizedBox(height: 12),
          Text(_userName, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
          Text(_auth.currentUser?.email ?? '', style: GoogleFonts.inter(fontSize: 13, color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 24),
          const Divider(color: AppColors.outlineVariant),
          _drawerItem(Icons.home_outlined, 'Home', () => Navigator.pop(context)),
          _drawerItem(Icons.history, 'Recent Measurements', () { Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())); }),
          _drawerItem(Icons.help_outline, 'How to Use', () { Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const InstructionsScreen())); }),
          const Spacer(),
          const Divider(color: AppColors.outlineVariant),
          _drawerItem(Icons.logout, 'Logout', () async {
            Navigator.pop(context);
            await _auth.signOut();
            if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
          }, color: AppColors.error),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _drawerItem(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? AppColors.onSurfaceVariant, size: 22),
      title: Text(label, style: GoogleFonts.inter(fontSize: 14, color: color ?? AppColors.onSurface)),
      onTap: onTap, dense: true,
    );
  }
}
