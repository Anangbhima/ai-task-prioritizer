import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(TaskPrioritizerApp());
}

class Task {
  String name;
  String urgency;
  String deadline;
  bool isComplete;
  double? score;

  Task({
    required this.name,
    required this.urgency,
    required this.deadline,
    this.isComplete = false,
    this.score,
  });
}

class TaskPrioritizerApp extends StatefulWidget {
  @override
  TaskPrioritizerAppState createState() => TaskPrioritizerAppState();
}

class TaskPrioritizerAppState extends State<TaskPrioritizerApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => _isDarkMode = prefs.getBool('isDarkMode') ?? false);
  }

  void _toggleTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() => _isDarkMode = !_isDarkMode);
    prefs.setBool('isDarkMode', _isDarkMode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Task Prioritizer',
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode
          ? ThemeData.dark().copyWith(
              primaryColor: Colors.teal,
              cardColor: Colors.grey[900],
            )
          : ThemeData(
              primarySwatch: Colors.teal,
              scaffoldBackgroundColor: Colors.teal.shade50,
            ),
      home: TaskListPage(
        isDarkMode: _isDarkMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class TaskListPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onToggleTheme;

  TaskListPage({required this.isDarkMode, required this.onToggleTheme});

  @override
  TaskListPageState createState() => TaskListPageState();
}

class TaskListPageState extends State<TaskListPage> {
  List<Task> tasks = [];
  final String _apiUrl = "https://your-render-url.onrender.com/prioritize_tasks";

  // Helper functions
  int _urgencyToScore(String urgency) {
    switch (urgency) {
      case 'High': return 3;
      case 'Medium': return 2;
      case 'Low': return 1;
      default: return 1;
    }
  }

  double _normalizedUrgency(String urgency) => _urgencyToScore(urgency) / 3.0;

  String _getStatus(Task task) {
    if (task.isComplete) return "complete";
    try {
      final deadline = DateFormat('MMM dd, yyyy').parse(task.deadline);
      return deadline.isBefore(DateTime.now()) ? "overdue" : "pending";
    } catch (e) {
      return "pending";
    }
  }

  Future<void> _prioritizeTasks() async {
    try {
      final apiTasks = tasks.map((task) {
        return {
          "deadline": DateFormat('yyyy-MM-dd')
              .format(DateFormat('MMM dd, yyyy').parse(task.deadline)),
          "urgency_score": _urgencyToScore(task.urgency),
          "dependencies": [],
          "status": _getStatus(task),
          "normalized_urgency": _normalizedUrgency(task.urgency),
        };
      }).toList();

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tasks': apiTasks}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prioritized = List<Map<String,dynamic>>.from(data['prioritized_tasks']);
        
        setState(() {
          tasks = prioritized.map((t) {
            return Task(
              name: t['name'] ?? 'Unnamed Task',
              urgency: _scoreToUrgency(t['urgency_score']),
              deadline: DateFormat('MMM dd, yyyy')
                  .format(DateFormat('yyyy-MM-dd').parse(t['deadline'])),
              score: t['score']?.toDouble(),
              isComplete: t['status'] == 'complete',
            );
          }).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  String _scoreToUrgency(int score) {
    if (score >= 3) return 'High';
    if (score >= 2) return 'Medium';
    return 'Low';
  }

  // Rest of your existing UI code (AddTaskPage, ListTiles, etc.)
  // ... [पहले जैसा UI कोड] ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _prioritizeTasks,
        icon: Icon(Icons.auto_awesome),
        label: Text('AI Prioritize'),
        backgroundColor: Colors.teal,
      ),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return ListTile(
            title: Text(task.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('📅 ${task.deadline}'),
                if (task.score != null)
                  Text('⚡ Priority Score: ${task.score!.toStringAsFixed(2)}'),
              ],
            ),
            trailing: Icon(
              task.isComplete ? Icons.check_circle : Icons.auto_awesome,
              color: task.score != null 
                 ? _getPriorityColor(task.score!)
                 : Colors.grey,
            ),
          );
        },
      ),
    );
  }

  Color _getPriorityColor(double score) {
    if (score > 0.7) return Colors.red;
    if (score > 0.4) return Colors.orange;
    return Colors.green;
  }
}
