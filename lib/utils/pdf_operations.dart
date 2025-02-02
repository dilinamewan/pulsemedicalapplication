import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PdfParse {
  String apiKey = dotenv.env['Llama_Parse_API_KEY'] ?? "";
  final Dio _dio;
  final String baseUrl = 'https://api.cloud.llamaindex.ai/api/parsing';

  PdfParse(String apiKey)
      : _dio = Dio(BaseOptions(headers: {
          'Authorization': 'Bearer $apiKey',
          'accept': 'application/json',
        }));

  Future<String> uploadFile(String filePath) async {
    var formData =
        FormData.fromMap({'file': await MultipartFile.fromFile(filePath)});
    return (await _dio.post('$baseUrl/upload', data: formData)).data['job_id'];
  }

  Future<Map<String, dynamic>> checkJobStatus(String jobId) async =>
      (await _dio.get('$baseUrl/job/$jobId')).data;

  Future<String> getMarkdownResult(String jobId) async =>
      (await _dio.get('$baseUrl/job/$jobId/result/markdown')).data.toString();
  }