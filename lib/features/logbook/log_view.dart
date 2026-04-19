import 'package:flutter/material.dart';
import 'package:mongo_dart/mongo_dart.dart' as mongo;
import 'package:logbook_app_032/services/access_control_service.dart';
import 'package:logbook_app_032/features/logbook/log_editor_page.dart';
import 'package:logbook_app_032/vision/vision_view.dart';
import 'log_controller.dart';
import 'models/log_model.dart';

class LogView extends StatefulWidget {
  final String username;
  final String role;
  final String teamId;

  const LogView({
    super.key,
    required this.username,
    required this.role,
    required this.teamId,
  });

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  late final LogController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = LogController(
      username: widget.username,
      teamId: widget.teamId,
      role: widget.role,
    );
    _controller.loadLogs();
  }

  void _goToEditor({LogModel? log, int? index}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LogEditorPage(
          log: log,
          index: index,
          controller: _controller,
          currentUser: {
            'uid': widget.username,
            'username': widget.username,
            'role': widget.role,
            'teamId': widget.teamId,
          },
        ),
      ),
    ).then((_) => _controller.loadLogs());
  }

  void _goToVision() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VisionView()),
    );
  }

  Color _getCategoryColor(String desc) {
    if (desc.startsWith("[Urgent]")) return Colors.redAccent;
    if (desc.startsWith("[Kerja]")) return Colors.blueAccent;
    if (desc.startsWith("[Kuliah]")) return Colors.greenAccent;
    return Colors.orangeAccent;
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Ketua':
        return Colors.deepPurple;
      case 'Admin':
        return Colors.deepOrange;
      case 'Asisten':
        return Colors.amber;
      case 'Anggota':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _onRefresh() async {
    await _controller.syncWithCloud();
    _controller.loadLogs();
  }

  @override
  Widget build(BuildContext context) {
    final canCreate = AccessControlService.canPerform(
      widget.role,
      AccessControlService.actionCreate,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Logbook: ${widget.username}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getRoleColor(widget.role),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.role,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () => _showLogoutDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _searchController,
                  onChanged: (val) => _controller.filterLogs(val),
                  decoration: InputDecoration(
                    hintText: "Cari catatan...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<LogModel>>(
              valueListenable: _controller.filteredLogs,
              builder: (context, currentLogs, _) {
                if (currentLogs.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: currentLogs.length,
                    itemBuilder: (context, index) {
                      final log = currentLogs[index];
                      final accentColor = _getCategoryColor(log.description);
                      final bool isOwner = log.authorId == widget.username;

                      return Dismissible(
                        key: Key(log.id ?? index.toString()),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) async {
                          return await AccessControlService.canPerform(
                            widget.role,
                            AccessControlService.actionDelete,
                            isOwner: isOwner,
                          );
                        },
                        onDismissed: (_) async {
                          if (log.id != null) {
                            await _controller.removeLog(
                              mongo.ObjectId.fromHexString(log.id!),
                            );
                          }
                        },
                        background: _buildDeleteBackground(),
                        child: _buildLogCard(log, index, accentColor, isOwner),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // ─── FAB: Kamera + Tambah berdampingan ───────────────────────────────
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Tombol Kamera
            FloatingActionButton(
              heroTag: 'fab_camera',
              backgroundColor: const Color(0xFF2A5298),
              onPressed: _goToVision,
              tooltip: 'Smart Patrol Vision',
              child: const Icon(Icons.camera_alt, color: Colors.white),
            ),

            // Jarak antar tombol
            if (canCreate) const SizedBox(width: 12),

            // Tombol Tambah Log — hanya muncul jika punya izin
            if (canCreate)
              FloatingActionButton(
                heroTag: 'fab_add',
                backgroundColor: const Color(0xFF1E3C72),
                onPressed: () => _goToEditor(),
                tooltip: 'Tambah Catatan',
                child: const Icon(Icons.add, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_stories_rounded,
            size: 70,
            color: Color(0xFF1E3C72),
          ),
          const SizedBox(height: 20),
          const Text(
            "Belum ada catatan",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          TextButton.icon(
            onPressed: () => _goToEditor(),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text("Buat Catatan Pertama"),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteBackground() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete_sweep, color: Colors.white, size: 30),
    );
  }

  Widget _buildLogCard(
    LogModel log,
    int index,
    Color accentColor,
    bool isOwner,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.only(bottom: 12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
            Expanded(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Icon(
                  log.id == null ? Icons.cloud_off_outlined : Icons.cloud_done,
                  color: log.id == null ? Colors.grey : Colors.green,
                  size: 28,
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        log.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(log),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      log.date,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            if (AccessControlService.canPerform(
              widget.role,
              AccessControlService.actionUpdate,
              isOwner: isOwner,
            ))
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Center(
                  child: IconButton(
                    icon: const Icon(
                      Icons.edit_note,
                      color: Colors.blue,
                      size: 28,
                    ),
                    onPressed: () => _goToEditor(log: log, index: index),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(LogModel log) {
    final isPublic = log.isPublic ?? true;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isPublic ? Colors.blue.shade100 : Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublic ? Icons.public : Icons.lock,
            size: 12,
            color: isPublic ? Colors.blue : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            isPublic ? 'Public' : 'Private',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isPublic ? Colors.blue : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text("Konfirmasi Logout"),
        content: const Text("Apakah Anda yakin ingin keluar?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
            },
            child: const Text("Keluar"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
