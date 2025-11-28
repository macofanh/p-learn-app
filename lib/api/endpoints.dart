import 'package:flutter_dotenv/flutter_dotenv.dart';

class Endpoints {
  static String get baseUrl => dotenv.env['API_BASE_URL']!;

  //Auth
  static String get login => '$baseUrl/api/auth/login';
  static String get register => '$baseUrl/api/auth/register';
  static String get resetPassword => '$baseUrl/api/auth/reset-password';

  //Subjects
  static String get createSubject => '$baseUrl/api/subjects/create';
  static String get getAllSubjects => '$baseUrl/api/subjects/getAll';
  static String getSubjectById(String id) => '$baseUrl/api/subjects/$id';
  static String updateSubject(String id) => '$baseUrl/api/subjects/update/$id';
  static String deleteSubject(String id) => '$baseUrl/api/subjects/delete/$id';

  //Notes 
  static String createNote(String subjectId) => '$baseUrl/api/notes/create/$subjectId';
  static String getAllNotes(String subjectId) => '$baseUrl/api/notes/getAll/$subjectId';
  static String getNoteById(String noteId) => '$baseUrl/api/notes/get/$noteId';
  static String updateNote(String noteId) => '$baseUrl/api/notes/update/$noteId';
  static String deleteNote(String noteId) => '$baseUrl/api/notes/delete/$noteId';

  //Tasks
  static String createTask(String subjectId) => '$baseUrl/api/subjects/create/$subjectId/tasks';
  static String getAllTasks(String subjectId) => '$baseUrl/api/subjects/$subjectId/tasks/list';
  static String getTaskById(String taskId) => '$baseUrl/api/tasks/get/$taskId';
  static String updateTask(String taskId) => '$baseUrl/api/tasks/update/$taskId';
  static String deleteTask(String taskId) => '$baseUrl/api/delete/tasks/$taskId';

  //Schedules
  static String createSchedule(String subjectId) => '$baseUrl/api/schedules/create/$subjectId';
  static String getAllSchedules(String subjectId) => '$baseUrl/api/schedules/getAll/$subjectId';
  static String getScheduleById(String scheduleId) => '$baseUrl/api/schedules/get/$scheduleId';
  static String updateSchedule(String scheduleId) => '$baseUrl/api/schedules/update/$scheduleId';
  static String deleteSchedule(String scheduleId) => '$baseUrl/api/schedules/delete/$scheduleId';

  //Groups
  static String get createGroup => '$baseUrl/api/groups/createGroup';
  static String get getAllGroups => '$baseUrl/api/groups/getAll';
  static String getGroupById(String groupId) => '$baseUrl/api/groups/get/$groupId';
  static String joinGroup(String groupCode) => '$baseUrl/api/groups/join/$groupCode';
  static String leaveGroup(String groupId) => '$baseUrl/api/groups/$groupId/leave';
  static String deleteGroup(String groupId) => '$baseUrl/api/groups/delete/$groupId';
  static String getGroupDocuments(String groupId) => '$baseUrl/api/groups/get/$groupId/documents';
  static String uploadGroupDocument(String groupId) => '$baseUrl/api/groups/$groupId/documents';
  static String downloadGroupDocument(String groupId, String documentId) =>'$baseUrl/api/groups/$groupId/documents/$documentId/download';
  static String deleteGroupDocument(String groupId, String documentId) =>'$baseUrl/api/groups/$groupId/documents/$documentId';
} 