import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Task Model
class Task {
  String name;
  String urgency;
  String deadline;
  List<int> dependencies;
  
  Task({
    required this.name, 
    required this.urgency, 
    required this.deadline,
    this.dependencies = const [],
  });

  Map<String, dynamic> toJson() {
    // Convert string urgency to numeric score for API compatibility
    int urgencyScore = urgency == 'High' ? 3 : (urgency == 'Medium' ? 2 : 1);
    double normalizedUrgency = urgencyScore / 3.0; // Normalize between 0-1
    
    return {
      'id': DateTime.now().millisecondsSinceEpoch % 10000, // Simple unique ID
      'name': name,
      'deadline': deadline,
      'urgency_score': urgencyScore,
      'status': 'Pending',
      'normalized_urgency': normalizedUrgency,
      'dependencies': dependencies,
    };
  }
}

void main() {
  runApp(TaskPrioritizerApp());
}

class TaskPrioritizerApp extends StatefulWidget {
  const TaskPrioritizerApp({super.key});

  @override
  TaskPrioritizerAppState createState() => TaskPrioritizerAppState();
}

// Rest of the code remains the same until prioritizeTasks method

Future<List<dynamic>> prioritizeTasks(List<Task> tasks) async {
  try {
    final response = await http.post(
      Uri.parse('http://10.0.2.2:5000/prioritize_tasks'), // Updated endpoint
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'tasks': tasks.map((task) => task.toJson()).toList(),
        'completed_task_ids': [],
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['prioritized_tasks'];
    } else {
      final error = json.decode(response.body);
      throw Exception('API Error: ${error['error'] ?? 'Unknown error'}');
    }
  } catch (e) {
    throw Exception('Connection failed: $e');
  }
}

// TestAPIPage updates
class TestAPIPageState extends State<TestAPIPage> {
  String responseText = "Click the button to send sample tasks to Flask backend";
  bool isLoading = false;

  Future<void> sendTasksToFlask() async {
    setState(() => isLoading = true);
    
    // Updated test data that matches API expectations
    final tasks = {
      "tasks": [
        {
          "id": 1,
          "name": "Study for Math test",
          "deadline": "2025-05-30",
          "urgency_score": 3,
          "dependencies": [],
          "status": "Pending",
          "normalized_urgency": 0.7
        },
        {
          "id": 2,
          "name": "Watch Netflix",
          "deadline": "2025-06-15",
          "urgency_score": 1,
          "dependencies": [],
          "status": "Pending",
          "normalized_urgency": 0.2
        }
      ],
      "completed_task_ids": []
    };

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/prioritize_tasks'), // Updated endpoint
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(tasks),
      );

      setState(() {
        isLoading = false;
        if (response.statusCode == 200) {
          responseText = "Success! API response:\n\n${json.encode(json.decode(response.body))}";
        } else {
          responseText = "Failed (${response.statusCode}):\n${response.body}";
        }
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        responseText = "Connection Error: $e";
      });
    }
  }
}


