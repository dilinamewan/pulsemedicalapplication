import 'package:flutter/material.dart';
import 'package:pulse/ui/components/documentscreen.dart';
import 'package:pulse/ui/components/documentscreen.dart' show DocumentScreen;



class NoteScreen extends StatefulWidget {
  final String? title;
  final String? content;
  List<String>? docs;
  final String scheduleId;
  final Function(String, String, List<String>?) onSave; // Callback function

  NoteScreen({
    Key? key,
    this.title,
    this.content,
    this.docs,
    required this.scheduleId,
    required this.onSave, // Receive the function
  }) : super(key: key);

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
    }else
      setValues();
  }
  void setValues(){
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
                docs: widget.docs ?? [], // Ensure it's not null
                scheduleId: widget.scheduleId,
                  onDocsUpdated: (updatedDocs) {
                    if (mounted) {
                      setState(() {
                        widget.docs = List.from(updatedDocs ?? []);
                      });
                    }
                  },
              )

            ),
            //const Spacer(), // Pushes buttons to the bottom
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Closes the screen
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent, // Cancel button color
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: const Text("Cancel", style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Call onSave with updated docs list
                    widget.onSave(
                      _titleController.text,
                      _contentController.text,
                      List.from(widget.docs ?? []), // Ensure list is not null
                    );

                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  ),
                  child: const Text("Save", style: TextStyle(color: Colors.white)),
                ),


              ],
            ),

            SizedBox(height: 20),

          ],
        ),
      ),
    );
  }
}
