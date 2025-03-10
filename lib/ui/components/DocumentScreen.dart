import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class DocumentScreen extends StatefulWidget {
  final String userId;
  final String scheduleId;
  final String noteId;

  const DocumentScreen({
    Key? key,
    required this.userId,
    required this.scheduleId,
    required this.noteId,
  }) : super(key: key);

  @override
  _DocumentScreenState createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  List<String> _uploadedFiles = []; // List to store uploaded file names

  @override
  void initState() {
    super.initState();
    _requestPermissions(); // Request permissions when the screen loads
  }

  @override
  void dispose() {
    // Clean up resources (if needed)
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

  // Handle file upload
  Future<void> _uploadFile() async {
    try {
      print("Opening file picker...");
      FilePickerResult? result = await FilePicker.platform.pickFiles();

      if (result != null) {
        print("File picked: ${result.files.single.name}");
        setState(() {
          _uploadedFiles.add(result.files.single.name);
        });
      } else {
        print("File picker canceled");
      }
    } catch (e) {
      print("Error picking file: $e");
    }
  }

  // Handle file deletion
  void _deleteFile(int index) {
    setState(() {
      _uploadedFiles.removeAt(index);
    });
    print("File deleted: ${_uploadedFiles[index]}");
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
                      title: Text(
                        _uploadedFiles[index],
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
            onPressed: _uploadFile,
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