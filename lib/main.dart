import 'package:flutter/material.dart';
void main() {
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: const HomeScreen(),
    );
  }
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {

  @override
  Widget build(BuildContext context) {
    int completedCount = TaskRepository().tasks.where((t) => t.done).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("KrakFlow"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Masz dziś ${TaskRepository().tasks.length} zadania",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text("Wykonano: $completedCount"),
            const SizedBox(height: 16),
            const Text(
              "Dzisiejsze zadania",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: TaskRepository().tasks.length,
                itemBuilder: (context, index) {
                  return TaskCard(task: TaskRepository().tasks[index]);
                },
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddTaskScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}


class Task {
  final String title;
  final String deadline;
  final bool done;
  final String priority;

  Task({
    required this.title,
    required this.deadline,
    required this.done,
    required this.priority,
  });
}

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    return Card(
        child: ListTile(
            leading: Icon(
              task.done ? Icons.check_circle : Icons.radio_button_unchecked,
              color: task.done ? Colors.green : Colors.grey,
            ),
            title: Text(
              task.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: task.done ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: Text("termin: ${task.deadline} | priorytet: ${task.priority}"),
          ),
        );
  }
}

class TaskRepository{
  final List<Task> tasks = [
    Task(title: "zrobic projekt strony", deadline: "31.03.2026", done: true, priority: "wysoki"),
    Task(title: "fluter", deadline: "26.03.2026 18:00", done: true, priority: "sredni"),
    Task(title: "Aisd", deadline: "30.03.2026", done: false, priority: "niski"),
  ];
}

class AddTaskScreen extends StatelessWidget {
  const AddTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nowe zadanie"),
      ),
      body: const Center(
        child: Text("Tutaj będzie formularz dodawania taska"),
      ),
    );
  }
}




