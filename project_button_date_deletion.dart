import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(TaskPrioritizerApp());
}

class Task {
  String name;
  String urgency;
  String deadline;
  bool isComplete;

  Task({
    required this.name,
    required this.urgency,
    required this.deadline,
    this.isComplete = false,
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
      title: 'Intelligent Task Prioritizer',
      debugShowCheckedModeBanner: false,
      theme: _isDarkMode
          ? ThemeData.dark().copyWith(
              primaryColor: Colors.teal,
              scaffoldBackgroundColor: Colors.black,
              cardColor: Colors.grey[900],
              floatingActionButtonTheme: FloatingActionButtonThemeData(
                backgroundColor: Colors.teal,
              ),
            )
          : ThemeData(
              primarySwatch: Colors.teal,
              scaffoldBackgroundColor: Colors.teal.shade50,
              textTheme: ThemeData.light().textTheme.copyWith(
                    titleLarge: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
  int _selectedIndex = 0;

  void _onItemTapped(int index) async {
    if (index == 1) {
      final Task? newTask = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AddTaskPage()),
      );
      if (newTask != null) {
        setState(() => tasks.add(newTask));
      }
    } else if (index == 2) {
      // Future implementation: Navigate to settings
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  void _toggleTaskCompletion(int index) {
    setState(() {
      tasks[index].isComplete = !tasks[index].isComplete;
    });
  }

  void _deleteTask(int index) {
    setState(() {
      tasks.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Task deleted')),
    );
  }

  void _showTaskDetails(int index) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tasks[index].name,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text('Deadline: ${tasks[index].deadline}'),
              Text('Urgency: ${tasks[index].urgency}'),
              Text(
                'Status: ${tasks[index].isComplete ? 'Complete' : 'Incomplete'}',
                style: TextStyle(
                  color: tasks[index].isComplete ? Colors.green : Colors.red,
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      _toggleTaskCompletion(index);
                      Navigator.pop(context);
                    },
                    child: Text(tasks[index].isComplete
                        ? 'Mark Incomplete'
                        : 'Mark Complete'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _showDeleteConfirmation(index);
                    },
                    child: Text('Delete'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Close'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Task?'),
        content:
            Text('Are you sure you want to delete "${tasks[index].name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteTask(index);
              Navigator.pop(ctx);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gradient = BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.teal.shade200, Colors.white],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Tasks'),
        actions: [
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.dark_mode : Icons.light_mode),
            onPressed: widget.onToggleTheme,
          )
        ],
      ),
      body: Container(
        decoration: gradient,
        child: tasks.isEmpty
            ? Center(child: Text('No tasks added yet.'))
            : ListView.builder(
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return GestureDetector(
                    onTap: () => _showTaskDetails(index),
                    child: Card(
                      elevation: 10,
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color:
                          widget.isDarkMode ? Colors.grey[850] : Colors.white,
                      child: ListTile(
                        leading: Icon(
                          task.isComplete ? Icons.check_circle : Icons.task,
                          size: 30,
                          color: task.isComplete ? Colors.green : Colors.teal,
                        ),
                        title: Text(
                          task.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: task.isComplete
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        subtitle: Text(
                          '📅 Deadline: ${task.deadline} | 🔥 Urgency: ${task.urgency}',
                          style: TextStyle(
                            decoration: task.isComplete
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        trailing: Icon(
                          task.isComplete ? Icons.check : Icons.chevron_right,
                          color: task.isComplete ? Colors.green : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Prioritization logic will be added here later
        },
        icon: Icon(Icons.sort),
        label: Text('Prioritise'),
        backgroundColor: Colors.teal,
        elevation: 8,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.miniEndFloat,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.white,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box),
            label: 'Add Task',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

class AddTaskPage extends StatefulWidget {
  @override
  AddTaskPageState createState() => AddTaskPageState();
}

class AddTaskPageState extends State<AddTaskPage> {
  final _formKey = GlobalKey<FormState>();
  final taskController = TextEditingController();
  DateTime? _selectedDate;
  String? urgency;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Add Task")),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.teal.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: taskController,
                decoration: InputDecoration(
                  labelText: "Task Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter task name' : null,
              ),
              SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: "Urgency",
                  border: OutlineInputBorder(),
                ),
                value: urgency,
                items: ['High', 'Medium', 'Low']
                    .map((u) => DropdownMenuItem(
                          child: Text(u),
                          value: u,
                        ))
                    .toList(),
                onChanged: (value) => setState(() => urgency = value),
                validator: (value) => value == null ? 'Select urgency' : null,
              ),
              SizedBox(height: 20),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: "Deadline",
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null
                            ? 'Select a date'
                            : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                      ),
                      Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (_selectedDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Please select a deadline date')),
                      );
                      return;
                    }
                    final newTask = Task(
                      name: taskController.text,
                      urgency: urgency!,
                      deadline:
                          DateFormat('MMM dd, yyyy').format(_selectedDate!),
                    );
                    Navigator.pop(context, newTask);
                  }
                },
                child: Text("Save Task", style: TextStyle(fontSize: 18)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
