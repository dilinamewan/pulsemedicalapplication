import 'package:flutter/material.dart';
import 'package:pulse/ui/components/documentscreen.dart'; // Import the DocumentScreen
import 'package:pulse/models/Notes.dart';

class NoteScreen extends StatefulWidget {
  final String userId;
  final String scheduleId;
  final Function(String) onNoteSelected;

  const NoteScreen({
    Key? key,
    required this.userId,
    required this.scheduleId,
    required this.onNoteSelected,
  }) : super(key: key);

  @override
  _NoteScreenState createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  List<String> _uploadedFiles = []; // Track uploaded files
final NoteService _noteService = NoteService();
  List<Note> _notes = [];

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  void _fetchNotes() async {
    List<Note> notes = await _noteService.getNotes(widget.scheduleId);
    setState(() {
      _notes = notes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            // Title: Add Note
            Align(
              alignment: Alignment.center,
              child: Text(
                "Add Note",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 20),

            // Note Input Box
            Expanded(
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    TextField(
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: "Title",
                        hintStyle: TextStyle(color: Colors.grey),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Expanded(
                      child: TextField(
                        style: TextStyle(color: Colors.white),
                        maxLines: null,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: "Write your note here...",
                          hintStyle: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 40),

            // Title: Add Attachments
            Align(
              alignment: Alignment.center,
              child: Text(
                "Add Attachments",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 10),

            // Embed DocumentScreen with reduced height
            SizedBox(
              height: 150, // Reduced height
              child: DocumentScreen(
                key: ValueKey(_uploadedFiles), // Force rebuild when state changes
                userId: widget.userId,
                scheduleId: widget.scheduleId,
                noteId: "noteId", // Replace with the actual noteId if available
              ),
            ),

            SizedBox(height: 20), // Space for Bottom Nav Bar
          ],
        ),
      ),
    );
  }
}