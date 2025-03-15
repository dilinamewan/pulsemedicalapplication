import 'package:flutter/material.dart';
import 'package:pulse/ui/components/documentscreen.dart';
import 'package:pulse/models/Notes.dart';

class NoteScreen extends StatefulWidget {
  final String scheduleId;

  const NoteScreen({
    Key? key,
    required this.scheduleId,
  }) : super(key: key);

  @override
  _NoteScreenState createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  final NoteService _noteService = NoteService();
  List<Note> _notes = [];
  TextEditingController _titleController = TextEditingController();
  TextEditingController _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.scheduleId.isNotEmpty) {
      _fetchNotes();
    }
  }

  void _fetchNotes() async {
    List<Note> notes = await _noteService.getNotes(widget.scheduleId);
    if (notes.isNotEmpty) {
      setState(() {
        _notes = notes;
        _titleController.text = notes.first.title;
        _contentController.text = notes.first.content;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                "Edit Note",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 20),
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
                      controller: _titleController,
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
                        controller: _contentController,
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
            Align(
              alignment: Alignment.center,
              child: Text(
                "Attachments",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 10),
            SizedBox(
              height: 150,
              child: DocumentScreen(
                key: ValueKey(widget.scheduleId),
                scheduleId: widget.scheduleId,
                noteId: _notes.isNotEmpty ? _notes.first.noteId : "",
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}