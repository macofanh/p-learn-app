import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:p_learn_app/services/group_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:p_learn_app/api/endpoints.dart';

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

class _GroupDetailScreenState extends State<GroupDetailScreen> with SingleTickerProviderStateMixin {
  final GroupService _groupService = GroupService();
  late Future<List<dynamic>> _documentsFuture;
  late TabController _tabController;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _documentsFuture = _groupService.getGroupDocuments(widget.groupId);
    _tabController = TabController(length: 2, vsync: this);
    // Add a listener to rebuild the widget when the tab changes, so the FAB can update.
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refreshDocuments() {
    setState(() {
      _documentsFuture = _groupService.getGroupDocuments(widget.groupId);
    });
  }

  Future<void> _pickAndUploadFile() async {
    // Prevent picking if upload is already in progress
    if (_isUploading) return;

    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      
      setState(() {
        _isUploading = true;
      });

      try {
        bool success = await _groupService.uploadDocument(widget.groupId, file.path);
        if (mounted) {
          if (success) {
            _refreshDocuments();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tải lên thành công!'), backgroundColor: Colors.green),
            );
          } else {
            throw Exception('Tải lên thất bại.');
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: ${e.toString().replaceAll("Exception: ", "")}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isUploading = false;
          });
        }
      }
    }
  }

  Future<void> _downloadFile(String documentUrl) async {
    final Uri baseUrl = Uri.parse(Endpoints.baseUrl);
    final Uri fullUrl = baseUrl.resolve(documentUrl);

    if (!await launchUrl(fullUrl)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể mở tệp: $documentUrl')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.groupName),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Trò chuyện'),
            Tab(text: 'Tài liệu'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildChatView(),
          _buildDocumentsView(),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_tabController.index == 1) {
      return FloatingActionButton(
        onPressed: _pickAndUploadFile,
        backgroundColor: Colors.red,
        child: _isUploading
            ? const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
            : const Icon(Icons.upload_file),
        tooltip: 'Tải lên tài liệu',
      );
    }
    return null;
  }

  Widget _buildChatView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          const Text(
            'Tính năng trò chuyện sắp ra mắt',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsView() {
    return FutureBuilder<List<dynamic>>(
      future: _documentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.red));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Lỗi tải tài liệu: ${snapshot.error.toString().replaceAll("Exception: ", "")}',
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
                 Text('Chưa có tài liệu nào trong nhóm', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            )
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
                margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file, color: Colors.red, size: 40),
                  title: Text(
                    doc['fileName'] ?? 'Tệp không tên',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Loại: ${doc['fileType'] ?? 'N/A'}'),
                  onTap: () => _downloadFile(doc['filePath']),
                ),
              );
            },
          ),
        );
      },
    );
  }
}