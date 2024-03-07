import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bson/bson.dart';

void main() {
  runApp(MyApp());
}

class Task {
  final String id;
  final String title;
  final String description;

  Task({
    required this.id,
    required this.title,
    required this.description,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['_id'],
      title: json['title'],
      description: json['description'],
    );
  }

  // New constructor without the id
  Task.create({String id = '', required this.title, required this.description})
      : id = id.isEmpty ? ObjectId().toHexString() : id;
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task App',
      home: TaskList(),
    );
  }
}

class TaskList extends StatefulWidget {
  @override
  _TaskListState createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  List<Task> tasks = [];

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    final response = await http.get(Uri.parse('http://localhost:3001/tasks'));
    if (response.statusCode == 200) {
      print('Connected');
      final List<dynamic> tasksJson = json.decode(response.body);
      setState(() {
        tasks = tasksJson.map((task) => Task.fromJson(task)).toList();
      });
    } else {
      throw Exception('Failed to load tasks');
    }
  }

  Future<void> deleteTask(String taskId) async {
    final response =
        await http.delete(Uri.parse('http://localhost:3001/tasks/$taskId'));
    if (response.statusCode == 200) {
      fetchTasks();
    } else {
      throw Exception('Failed to delete task');
    }
  }

  // Function to navigate to the screen for adding a new task
  void navigateToAddTaskScreen() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => AddTaskScreen(),
    )).then((_) {
      // Refresh the task list when returning from the add task screen
      fetchTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Task App'),
      ),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return ListTile(
            title: Text(task.title),
            subtitle: Text(task.description),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => deleteTask(task.id),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: navigateToAddTaskScreen,
        tooltip: 'Add Task',
        child: Icon(Icons.add),
      ),
    );
  }
}

class AddTaskScreen extends StatelessWidget {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                // Create a new task without the id
                final newTask = Task.create(
                  title: titleController.text,
                  description: descriptionController.text,
                );

                // Send the new task to the server using http.post
                final response = await http.post(
                  Uri.parse('http://localhost:3001/tasks'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'title': newTask.title,
                    'description': newTask.description,
                  }),
                );

                if (response.statusCode == 200) {
                  print('New Task added successfully');
                  // Close the add task screen
                  Navigator.of(context).pop();
                } else {
                  print('Failed to add new task. Server returned ${response.statusCode}');
                  // Handle the error accordingly (e.g., display a message to the user)
                }
              },
              child: Text('Add Task'),
            ),
          ],
        ),
      ),
    );
  }
}
