import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:p_learn_app/services/group_service.dart';
import 'package:p_learn_app/api/endpoints.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GroupDetailScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupDetailScreen({
    Key? key,
    required this.groupId,
    required this.groupName,
  }) : super(key: key);

  @override
  _GroupDetailScreenState createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final GroupService _groupService = GroupService();
  late Future<List<dynamic>> _documentsFuture;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _documentsFuture = _groupService.getGroupDocuments(widget.groupId);
  }

  void _refreshDocuments() {
    setState(() {
      _documentsFuture = _groupService.getGroupDocuments(widget.groupId);
    });
  }

  Future<void> _pickAndUploadFile() async {
    if (_isUploading) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);

      setState(() => _isUploading = true);

      try {
        bool success = await _groupService.uploadDocument(
          widget.groupId,
          file.path,
        );

        if (mounted) {
          if (success) {
            _refreshDocuments();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tải lên thành công!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            throw Exception('Tải lên thất bại.');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Lỗi: ${e.toString().replaceAll("Exception: ", "")}',
              ),
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _openDocument(Map<String, dynamic> doc) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access_token") ?? "";

      final String fileName = doc["fileName"];
      final String docId = doc["id"].toString();
      final String url = Endpoints.downloadGroupDocument(widget.groupId, docId);

      final tempDir = await getTemporaryDirectory();
      final savePath = "${tempDir.path}/$fileName";

      final response = await Dio().get(
        url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {"Authorization": "Bearer $token"},
        ),
      );

      if (response.statusCode == 200) {
        final file = File(savePath);
        await file.writeAsBytes(response.data);
        await OpenFilex.open(savePath);
      } else {
        throw Exception("Server trả về mã lỗi ${response.statusCode}");
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Không thể mở tệp: $e")));
    }
  }

  Future<void> _deleteDocument(Map<String, dynamic> doc) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("access_token") ?? "";
      final docId = doc["id"].toString();

      final String url = Endpoints.deleteGroupDocument(widget.groupId, docId);

      final response = await Dio().delete(
        url,
        options: Options(
          headers: {"Authorization": "Bearer $token"},
          validateStatus: (_) => true,
        ),
      );

      if (response.statusCode == 200) {
        _refreshDocuments();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Xóa tài liệu thành công!"),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception("Server trả về mã lỗi ${response.statusCode}");
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Không thể xóa tài liệu: $e")));
    }
  }

  void _confirmDelete(Map<String, dynamic> doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận xoá"),
        content: Text("Xoá tài liệu '${doc['fileName']}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteDocument(doc);
            },
            child: const Text("Xoá", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: _buildDocumentsView(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _pickAndUploadFile,
      backgroundColor: Colors.red,
      child: _isUploading
          ? const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
          : const Icon(Icons.upload_file),
      tooltip: 'Tải lên tài liệu',
    );
  }

  Widget _buildDocumentsView() {
    return FutureBuilder<List<dynamic>>(
      future: _documentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.red),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Lỗi tải tài liệu: ${snapshot.error}',
              textAlign: TextAlign.center,
            ),
          );
        }

        final documents = snapshot.data;
        if (documents == null || documents.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_off_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Chưa có tài liệu nào trong nhóm',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async => _refreshDocuments(),
          color: Colors.red,
          child: ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final doc = documents[index];

              return Card(
                margin: const EdgeInsets.symmetric(
                  vertical: 4.0,
                  horizontal: 8.0,
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.insert_drive_file,
                    color: Colors.red,
                    size: 40,
                  ),

                  title: Text(
                    doc['fileName'] ?? 'Tệp không tên',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),

                  subtitle: Text(
                    'Người đăng: ${doc['uploader']?['username'] ?? "N/A"}',
                  ),

                  onTap: () => _openDocument(doc),

                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _confirmDelete(doc),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
