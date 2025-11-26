import 'package:flutter/material.dart';
import 'package:p_learn_app/screens/group/create_group_dialog.dart';
import 'package:p_learn_app/screens/group/join_group_dialog.dart';
import 'package:p_learn_app/services/group_service.dart';

class StudyGroupScreen extends StatefulWidget {
  const StudyGroupScreen({super.key});

  @override
  State<StudyGroupScreen> createState() => _StudyGroupScreenState();
}

class _StudyGroupScreenState extends State<StudyGroupScreen> {
  List<dynamic> _groups = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // SỬ DỤNG HÀM MỚI fetchGroups()
      final groups = await GroupService().fetchGroups();
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  void _showGroupActions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (BuildContext bc) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: Colors.red),
                title: const Text('Tạo nhóm mới'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => CreateGroupDialog(onSuccess: _fetchGroups),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.group_add_outlined, color: Colors.red),
                title: const Text('Tham gia nhóm'),
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (context) => JoinGroupDialog(onSuccess: _fetchGroups),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Nhóm',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 28),
            onPressed: _showGroupActions,
            tooltip: "Thêm nhóm",
          )
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchGroups,
        color: Colors.red,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _fetchGroups,
                child: const Text("Thử lại", style: TextStyle(color: Colors.red)),
              )
            ],
          ),
        ),
      );
    }

    if (_groups.isEmpty) {
      return ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          const Center(
            child: Column(
              children: [
                Icon(Icons.groups_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  "Chưa tham gia nhóm nào",
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text("Nhấn dấu + ở góc phải để tạo hoặc tham gia"),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final group = _groups[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: Colors.red.shade100,
              child: Text(
                (group['name'] != null && group['name'].isNotEmpty) 
                  ? group['name'][0].toUpperCase() 
                  : 'G',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              group['name'] ?? "Không tên",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (group['description'] != null && group['description'].isNotEmpty)
                  Text(
                    group['description'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SelectableText( // Cho phép user copy mã code
                    "Mã nhóm: ${group['groupCode'] ?? 'N/A'}",
                    style: TextStyle(
                      color: Colors.grey.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Đã chọn nhóm: ${group['name']}")),
              );
              // TODO: Điều hướng vào chi tiết nhóm ở đây
            },
          ),
        );
      },
    );
  }
}