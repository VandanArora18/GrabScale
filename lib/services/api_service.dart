import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class ApiService {
  Future<Map<String, dynamic>> measure({
    required File frontalImage,
    required File sideImage,
    required String frontalRefBbox,
    required String frontalTgtBbox,
    required String sideRefBbox,
    required String sideTgtBbox,
    required String shape,
  }) async {
    var request = http.MultipartRequest('POST', Uri.parse(ApiConstants.measureEndpoint));

    request.files.add(await http.MultipartFile.fromPath('frontal_image', frontalImage.path));
    request.files.add(await http.MultipartFile.fromPath('side_image', sideImage.path));

    request.fields['frontal_ref_bbox'] = frontalRefBbox;
    request.fields['frontal_tgt_bbox'] = frontalTgtBbox;
    request.fields['side_ref_bbox'] = sideRefBbox;
    request.fields['side_tgt_bbox'] = sideTgtBbox;
    request.fields['shape'] = shape;

    final streamedResponse = await request.send().timeout(ApiConstants.timeout);
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception('API error: ${response.statusCode} - ${response.body}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<bool> healthCheck() async {
    try {
      final response = await http.get(Uri.parse(ApiConstants.healthEndpoint))
          .timeout(const Duration(seconds: 10));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
