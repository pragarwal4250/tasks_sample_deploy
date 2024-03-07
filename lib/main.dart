import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:bson/bson.dart';

void main() {
  runApp(const MyApp());
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
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Task App',
      home: TaskList(baseUrl: 'http://ec2-3-145-28-92.us-east-2.compute.amazonaws.com:3001'), // Set your base URL here
    );
  }
}

class TaskList extends StatefulWidget {
  final String baseUrl;

  const TaskList({Key? key, required this.baseUrl}) : super(key: key);

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
    final response = await http.get(Uri.parse('${widget.baseUrl}/tasks'));
    if (response.statusCode == 200) {
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
        await http.delete(Uri.parse('${widget.baseUrl}/tasks/$taskId'));
    if (response.statusCode == 200) {
      fetchTasks();
    } else {
      throw Exception('Failed to delete task');
    }
  }

  void navigateToAddTaskScreen() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => AddTaskScreen(baseUrl: widget.baseUrl),
    )).then((_) {
      fetchTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task App'),
      ),
      body: ListView.builder(
        itemCount: tasks.length,
        itemBuilder: (context, index) {
          final task = tasks[index];
          return ListTile(
            title: Text(task.title),
            subtitle: Text(task.description),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => deleteTask(task.id),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: navigateToAddTaskScreen,
        tooltip: 'Add Task',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddTaskScreen extends StatelessWidget {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final String baseUrl;

  AddTaskScreen({Key? key, required this.baseUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Task'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () async {
                final newTask = Task.create(
                  title: titleController.text,
                  description: descriptionController.text,
                );

                final response = await http.post(
                  Uri.parse('${baseUrl}/tasks'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'title': newTask.title,
                    'description': newTask.description,
                  }),
                );

                if (response.statusCode == 200) {
                  Navigator.of(context).pop();
                } else {
                  // Handle the error accordingly (e.g., display a message to the user)
                }
              },
              child: const Text('Add Task'),
            ),
          ],
        ),
      ),
    );
  }
}
