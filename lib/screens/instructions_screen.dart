import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';

class InstructionsScreen extends StatefulWidget {
  const InstructionsScreen({super.key});
  @override
  State<InstructionsScreen> createState() => _InstructionsScreenState();
}

class _InstructionsScreenState extends State<InstructionsScreen> {
  final _controller = PageController();
  int _page = 0;

  final _pages = const [
    _InstructionPage(
      icon: Icons.credit_card, title: 'Get a Reference Card',
      description: 'Place a standard credit card (85.6 × 54 mm) flat on the same surface as the object you want to measure.',
      gradientColors: [Color(0xFF00D4FF), Color(0xFF0088AA)]),
    _InstructionPage(
      icon: Icons.camera_alt, title: 'Capture Front View',
      description: 'Take a clear photo facing the object directly. Ensure all primary edges are visible within the frame.',
      gradientColors: [Color(0xFF3CD7FF), Color(0xFF0066DD)]),
    _InstructionPage(
      icon: Icons.crop_square, title: 'Draw Bounding Boxes',
      description: 'Draw a box around the credit card first, then around the object. Be precise — tight boxes give better results.',
      gradientColors: [Color(0xFF7000FF), Color(0xFF4400AA)]),
    _InstructionPage(
      icon: Icons.flip_camera_android, title: 'Capture Side View',
      description: 'Now photograph the object from the side. Include the credit card in the same frame for scale calibration.',
      gradientColors: [Color(0xFFFEB528), Color(0xFFCC8800)]),
    _InstructionPage(
      icon: Icons.analytics, title: 'Get Your Results',
      description: 'Our AI processes both views to compute precise 3D dimensions, volume, and surface area. Download the PDF report!',
      gradientColors: [Color(0xFF00D4FF), Color(0xFF7000FF)]),
  ];

  @override
  Widget build(BuildContext context) {
    final isLast = _page == _pages.length - 1;
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      body: Stack(
        children: [
          Positioned(top: -100, left: -100, child: Container(width: 400, height: 400,
            decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [AppColors.electricCyan.withOpacity(0.08), Colors.transparent])))),
          SafeArea(
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(children: [
                  const SizedBox(width: 40),
                  const Spacer(),
                  Text('HOW TO USE', style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 2, color: AppColors.onSurfaceVariant)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(width: 40, height: 40, decoration: BoxDecoration(
                      shape: BoxShape.circle, color: AppColors.surfaceContainer.withOpacity(0.5),
                      border: Border.all(color: Colors.white.withOpacity(0.1))),
                      child: const Icon(Icons.close, color: AppColors.onSurfaceVariant, size: 20))),
                ])),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => _pages[i],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(
                  _pages.length, (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 32 : 8, height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? AppColors.electricCyan : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: i == _page ? [BoxShadow(color: AppColors.electricCyan.withOpacity(0.5), blurRadius: 8)] : null))))),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: SizedBox(width: double.infinity, height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isLast) Navigator.pop(context);
                      else _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.electricCyan, foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                      elevation: 0,
                      shadowColor: AppColors.electricCyan.withOpacity(0.3)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text(isLast ? 'GET STARTED' : 'NEXT', style: GoogleFonts.inter(
                          fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                      const SizedBox(width: 8),
                      Icon(isLast ? Icons.check : Icons.arrow_forward, size: 18),
                    ]),
                  )),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _InstructionPage extends StatelessWidget {
  final IconData icon;
  final String title, description;
  final List<Color> gradientColors;
  const _InstructionPage({required this.icon, required this.title, required this.description, required this.gradientColors});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 32, offset: const Offset(0, 8)),
              BoxShadow(color: gradientColors[0].withOpacity(0.05), blurRadius: 20),
            ]),
          child: Column(children: [
            
            AspectRatio(aspectRatio: 4/3,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05)))),
                child: Stack(children: [
                  
                  Center(child: Container(width: 200, height: 200,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      gradient: RadialGradient(colors: [gradientColors[0].withOpacity(0.15), Colors.transparent])))),
                  
                  Center(child: ShaderMask(
                    shaderCallback: (r) => LinearGradient(colors: gradientColors).createShader(r),
                    child: Icon(icon, size: 80, color: Colors.white))),
                  Positioned(left: 24, top: 24, child: _cornerMark()),
                  Positioned(right: 24, top: 24, child: Transform.flip(flipX: true, child: _cornerMark())),
                  Positioned(left: 24, bottom: 24, child: Transform.flip(flipY: true, child: _cornerMark())),
                  Positioned(right: 24, bottom: 24, child: Transform.flip(flipX: true, flipY: true, child: _cornerMark())),
                ]),
              )),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(children: [
                Text(title, style: GoogleFonts.plusJakartaSans(
                    fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.onSurface), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(description, style: GoogleFonts.inter(
                    fontSize: 15, color: AppColors.onSurfaceVariant, height: 1.5), textAlign: TextAlign.center),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
  Widget _cornerMark() => Container(width: 16, height: 16,
    decoration: BoxDecoration(
      border: Border(
        left: BorderSide(color: AppColors.electricCyan.withOpacity(0.3), width: 2),
        top: BorderSide(color: AppColors.electricCyan.withOpacity(0.3), width: 2))));
}
