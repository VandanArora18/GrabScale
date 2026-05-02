import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/colors.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/measurement.dart';
import 'results_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _search = '';
  String _filter = 'All';
  final _uid = AuthService().currentUser?.uid ?? '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.deepNavy,
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.onSurface), onPressed: () => Navigator.pop(context)),
        title: Text('History', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
        centerTitle: true),
      body: Column(children: [
       
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            style: const TextStyle(color: AppColors.onSurface),
            decoration: InputDecoration(
              hintText: 'Search measurements...',
              hintStyle: TextStyle(color: AppColors.onSurfaceVariant.withOpacity(0.6)),
              prefixIcon: const Icon(Icons.search, color: AppColors.onSurfaceVariant, size: 20),
              filled: true, fillColor: AppColors.surfaceContainerLow,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(vertical: 14)))),
    
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: ['All', 'Week', 'Month'].map((f) =>
            Padding(padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(f, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                selected: _filter == f,
                onSelected: (_) => setState(() => _filter = f),
                selectedColor: AppColors.electricCyan,
                backgroundColor: AppColors.surfaceContainerHigh,
                labelStyle: TextStyle(color: _filter == f ? AppColors.onPrimary : AppColors.onSurfaceVariant),
                side: BorderSide.none, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
              ))).toList())),
        const SizedBox(height: 8),
        
        Expanded(
          child: StreamBuilder<List<Measurement>>(
            stream: FirestoreService().getMeasurements(_uid),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator(color: AppColors.electricCyan));
              var items = snap.data ?? [];
              
              final now = DateTime.now();
              if (_filter == 'Week') items = items.where((m) => now.difference(m.createdAt).inDays <= 7).toList();
              if (_filter == 'Month') items = items.where((m) => now.difference(m.createdAt).inDays <= 30).toList();
              
              if (_search.isNotEmpty) items = items.where((m) => m.objectName.toLowerCase().contains(_search.toLowerCase())).toList();

              if (items.isEmpty) return Center(child: Text('No measurements found', style: GoogleFonts.inter(color: AppColors.onSurfaceVariant)));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final m = items[i];
                  return Dismissible(
                    key: Key(m.id ?? '$i'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: AppColors.errorContainer.withOpacity(0.3), borderRadius: BorderRadius.circular(20)),
                      child: const Icon(Icons.delete, color: AppColors.error)),
                    onDismissed: (_) {
                      if (m.id != null) FirestoreService().deleteMeasurement(_uid, m.id!);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${m.objectName} deleted')));
                    },
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ResultsScreen(measurement: m))),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.glassBackground, borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.glassBorder)),
                        child: Row(children: [
                          Container(width: 44, height: 44, decoration: BoxDecoration(
                            color: AppColors.electricCyan.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.straighten, color: AppColors.electricCyan, size: 20)),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(m.objectName, style: GoogleFonts.plusJakartaSans(
                                fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.onSurface)),
                            const SizedBox(height: 2),
                            Text('${m.lengthMm.toStringAsFixed(0)}×${m.heightMm.toStringAsFixed(0)}×${m.widthMm.toStringAsFixed(0)} mm',
                                style: GoogleFonts.inter(fontSize: 12, color: AppColors.onSurfaceVariant)),
                          ])),
                          Text('${m.volumeCm3.toStringAsFixed(1)}cm³', style: GoogleFonts.plusJakartaSans(
                              fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.electricCyan)),
                        ]),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
    );
  }
}
