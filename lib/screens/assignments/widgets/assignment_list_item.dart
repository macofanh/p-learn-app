import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:p_learn_app/models/assignment_model.dart';

class AssignmentListItem extends StatelessWidget {
  const AssignmentListItem({
    super.key,
    required this.assignment,
    required this.onLongPress,
    this.onStatusChanged,
  });

  final Assignment assignment;
  final VoidCallback onLongPress;
  final ValueChanged<bool?>? onStatusChanged;

  // ---- Tính số ngày đến hạn ----
  String _getDueDateInfo(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dday = DateTime(dueDate.year, dueDate.month, dueDate.day);

    final diff = dday.difference(today).inDays;

    if (diff < 0) return "Đã quá hạn";
    if (diff == 0) return "Hạn hôm nay";
    if (diff == 1) return "Còn 1 ngày";
    return "Còn $diff ngày";
  }

  // ---- Màu trạng thái ----
  Color _getDueColor(DateTime dueDate) {
    final now = DateTime.now();
    final diff = dueDate.difference(now).inDays;

    if (dueDate.isBefore(now) && diff < 0) return Colors.red;
    if (diff <= 3) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final dueInfo = _getDueDateInfo(assignment.dueDate);
    final dueColor = _getDueColor(assignment.dueDate);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: dueColor.withOpacity(0.1),
            child: Icon(
              Icons.assignment,
              color: dueColor,
            ),
          ),

          // ======================
          // 🔥 Dùng đúng dữ liệu từ endpoint
          // ======================
          title: Text(
            assignment.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),

          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Mô tả
              if (assignment.description.isNotEmpty)
                Text(
                  assignment.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),

              const SizedBox(height: 4),

              // Hạn nộp
              Text(
                "Hạn nộp: ${DateFormat('dd/MM/yyyy').format(assignment.dueDate)}",
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),

          // Badge trạng thái thời gian
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                dueInfo,
                style: TextStyle(
                  color: dueColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Checkbox(
                value: assignment.completed,
                onChanged: onStatusChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
