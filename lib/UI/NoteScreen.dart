import 'package:flutter/material.dart';
import 'package:pulse/ui/components/documentscreen.dart';

class NoteScreen extends StatefulWidget {
  final String? title;
  final String? content;
  List<String>? docs;
  final String scheduleId;
  final Function(String, String, List<String>?) onSave; // Callback function

  NoteScreen({
    super.key,
    this.title,
    this.content,
    this.docs,
    required this.scheduleId,
    required this.onSave, // Receive the function
  });

  @override
  _NoteScreenState createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  TextEditingController _titleController = TextEditingController();
  TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.scheduleId.isNotEmpty) {
      _fetchNotes();
    } else {
      setValues();
    }
  }

  void setValues() {
    _titleController.text = widget.title ?? "";
    _contentController.text = widget.content ?? "";
  }

  void _fetchNotes() async {
    _titleController.text = widget.title ?? "";
    _contentController.text = widget.content ?? "";
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[900],
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          widget.scheduleId.isEmpty ? "Add Note" : "Edit Note",
          style: const TextStyle(color: Colors.white),
        ),
      ),
      backgroundColor: Colors.grey[900],
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _titleController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              hintText: "Title",
                              hintStyle: TextStyle(color: Colors.grey),
                              border: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _contentController,
                            style: const TextStyle(color: Colors.white),
                            maxLines: null,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: "Write your note here...",
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.center,
                      child: const Text(
                        "Attachments",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 150,
                      child: DocumentScreen(
                        docs: widget.docs ?? [],
                        scheduleId: widget.scheduleId,
                        onDocsUpdated: (updatedDocs) {
                          if (mounted) {
                            setState(() {
                              widget.docs = List.from(updatedDocs ?? []);
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.grey[900],
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: const Text("Cancel", style: TextStyle(color: Colors.white)),
            ),
            ElevatedButton(
              onPressed: () {
                widget.onSave(
                  _titleController.text,
                  _contentController.text,
                  List.from(widget.docs ?? []),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              ),
              child: const Text("Save", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
