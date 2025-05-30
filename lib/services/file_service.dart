import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:quokka_box/config/api_config.dart';

class FileService {
  static Future<String> uploadFileUniversal(PlatformFile file) async {
    try {
      if (kIsWeb && file.bytes == null) {
        throw Exception('File bytes are required for web uploads');
      }

      final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/${ApiConfig.cloudinaryCloudName}/image/upload');

      print('=== Upload Details ===');
      print('File name: ${file.name}');
      print('File size: ${kIsWeb ? file.bytes!.length : file.size} bytes');
      print('File extension: ${file.extension}');
      print('Upload URL: $uri');
      print('Cloud name: ${ApiConfig.cloudinaryCloudName}');
      print('Upload preset: test');
      print('===================');

      var request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = 'tested'
        ..files.add(
          kIsWeb
              ? http.MultipartFile.fromBytes(
                  'file',
                  file.bytes!,
                  filename: file.name,
                )
              : await http.MultipartFile.fromPath(
                  'file',
                  file.path!,
                ),
        );

      print('Sending request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('=== Response Details ===');
      print('Status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');
      print('=====================');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('Upload successful!');
        print('Secure URL: ${json['secure_url']}');
        return json['secure_url'];
      } else {
        print('Upload failed!');
        print('Error response: ${response.body}');
        throw Exception('Upload failed: ${response.body}');
      }
    } catch (e) {
      print('Upload error: $e');
      rethrow;
    }
  }

  static Future<List<String>> uploadMultipleFilesUniversal(
      List<PlatformFile> files) async {
    final List<String> urls = [];
    for (final file in files) {
      try {
        final url = await uploadFileUniversal(file);
        urls.add(url);
      } catch (e) {
        print('Error uploading file ${file.name}: $e');
        rethrow;
      }
    }
    return urls;
  }

  static String _getMimeType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'txt':
        return 'text/plain';
      default:
        return 'application/octet-stream';
    }
  }
}
