import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/colors.dart';
import 'bbox_drawing_screen.dart';
import 'processing_screen.dart';

class CameraFlowScreen extends StatefulWidget {
  final String mode;
  const CameraFlowScreen({super.key, required this.mode});
  @override
  State<CameraFlowScreen> createState() => _CameraFlowScreenState();
}

class _CameraFlowScreenState extends State<CameraFlowScreen> {
  int _step = 0;
  File? _frontalImage;
  File? _sideImage;
  String? _frontalRefBbox;
  String? _frontalTgtBbox;
  String? _sideRefBbox;
  String? _sideTgtBbox;
  String? _selectedShape;
  final _picker = ImagePicker();

  final _stepNames = ['Front Photo', 'Front Boxes', 'Side Photo', 'Side Boxes', 'Select Shape'];

  Future<void> _pickImage(bool isFrontal) async {
    final source = widget.mode == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return;
    setState(() {
      if (isFrontal) _frontalImage = File(picked.path);
      else _sideImage = File(picked.path);
      _step++;
    });
  }

  void _onBboxDone(String refBbox, String tgtBbox) {
    setState(() {
      if (_step == 1) { _frontalRefBbox = refBbox; _frontalTgtBbox = tgtBbox; }
      else { _sideRefBbox = refBbox; _sideTgtBbox = tgtBbox; }
      _step++;
    });
  }

  void _goToProcessing() {
    if (_selectedShape == null) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ProcessingScreen(
      frontalImage: _frontalImage!, sideImage: _sideImage!,
      frontalRefBbox: _frontalRefBbox!, frontalTgtBbox: _frontalTgtBbox!,
      sideRefBbox: _sideRefBbox!, sideTgtBbox: _sideTgtBbox!,
      shape: _selectedShape!)));
  }

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _pickImage(true)); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.onSurface), onPressed: () => Navigator.pop(context)),
        title: Text('Step ${_step + 1} of 5 • ${_stepNames[_step.clamp(0, 4)]}',
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant)),
        centerTitle: true,
      ),
      body: SafeArea(
        bottom: true,
        child: Column(
          children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) =>
            AnimatedContainer(duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: i == _step ? 24 : 8, height: 8,
              decoration: BoxDecoration(
                color: i <= _step ? AppColors.electricCyan : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4))))),
          const SizedBox(height: 24),
          Expanded(child: _buildStep()),
        ],
      )),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0: return _capturePrompt('📸 Capture the FRONT VIEW', 'Place reference card flat beside the object', true);
      case 1: return BboxDrawingScreen(image: _frontalImage!, onDone: _onBboxDone);
      case 2: return _capturePrompt('📸 Capture the SIDE VIEW', 'Include the credit card in the same frame', false);
      case 3: return BboxDrawingScreen(image: _sideImage!, onDone: _onBboxDone);
      case 4: return _shapeSelectionStep();
      default: return const SizedBox();
    }
  }

  Widget _capturePrompt(String title, String subtitle, bool isFrontal) {
    return Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.camera_alt_outlined, size: 80, color: AppColors.electricCyan.withOpacity(0.3)),
        const SizedBox(height: 24),
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onSurface), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(subtitle, style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant), textAlign: TextAlign.center),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: () => _pickImage(isFrontal),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.electricCyan,
            foregroundColor: AppColors.onPrimary, padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))),
          child: Text(widget.mode == 'camera' ? 'OPEN CAMERA' : 'CHOOSE PHOTO',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, letterSpacing: 1)),
        ),
      ]),
    ));
  }

  Widget _shapeSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text('What shape is the object?', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.onSurface)),
          const SizedBox(height: 8),
          Text('Select the correct shape to guarantee mathematical accuracy.', style: GoogleFonts.inter(fontSize: 14, color: AppColors.onSurfaceVariant), textAlign: TextAlign.center),
          const SizedBox(height: 32),
          _shapeCard('box', 'Box / Rectangle', Icons.check_box_outline_blank, 'Books, phones, shipping boxes'),
          const SizedBox(height: 16),
          _shapeCard('cylinder', 'Cylinder', Icons.battery_full_outlined, 'Cans, bottles, cups (requires 2 side views)'),
          const SizedBox(height: 16),
          _shapeCard('sphere', 'Sphere', Icons.sports_basketball_outlined, 'Balls, globes'),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedShape != null ? _goToProcessing : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.electricCyan,
                foregroundColor: AppColors.onPrimary,
                disabledBackgroundColor: AppColors.surfaceContainerHigh,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ),
              child: Text('MEASURE NOW', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ),
          )
        ],
      ),
    );
  }

  Widget _shapeCard(String shapeId, String title, IconData icon, String subtitle) {
    final isSelected = _selectedShape == shapeId;
    return GestureDetector(
      onTap: () => setState(() => _selectedShape = shapeId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.electricCyan.withOpacity(0.15) : AppColors.surfaceContainer,
          border: Border.all(color: isSelected ? AppColors.electricCyan : Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: isSelected ? AppColors.electricCyan : AppColors.onSurfaceVariant),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: AppColors.electricCyan)
          ],
        ),
      ),
    );
  }
}
