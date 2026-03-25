import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:logbook_app_032/features/logbook/models/log_model.dart';
import 'package:logbook_app_032/features/logbook/log_controller.dart';
import 'package:mongo_dart/mongo_dart.dart' show ObjectId;

class LogEditorPage extends StatefulWidget {
  final LogModel? log;
  final int? index;
  final LogController controller;
  final Map<String, dynamic> currentUser;

  const LogEditorPage({
    super.key,
    this.log,
    this.index,
    required this.controller,
    required this.currentUser,
  });

  @override
  State<LogEditorPage> createState() => _LogEditorPageState();
}

class _LogEditorPageState extends State<LogEditorPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  String _selectedCategory = "Pribadi";
  bool _isPublic = false;
  final List<String> _categories = ["Pribadi", "Kuliah", "Kerja", "Urgent"];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.log?.title ?? '');
    _isPublic = widget.log?.isPublic ?? false;

    // Bersihkan prefix kategori dari deskripsi jika mode edit
    String cleanDesc = widget.log?.description ?? '';
    for (var cat in _categories) {
      if (cleanDesc.startsWith("[$cat] ")) {
        _selectedCategory = cat;
        cleanDesc = cleanDesc.replaceFirst("[$cat] ", "");
        break;
      }
    }
    _descController = TextEditingController(text: cleanDesc);

    // Listener agar tab Pratinjau update otomatis
    _descController.addListener(() => setState(() {}));
  }

  void _save() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Judul tidak boleh kosong")));
      return;
    }

    if (widget.log == null) {
      await widget.controller.addLog(
        _titleController.text,
        _descController.text,
        _selectedCategory,
        _isPublic,
      );
    } else {
      // Mode Edit
      await widget.controller.updateLog(
        ObjectId.fromHexString(widget.log!.id!),
        _titleController.text,
        _descController.text,
        _selectedCategory,
        _isPublic,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Catatan berhasil disimpan"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.log == null ? "Catatan Baru" : "Edit Catatan",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: const Color(0xFF1E3C72),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.save, color: Colors.white),
              onPressed: _save,
            ),
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: "Editor"),
              Tab(text: "Pratinjau"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Editor
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: "Judul",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      labelText: "Kategori",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _categories
                        .map(
                          (cat) =>
                              DropdownMenuItem(value: cat, child: Text(cat)),
                        )
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCategory = val!),
                  ),
                  const SizedBox(height: 12),
                  //Toggle Public/Private
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _isPublic ? Icons.public : Icons.lock,
                              color: _isPublic ? Colors.blue : Colors.red,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isPublic ? 'Public' : 'Private',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _isPublic ? Colors.blue : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isPublic,
                          onChanged: (val) => setState(() => _isPublic = val),
                          activeColor: Colors.blue,
                          inactiveThumbColor: Colors.red,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TextField(
                      controller: _descController,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        hintText:
                            "Tulis laporan dengan format Markdown...\n\n"
                            "Contoh:\n"
                            "# Judul Besar\n"
                            "**teks tebal**\n"
                            "- item list",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tab 2: Pratinjau Markdown
            Markdown(data: _descController.text),
          ],
        ),
      ),
    );
  }
}
