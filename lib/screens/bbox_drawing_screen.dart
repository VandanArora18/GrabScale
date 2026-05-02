import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../widgets/bbox_painter.dart';

class BboxDrawingScreen extends StatefulWidget {
  final File image;
  final void Function(String refBbox, String tgtBbox) onDone;
  const BboxDrawingScreen({super.key, required this.image, required this.onDone});
  @override
  State<BboxDrawingScreen> createState() => _BboxDrawingScreenState();
}

class _BboxDrawingScreenState extends State<BboxDrawingScreen> {
  Rect? _refRect;
  Rect? _tgtRect;
  Rect? _currentDrawing;
  Offset? _startPos;
  bool _drawingRef = true;
  bool _refConfirmed = false;
  ui.Image? _loadedImage;
  final _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    final bytes = await widget.image.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    setState(() => _loadedImage = frame.image);
  }

  String _rectToString(Rect r, Size displaySize) {
    if (_loadedImage == null) return '0,0,0,0';
    
    final double originalWidth = _loadedImage!.width.toDouble();
    final double originalHeight = _loadedImage!.height.toDouble();
    
    // Get the size of the rendered image using BoxFit.contain
    FittedSizes fittedSizes = applyBoxFit(
        BoxFit.contain,
        Size(originalWidth, originalHeight),
        displaySize,
    );
    double actualDisplayW = fittedSizes.destination.width;
    double actualDisplayH = fittedSizes.destination.height;
    double offsetX = (displaySize.width - actualDisplayW) / 2;
    double offsetY = (displaySize.height - actualDisplayH) / 2;
    int x1 = ((r.left - offsetX) * (originalWidth / actualDisplayW)).round();
    int y1 = ((r.top - offsetY) * (originalHeight / actualDisplayH)).round();
    int x2 = ((r.right - offsetX) * (originalWidth / actualDisplayW)).round();
    int y2 = ((r.bottom - offsetY) * (originalHeight / actualDisplayH)).round();

    x1 = x1.clamp(0, originalWidth.toInt() - 1);
    y1 = y1.clamp(0, originalHeight.toInt() - 1);
    x2 = x2.clamp(0, originalWidth.toInt() - 1);
    y2 = y2.clamp(0, originalHeight.toInt() - 1);
    
    return '$x1,$y1,$x2,$y2';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: (_drawingRef ? AppColors.electricCyan : const Color(0xFFFF6B35)).withOpacity(0.15),
            borderRadius: BorderRadius.circular(12)),
          child: Text(
            _refConfirmed ? '🎯 Now draw box around the OBJECT' : '💳 Draw box around the CREDIT CARD first',
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600,
                color: _drawingRef ? AppColors.electricCyan : const Color(0xFFFF6B35)),
            textAlign: TextAlign.center),
        ),
  
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: LayoutBuilder(builder: (context, constraints) {
              return GestureDetector(
                onPanStart: (d) => setState(() { _startPos = d.localPosition; _currentDrawing = null; }),
                onPanUpdate: (d) {
                  if (_startPos == null) return;
                  setState(() => _currentDrawing = Rect.fromPoints(_startPos!, d.localPosition));
                },
                onPanEnd: (d) {
                  if (_currentDrawing == null) return;
                  setState(() {
                    if (_drawingRef) _refRect = _currentDrawing;
                    else _tgtRect = _currentDrawing;
                    _currentDrawing = null;
                    _startPos = null;
                  });
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(widget.image, key: _imageKey, fit: BoxFit.contain)),
                    CustomPaint(
                      painter: BboxPainter(
                        refRect: _refRect,
                        tgtRect: _tgtRect,
                        currentDrawing: _currentDrawing,
                        isDrawingRef: _drawingRef)),
                  ],
                ),
              );
            }),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => setState(() {
                if (_refConfirmed) { _tgtRect = null; }
                else { _refRect = null; }
              }),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.onSurface,
                side: BorderSide(color: AppColors.glassBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                padding: const EdgeInsets.symmetric(vertical: 14)),
              child: Text('REDRAW', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
            )),
            const SizedBox(width: 12),
            Expanded(flex: 2, child: ElevatedButton(
              onPressed: _canConfirm() ? _onConfirm : null,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.electricCyan,
                foregroundColor: AppColors.onPrimary, disabledBackgroundColor: AppColors.surfaceContainerHigh,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                padding: const EdgeInsets.symmetric(vertical: 14)),
              child: Text(_refConfirmed ? 'CONFIRM & CONTINUE' : 'CONFIRM CARD BOX',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
            )),
          ]),
        ),
      ],
    );
  }

  bool _canConfirm() {
    if (!_refConfirmed) return _refRect != null;
    return _tgtRect != null;
  }

  void _onConfirm() {
    if (!_refConfirmed) {
      setState(() { _refConfirmed = true; _drawingRef = false; });
    } else {
      final renderBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
      final displaySize = renderBox?.size ?? const Size(400, 600);
      widget.onDone(
        _rectToString(_refRect!, displaySize),
        _rectToString(_tgtRect!, displaySize),
      );
    }
  }
}
