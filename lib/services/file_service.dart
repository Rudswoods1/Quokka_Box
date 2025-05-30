import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:file_picker/file_picker.dart';
import 'package:quokka_box/config/api_config.dart';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';

class FileService {
  static Future<String> uploadFileUniversal(
      PlatformFile file, BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Загрузка файла'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Пожалуйста, подождите...'),
              ],
            ),
          );
        },
      );

      if (kIsWeb && file.bytes == null) {
        Navigator.pop(context);
        throw Exception('File bytes are required for web uploads');
      }

      final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/${ApiConfig.cloudinaryCloudName}/auto/upload');

      print('=== Upload Details ===');
      print('File name: ${file.name}');
      print('File size: ${kIsWeb ? file.bytes!.length : file.size} bytes');
      print('File extension: ${file.extension}');
      print('Upload URL: $uri');
      print('Cloud name: ${ApiConfig.cloudinaryCloudName}');
      print('Upload preset: tested');
      print('===================');

      var request = http.MultipartRequest('POST', uri);

      request.fields.addAll({
        'upload_preset': 'tested',
        'resource_type': 'auto',
        'api_key': '174196584956159',
      });

      request.files.add(
        kIsWeb
            ? http.MultipartFile.fromBytes(
                'file',
                file.bytes!,
                filename: file.name,
                contentType: MediaType.parse(_getMimeType(file.name)),
              )
            : await http.MultipartFile.fromPath(
                'file',
                file.path!,
                contentType: MediaType.parse(_getMimeType(file.name)),
              ),
      );

      print('Sending request...');
      print('Request fields: ${request.fields}');
      print(
          'Request files: ${request.files.map((f) => f.filename).join(', ')}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('=== Response Details ===');
      print('Status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');
      print('=====================');

      Navigator.pop(context);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('Upload successful!');
        print('Secure URL: ${json['secure_url']}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Файл успешно загружен!'),
            backgroundColor: Colors.green,
          ),
        );

        return json['secure_url'];
      } else {
        print('Upload failed!');
        print('Error response: ${response.body}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );

        throw Exception('Upload failed: ${response.body}');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      print('Upload error: $e');
      rethrow;
    }
  }

  static Future<List<String>> uploadMultipleFilesUniversal(
      List<PlatformFile> files, BuildContext context) async {
    final List<String> urls = [];
    for (final file in files) {
      try {
        final url = await uploadFileUniversal(file, context);
        urls.add(url);
      } catch (e) {
        print('Error uploading file ${file.name}: $e');
        rethrow;
      }
    }
    return urls;
  }

  static Future<String> uploadFileFromUrl(
      String fileUrl, BuildContext context) async {
    try {
      // Показываем диалог загрузки
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Загрузка файла'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Пожалуйста, подождите...'),
              ],
            ),
          );
        },
      );

      print('=== Upload Details ===');
      print('File URL: $fileUrl');
      print('Cloud name: ${ApiConfig.cloudinaryCloudName}');
      print('Upload preset: tested');
      print('===================');

      final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/${ApiConfig.cloudinaryCloudName}/auto/upload');

      var request = http.MultipartRequest('POST', uri);

      request.fields.addAll({
        'upload_preset': 'tested',
        'resource_type': 'auto',
        'api_key': '174196584956159',
        'file': fileUrl,
      });

      print('Sending request...');
      print('Request fields: ${request.fields}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('=== Response Details ===');
      print('Status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');
      print('=====================');

      // Закрываем диалог загрузки
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('Upload successful!');
        print('Secure URL: ${json['secure_url']}');

        // Показываем успешное сообщение
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Файл успешно загружен!'),
            backgroundColor: Colors.green,
          ),
        );

        return json['secure_url'];
      } else {
        print('Upload failed!');
        print('Error response: ${response.body}');

        // Показываем сообщение об ошибке
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка загрузки: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );

        throw Exception('Upload failed: ${response.body}');
      }
    } catch (e) {
      // Закрываем диалог загрузки в случае ошибки
      if (context.mounted) {
        Navigator.pop(context);

        // Показываем сообщение об ошибке
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      print('Upload error: $e');
      rethrow;
    }
  }

  static Future<List<String>> uploadMultipleFilesFromUrls(
      List<String> fileUrls, BuildContext context) async {
    final List<String> urls = [];
    for (final fileUrl in fileUrls) {
      try {
        final url = await uploadFileFromUrl(fileUrl, context);
        urls.add(url);
      } catch (e) {
        print('Error uploading file from URL $fileUrl: $e');
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

  static Future<Map<String, dynamic>> getFileDetails(
      String publicId, BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Получение информации о файле'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Пожалуйста, подождите...'),
              ],
            ),
          );
        },
      );

      final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/${ApiConfig.cloudinaryCloudName}/image/resource/$publicId');

      print('=== GET Request Details ===');
      print('Public ID: $publicId');
      print('Cloud name: ${ApiConfig.cloudinaryCloudName}');
      print('===================');

      final response = await http.get(
        uri,
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('174196584956159:xUJqaRlxBUIM_NsSlOmxo0rVo4E'))}',
        },
      );

      print('=== Response Details ===');
      print('Status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');
      print('=====================');

      Navigator.pop(context);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        print('File details retrieved successfully!');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Информация о файле получена!'),
            backgroundColor: Colors.green,
          ),
        );

        return json;
      } else {
        print('Failed to get file details!');
        print('Error response: ${response.body}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка получения информации: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );

        throw Exception('Failed to get file details: ${response.body}');
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      print('Error getting file details: $e');
      rethrow;
    }
  }

  static Future<List<Map<String, dynamic>>> listFiles(
      BuildContext context) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final signature = _generateSignature(timestamp);

      final uri = Uri.parse(
              'https://api.cloudinary.com/v1_1/${ApiConfig.cloudinaryCloudName}/resources/image')
          .replace(queryParameters: {
        'timestamp': timestamp.toString(),
        'api_key': ApiConfig.cloudinaryApiKey,
        'signature': signature,
        'max_results': '500',
        'type': 'upload',
      });

      print('=== List Files Request ===');
      print('URI: $uri');
      print('Timestamp: $timestamp');
      print('Signature: $signature');
      print('Cloud Name: ${ApiConfig.cloudinaryCloudName}');
      print('API Key: ${ApiConfig.cloudinaryApiKey}');
      print('========================');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('=== List Files Response ===');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('========================');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final resources = json['resources'] as List;
        return resources
            .map((resource) => resource as Map<String, dynamic>)
            .toList();
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to list files: ${response.body}');
      }
    } catch (e) {
      print('Error listing files: $e');
      if (e is http.ClientException) {
        print('Network error: ${e.message}');
        print('URI: ${e.uri}');
      }
      rethrow;
    }
  }

  static String _generateSignature(int timestamp) {
    final params = {
      'timestamp': timestamp.toString(),
      'max_results': '500',
      'type': 'upload',
    };

    final sortedParams = params.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final signatureBase =
        sortedParams.map((e) => '${e.key}=${e.value}').join('&');

    print('Signature base: $signatureBase');
    print('API Secret: ${ApiConfig.cloudinaryApiSecret}');

    final signature = _sha1('$signatureBase${ApiConfig.cloudinaryApiSecret}');
    print('Generated signature: $signature');
    return signature;
  }

  static String _sha1(String input) {
    final bytes = utf8.encode(input);
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

  static Future<bool> deleteFile(String publicId, BuildContext context) async {
    try {
      final uri = Uri.parse(
          'https://api.cloudinary.com/v1_1/${ApiConfig.cloudinaryCloudName}/image/destroy');

      final response = await http.post(
        uri,
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('${ApiConfig.cloudinaryApiKey}:${ApiConfig.cloudinaryApiSecret}'))}',
        },
        body: {
          'public_id': publicId,
        },
      );

      print('=== Delete File Response ===');
      print('Status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('==========================');

      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete file: ${response.body}');
      }
    } catch (e) {
      print('Error deleting file: $e');
      rethrow;
    }
  }
}
