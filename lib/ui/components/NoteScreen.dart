import 'package:flutter/material.dart';
import 'package:pulse/models/Notes.dart';

class NoteScreen extends StatefulWidget {
  final String userId;
  final String scheduleId;
  final Function(String) onNoteSelected;

  const NoteScreen({Key? key, required this.userId, required this.scheduleId, required this.onNoteSelected}) : super(key: key);

  @override
  _NoteScreenState createState() => _NoteScreenState();
}

class _NoteScreenState extends State<NoteScreen> {
  final NoteService _noteService = NoteService();
  List<Note> _notes = [];

  @override
  void initState() {
    super.initState();
    _fetchNotes();
  }

  void _fetchNotes() async {
    List<Note> notes = await _noteService.getNotes(widget.scheduleId, widget.userId);
    setState(() {
      _notes = notes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _notes.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(_notes[index].title),
          subtitle: Text(_notes[index].content),
          onTap: () => widget.onNoteSelected(_notes[index].noteId),
        );
      },
    );
  }
}
