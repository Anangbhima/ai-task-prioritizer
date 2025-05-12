import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(TaskPrioritizerApp());
}

// Task Model
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

  Map<String, dynamic> toJson() {
    int urgencyScore = _urgencyToScore(urgency);
    double normalizedUrgency = urgencyScore / 3.0;

    return {
      'id': DateTime.now().millisecondsSinceEpoch % 10000,
      'name': name,
      'deadline': deadline,
      'urgency_score': urgencyScore,
      'status': isComplete ? 'Complete' : 'Pending',
      'normalized_urgency': normalizedUrgency,
      'dependencies': [],
    };
  }

  static int _urgencyToScore(String urgency) {
    switch (urgency) {
      case 'High':
        return 3;
      case 'Medium':
        return 2;
      case 'Low':
        return 1;
      default:
        return 1;
    }
  }
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
  final String _apiUrl = "http://10.0.2.2:5000/prioritize_tasks"; // Update with your Flask backend URL

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedUrgency = 'Medium';
  DateTime _selectedDeadline = DateTime.now().add(Duration(days: 7));

  Future<void> _prioritizeTasks() async {
    try {
      final apiTasks = tasks.map((task) {
        return {
          "id": DateTime.now().millisecondsSinceEpoch % 10000,
          "name": task.name,
          "deadline": DateFormat('yyyy-MM-dd')
              .format(DateFormat('MMM dd, yyyy').parse(task.deadline)),
          "urgency_score": _urgencyToScore(task.urgency),
          "dependencies": [],
          "status": task.isComplete ? 'Complete' : 'Pending',
          "normalized_urgency": _urgencyToScore(task.urgency) / 3.0,
        };
      }).toList();

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'tasks': apiTasks, 'completed_task_ids': []}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prioritized = List<Map<String, dynamic>>.from(data['prioritized_tasks']);

        setState(() {
          tasks = prioritized.map((t) {
            return Task(
              name: t['name'] ?? 'Unnamed Task',
              urgency: _scoreToUrgency(t['urgency_score']),
              deadline: DateFormat('MMM dd, yyyy')
                  .format(DateFormat('yyyy-MM-dd').parse(t['deadline'])),
              score: t['score']?.toDouble(),
              isComplete: t['status'] == 'Complete',
            );
          }).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('API Error: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection failed: $e')),
      );
    }
  }

  int _urgencyToScore(String urgency) {
    switch (urgency) {
      case 'High':
        return 3;
      case 'Medium':
        return 2;
      case 'Low':
        return 1;
      default:
        return 1;
    }
  }

  String _scoreToUrgency(int score) {
    if (score >= 3) return 'High';
    if (score >= 2) return 'Medium';
    return 'Low';
  }

  Color _getPriorityColor(double score) {
    if (score > 0.7) return Colors.red;
    if (score > 0.4) return Colors.orange;
    return Colors.green;
  }

  void _addTask() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        tasks.add(Task(
          name: _nameController.text,
          urgency: _selectedUrgency,
          deadline: DateFormat('MMM dd, yyyy').format(_selectedDeadline),
        ));
        _nameController.clear();
        _selectedUrgency = 'Medium';
        _selectedDeadline = DateTime.now().add(Duration(days: 7));
      });
      Navigator.of(context).pop();
    }
  }

  Future<void> _selectDeadline(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDeadline)
      setState(() {
        _selectedDeadline = picked;
      });
  }

  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Task'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Task Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter task name';
                      }
                      return null;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedUrgency,
                    items: ['High', 'Medium', 'Low']
                        .map((label) => DropdownMenuItem(
                              child: Text(label),
                              value: label,
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedUrgency = value!;
                      });
                    },
                    decoration: InputDecoration(labelText: 'Urgency'),
                  ),
                  SizedBox(height: 10),
                  Row(
                    children: [
                      Text('Deadline: ${DateFormat('MMM dd, yyyy').format(_selectedDeadline)}'),
                      IconButton(
                        icon: Icon(Icons.calendar_today),
                        onPressed: () => _selectDeadline(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: Text('Add'),
              onPressed: _addTask,
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                _nameController.clear();
                _selectedUrgency = 'Medium';
                _selectedDeadline = DateTime.now().add(Duration(days: 7));
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleTaskCompletion(int index) {
    setState(() {
      tasks[index].isComplete = !tasks[index].isComplete;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI Task Prioritizer'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.wb_sunny : Icons.nightlight_round),
            onPressed: widget.onToggleTheme,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _prioritizeTasks,
        icon: Icon(Icons.auto_awesome),
        label: Text('AI Prioritize'),
        backgroundColor: Colors.teal,
      ),
      body: tasks.isEmpty
          ? Center(child: Text('No tasks added yet.'))
          : ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return Card(
                  child: ListTile(
                    title: Text(task.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📅 ${task.deadline}'),
                        Text('Urgency: ${task.urgency}'),
                        if (task.score != null)
                          Text('⚡ Priority Score: ${task.score!.toStringAsFixed(2)}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        task.isComplete ? Icons.check_box : Icons.check_box_outline_blank,
                        color: task.score != null
                            ? _getPriorityColor(task.score!)
                            : Colors.grey,
                      ),
                      onPressed: ()
::contentReference[oaicite:0]{index=0}
 


