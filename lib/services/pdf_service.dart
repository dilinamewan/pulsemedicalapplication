import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class _ParsingJob {
  final String filePath;
  final String fileName;
  final String apiKey;
  final String baseUrl;

  _ParsingJob({
    required this.filePath,
    required this.fileName,
    required this.apiKey,
    required this.baseUrl,
  });

  // Static method that will run in a separate isolate
  static Future<Map<String, dynamic>> parse(_ParsingJob job) async {
    try {
      final dio = Dio();
      dio.options.headers['Authorization'] = 'Bearer ${job.apiKey}';

      // Create multipart request
      final file = await MultipartFile.fromFile(
        job.filePath,
        filename: job.fileName,
        contentType: DioMediaType('multipart', 'form-data'),
      );

      final formData = FormData.fromMap({
        'file': file,
      });

      // Upload file to parsing service
      final uploadUrl = '${job.baseUrl}/upload';
      final uploadResponse = await dio.post(uploadUrl, data: formData);

      if (uploadResponse.statusCode != 200) {
        return {
          'success': false,
          'error': 'File upload failed with status: ${uploadResponse.statusCode}'
        };
      }

      final jobId = uploadResponse.data['id'];
      final resultUrl = '${job.baseUrl}/job/$jobId/result/markdown';

      // Poll for results
      int retries = 0;
      const maxRetries = 10;
      const delay = Duration(seconds: 10);

      while (retries < maxRetries) {
        try {
          final resultResponse = await dio.get(resultUrl);

          if (resultResponse.statusCode == 200 && resultResponse.data.containsKey('markdown')) {
            var markdownContent = resultResponse.data["markdown"];

            // Return the parsed content
            return {
              'success': true,
              'markdown': markdownContent,
              'fileName': job.fileName
            };
          }

          // If we get here, the job is still processing
          retries++;
          await Future.delayed(delay);

        } catch (e) {
          if (e is DioException && e.response?.statusCode == 404) {
            // Job still processing, wait and retry
            retries++;
            if (retries >= maxRetries) {
              return {
                'success': false,
                'error': 'Document parsing timed out after $maxRetries attempts'
              };
            }
            await Future.delayed(delay);
          } else {
            // Some other error occurred
            return {
              'success': false,
              'error': 'Error retrieving parsing results: ${e.toString()}'
            };
          }
        }
      }

      return {
        'success': false,
        'error': 'Document parsing timed out after $maxRetries attempts'
      };

    } catch (e) {
      return {
        'success': false,
        'error': 'Error parsing document: ${e.toString()}'
      };
    }
  }
}

class DocumentParser {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // Get current user ID
  String get _userId => _auth.currentUser?.uid ?? '';

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

  /// Compresses a string using GZip encoding
  Uint8List compressString(String input) {
    final bytes = utf8.encode(input);
    final compressed = GZipEncoder().encode(bytes);
    return Uint8List.fromList(compressed!);
  }

  /// Decompresses a byte array back to a string
  String decompressString(Uint8List compressedData) {
    final decompressed = GZipDecoder().decodeBytes(compressedData);
    return utf8.decode(decompressed);
  }

  Future<void> deletepdf(String customid) async {
    try {
      final userDocRef = _firestore.collection('users').doc(_userId);
      final docsSnapshot = await userDocRef.collection('documents').get();
      for (var doc in docsSnapshot.docs) {
        if (doc.id.endsWith('_$customid')) {
          await doc.reference.delete();
          debugPrint('Deleted document: ${doc.id}');
        }
      }
    } catch (e) {
      debugPrint('Error deleting schedule and related documents: $e');
    }
  }

  /// Parses a document file in the background and stores the result in Firestore
  /// Returns the document ID and markdown content on success
  Future<Map<String, dynamic>> parseDocument(String result,String customid, BuildContext context) async {
    try {
      final filePath = result;
      final fileName = filePath.split('/').last;

      // Prepare the job for background processing
      final job = _ParsingJob(
        filePath: filePath,
        fileName: fileName,
        apiKey: _apiKey,
        baseUrl: _baseUrl,
      );

      // Process in background isolate
      final parsingResult = await compute(_ParsingJob.parse, job);

      // If parsing was successful, store the result in Firestore
      if (parsingResult['success']) {
        String markdownContent = parsingResult['markdown'];
        Uint8List compressedMarkdown = compressString(markdownContent);

        // Get the filename without extension
        String docName = fileName.split('.').first;

        // This code will change in future
        String docId = '${docName}_${customid}';

        // Store in Firestore
        await _firestore.collection('users')
            .doc(_userId)
            .collection('documents')
            .doc(docId)
            .set({
          'compressedContent': compressedMarkdown,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Document "$fileName" parsed successfully')),
        );

        // Return success result
        return {
          'success': true,
          'documentId': docId,
          'markdown': markdownContent,
          'fileName': fileName
        };
      } else {
        // Return the error from the background process
        return parsingResult;
      }

    } catch (e) {
      return {
        'success': false,
        'error': 'Error in document processing: ${e.toString()}'
      };
    }
  }

  /// Retrieves a parsed document from Firestore by ID
  Future<String?> getDocument(String documentId) async {
    try {
      final docSnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('documents')
          .doc(documentId)
          .get();

      if (docSnapshot.exists && docSnapshot.data()!.containsKey('compressedContent')) {
        Uint8List compressedContent = docSnapshot.data()!['compressedContent'];
        return decompressString(compressedContent);
      }

      return null;
    } catch (e) {
      throw Exception('Error retrieving document: ${e.toString()}');
    }
  }

  /// Retrieves all documents for the current user
  Future<List<Map<String, dynamic>>> getAllDocuments() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('documents')
          .get();

      List<Map<String, dynamic>> results = [];

      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          if (data.containsKey('compressedContent') && data['compressedContent'] != null) {
            // Convert to Uint8List regardless of input type
            Uint8List compressedContent;

            if (data['compressedContent'] is Uint8List) {
              compressedContent = data['compressedContent'];
            } else if (data['compressedContent'] is List) {
              // Convert List<dynamic> to Uint8List
              final listData = data['compressedContent'] as List;
              if (listData.isEmpty) {
                // Handle empty list case
                results.add({
                  'id': doc.id,
                  'markdown': 'Error: Document content is empty',
                  'fileName': doc.id.split('_').first,
                });
                continue;
              }
              compressedContent = Uint8List.fromList(
                  listData.map((item) => item as int).toList()
              );
            } else {
              // Skip this document if content is in an unexpected format
              results.add({
                'id': doc.id,
                'markdown': 'Error: Document content is in an invalid format',
                'fileName': doc.id.split('_').first,
              });
              continue;
            }

            // Safely decompress the markdown
            String markdown;
            try {
              markdown = decompressString(compressedContent);
            } catch (e) {
              print('Error decompressing document ${doc.id}: ${e.toString()}');
              results.add({
                'id': doc.id,
                'markdown': 'Error: Document content could not be decompressed',
                'fileName': doc.id.split('_').first,
              });
              continue;
            }

            results.add({
              'id': doc.id,
              'markdown': markdown,
              'fileName': doc.id.split('_').first,
            });
          } else {
            results.add({
              'id': doc.id,
              'markdown': 'Error: No content available',
              'fileName': doc.id.split('_').first,
            });
          }
        } catch (e) {
          print('Error processing document ${doc.id}: ${e.toString()}');
          // Add the document with error indication
          results.add({
            'id': doc.id,
            'markdown': 'Error: Failed to process document',
            'fileName': doc.id.split('_').first,
          });
        }
      }

      return results;
    } catch (e) {
      print('Error retrieving documents: ${e.toString()}');
      throw Exception('Error retrieving documents: ${e.toString()}');
    }
  }


  /// Clears all documents for the current user
  Future<void> clearData() async {
    try {
      final batch = _firestore.batch();
      final documents = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('documents')
          .get();

      for (var doc in documents.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error clearing data: ${e.toString()}');
    }
  }

}