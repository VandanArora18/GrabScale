import 'package:cloud_firestore/cloud_firestore.dart';

class Measurement {
  final String? id;
  final DateTime createdAt;
  final String objectName;
  final double lengthMm;
  final double heightMm;
  final double widthMm;
  final double volumeCm3;
  final double surfaceCm2;
  final double fillPct;
  final String? shape;
  final String? frontalImageUrl;
  final String? sideImageUrl;
  final String? resultImageUrl;
  final String? pdfUrl;

  Measurement({
    this.id,
    required this.createdAt,
    required this.objectName,
    required this.lengthMm,
    required this.heightMm,
    required this.widthMm,
    required this.volumeCm3,
    required this.surfaceCm2,
    required this.fillPct,
    this.shape,
    this.frontalImageUrl,
    this.sideImageUrl,
    this.resultImageUrl,
    this.pdfUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'createdAt': Timestamp.fromDate(createdAt),
      'objectName': objectName,
      'length_mm': lengthMm,
      'height_mm': heightMm,
      'width_mm': widthMm,
      'volume_cm3': volumeCm3,
      'surface_cm2': surfaceCm2,
      'fill_pct': fillPct,
      'shape': shape,
      'frontalImageUrl': frontalImageUrl,
      'sideImageUrl': sideImageUrl,
      'resultImageUrl': resultImageUrl,
      'pdfUrl': pdfUrl,
    };
  }

  factory Measurement.fromMap(Map<String, dynamic> map, String docId) {
    return Measurement(
      id: docId,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      objectName: map['objectName'] ?? 'Unknown',
      lengthMm: (map['length_mm'] ?? 0).toDouble(),
      heightMm: (map['height_mm'] ?? 0).toDouble(),
      widthMm: (map['width_mm'] ?? 0).toDouble(),
      volumeCm3: (map['volume_cm3'] ?? 0).toDouble(),
      surfaceCm2: (map['surface_cm2'] ?? 0).toDouble(),
      fillPct: (map['fill_pct'] ?? 0).toDouble(),
      shape: map['shape'],
      frontalImageUrl: map['frontalImageUrl'],
      sideImageUrl: map['sideImageUrl'],
      resultImageUrl: map['resultImageUrl'],
      pdfUrl: map['pdfUrl'],
    );
  }
}
