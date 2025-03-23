import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mime/mime.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class DocumentScreen extends StatefulWidget {
  final String scheduleId;
  Function(List<String>?) onDocsUpdated;
  List<String>? docs;


  DocumentScreen({
    Key? key,
    required this.scheduleId,
    this.docs,
    required this.onDocsUpdated,
  }) : super(key: key);



  @override
  _DocumentScreenState createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {

  final SupabaseClient supabase = Supabase.instance.client;
  List<String> _uploadedFiles = []; // List to store uploaded file names

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _fetchDocuments();// Request permissions when the screen loads
  }


  @override
  void dispose() {


    super.dispose();
  }

  // Request storage permissions
  Future<void> _requestPermissions() async {
    if (await Permission.storage.request().isGranted) {
      print("Storage permission granted");
    } else {
      print("Storage permission denied");
    }
  }



  Future<void> uploadFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        PlatformFile file = result.files.first;

        String fileName = '${widget.scheduleId}/${file.name}';


        if (file.path != null) {
          File fileToUpload = File(file.path!);
          String? mimeType = lookupMimeType(file.path!);
          setState(() {
            _uploadedFiles.add('$fileName,${file.path},$mimeType,');
          });
          updateDocs();
        }else {
          print("File path not available");
        }


      } else {
        print("File picker canceled");
      }
    } catch (e) {
      print("Error uploading file: $e");
    }
  }


  // Handle file deletion
  void _deleteFile(int index) async {
    if (index >= 0 && index < _uploadedFiles.length) {
      String fileName = _uploadedFiles[index].split('/').last;
      try {
        //await supabase.storage.from('pulseapp').remove(['${widget.scheduleId}/$fileName']);
        setState(() {
          _uploadedFiles.removeAt(index);
        });
        updateDocs();
        print("File deleted: $fileName");
      } catch (e) {
        print("Error deleting file: $e");
      }
    } else {
      print("Invalid index: $index");
    }
  }
  void updateDocs() {

      setState(() {
        widget.docs = _uploadedFiles;
      });

    widget.onDocsUpdated(widget.docs); // Ensure updates are passed to NoteScreen
  }


  void _fetchDocuments() async {
    for (var doc in widget.docs!) {
      setState(() {
        _uploadedFiles.add(doc);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Display uploaded files
          Expanded(
            child: ListView.builder(
              itemCount: _uploadedFiles.length,
              itemBuilder: (context, index) {
                return Column(
                  children: [
                    ListTile(
                      leading: Icon(Icons.insert_drive_file, color: Colors.white),
                      onTap: () async {
                        final fileBytes = await supabase.storage.from('pulseapp').download(_uploadedFiles[index].split(',')[0]);

                        final filePath = '/storage/emulated/0/Download/${_uploadedFiles[index].split(',')[0].split('/')[1]}';
                        final file = File(filePath);

                        // Save file locally
                        await file.writeAsBytes(fileBytes);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("File downloaded to Downloads folder"),
                            action: SnackBarAction(
                              label: "Open",
                              onPressed: () {
                                OpenFilex.open(filePath); // Open the file with the default app
                              },
                            ),
                          ),
                        );
                                            },
                      title: Text(
                        _uploadedFiles[index].split(',')[0].split('/')[1],
                        style: TextStyle(color: Colors.white),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _deleteFile(index); // Delete the file
                        },
                      ),
                    ),
                    Divider(color: Colors.grey),
                  ],
                );
              },
            ),
          ),

          // Upload Document Button
          TextButton(

            onPressed: uploadFile,
            child: Text(
              "Upload Document",
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }
}
