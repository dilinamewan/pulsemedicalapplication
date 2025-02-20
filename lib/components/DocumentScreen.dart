import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../models/Documents.dart';

class DocumentScreen extends StatefulWidget {
  final String userId;
  final String scheduleId;
  final String noteId;

  const DocumentScreen({Key? key, required this.userId, required this.scheduleId, required this.noteId}) : super(key: key);

  @override
  _DocumentScreenState createState() => _DocumentScreenState();
}

class _DocumentScreenState extends State<DocumentScreen> {
  final DocumentService _documentService = DocumentService();
  List<Document> _documents = [];

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  void _fetchDocuments() async {
    List<Document> documents = await _documentService.getDocuments(widget.userId, widget.scheduleId, widget.noteId);
    setState(() {
      _documents = documents;
    });
  }

  Future<void> _uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      File file = File(result.files.single.path!);
      await _documentService.uploadDocument(widget.userId, widget.scheduleId, widget.noteId, file);
      _fetchDocuments();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(onPressed: _uploadFile, child: Text("Upload Document")),
        Expanded(
          child: ListView.builder(
            itemCount: _documents.length,
            itemBuilder: (context, index) {
              return ListTile(
                title: Text(_documents[index].name),
                subtitle: Text(_documents[index].url),
                trailing: IconButton(
                  icon: Icon(Icons.download),
                  onPressed: () {
                    // Open document URL
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
