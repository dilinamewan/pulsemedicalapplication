import 'dart:io';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';


class DocumentParser {

  static final DocumentParser _instance = DocumentParser._internal();
  late final Dio _dio;
  final String _apiKey = dotenv.env['Llama_Parse_API_KEY'] ?? "";
  static const String _baseUrl = 'https://api.cloud.llamaindex.ai/api/parsing';

  DocumentParser._internal() {
    _dio = Dio();
    _dio.options.headers['Authorization'] = 'Bearer $_apiKey';
  }

  factory DocumentParser() {
    return _instance;
  }

  Future<String?> parseDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      if (result == null) {
        throw Exception("No file selected");
      }

      final filePath = result.files.single.path!;

      if(await isAlreadyParsed(File(filePath))){
        return null;
      }

      final file = await MultipartFile.fromFile(
        filePath,
        filename: filePath.split('/').last,
        contentType: DioMediaType('multipart', 'form-data'),
      );

      final formData = FormData.fromMap({
        'file': file,
      });

      final uploadUrl = '$_baseUrl/upload';
      final uploadResponse = await _dio.post(uploadUrl, data: formData);
      final jobId = uploadResponse.data['id'];
      final resultUrl = '$_baseUrl/job/$jobId/result/markdown';
      Response resultResponse;

      int retries = 0;
      const maxRetries = 5;
      const delay = Duration(seconds: 30);

      while (retries < maxRetries) {
        try {
          resultResponse = await _dio.get(resultUrl);
          Directory appDocDir = await getApplicationDocumentsDirectory();
          String filePath = '${appDocDir.path}/data.md';
          File markdownFile = File(filePath);
          var markdownContent =  resultResponse.data["markdown"];
          if (await markdownFile.exists()) {
            String separator = '\n\n------------------------------------\n\n';
            await markdownFile.writeAsString('$separator$markdownContent', mode: FileMode.append);
          } else {
            await markdownFile.writeAsString(markdownContent);
          }
        } catch (e) {
          retries++;
          if (retries >= maxRetries) {
            throw Exception('Failed to retrieve result after $maxRetries retries');
          }
          await Future.delayed(delay);
        }
      }

      throw Exception('Unknown error occurred during document parsing');

    } catch (e) {
      throw Exception('Error parsing document: $e');
    }
  }

  Future<String> getMd5Hash(File file) async {
    List<int> fileBytes = await file.readAsBytes();
    return md5.convert(fileBytes).toString();
  }

  Future<bool> isAlreadyParsed(File file) async {
    final prefs = await SharedPreferences.getInstance();
    final String fileMd5 = await getMd5Hash(file);

    List<String> storedMd5s = prefs.getStringList('md5_list') ?? [];

    if (storedMd5s.contains(fileMd5)) {
      return true;
    } else {
      storedMd5s.add(fileMd5);
      await prefs.setStringList('md5_list', storedMd5s);
      return false;

  }}

  Future<void> clearData() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String filePath = '${appDocDir.path}/data.md';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('md5_list');
    File file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

}
