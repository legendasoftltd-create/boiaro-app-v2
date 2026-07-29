import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/backend/api_requests/api_calls.dart';

class ShareHelper {
  static Future<bool> shareBadgeCard(String userBadgeId) async {
    try {
      final token = FFAppState().token;
      final baseUrl = EbookGroup.getBaseUrl();
      final url = Uri.parse('${baseUrl}share/badge/$userBadgeId.png');

      final response = await http.get(url, headers: {
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/badge_$userBadgeId.png');
        await file.writeAsBytes(response.bodyBytes);

        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'আমি Boiaro App এ একটি নতুন ব্যাজ অর্জন করেছি! 🎉',
        );
        return true;
      }
    } catch (e) {
      debugPrint('Error sharing badge card: $e');
    }
    return false;
  }

  static Future<bool> shareWeeklyReportCard() async {
    try {
      final token = FFAppState().token;
      final baseUrl = EbookGroup.getBaseUrl();
      final url = Uri.parse('${baseUrl}share/weekly-report.png');

      final response = await http.get(url, headers: {
        if (token.isNotEmpty) 'Authorization': 'Bearer $token',
      });

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/weekly_report.png');
        await file.writeAsBytes(response.bodyBytes);

        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'আমার Boiaro এই সপ্তাহের পাঠ রিপোর্ট! 📚✨',
        );
        return true;
      }
    } catch (e) {
      debugPrint('Error sharing weekly report card: $e');
    }
    return false;
  }
}
