import 'package:flutter/material.dart';
void main() {
  runApp(MyApp());
}
class MyApp extends StatelessWidget {
  MyApp({super.key});

  final List<Task> tasks = [
    Task(title: "zrobic projekt strony", deadline: "31.03.2026", done: true, priority: "wysoki"),
    Task(title: "fluter", deadline: "26.03.2026 18:00", done: true, priority: "sredni"),
    Task(title: "Aisd", deadline: "30.03.2026", done: false, priority: "niski"),
  ];





  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("KrakFlow"),
        ),


        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "masz dzis ${tasks.length} zadania",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index){
                    final task = tasks[index];

                    return TaskCard(task: task);
                  },
                ),
              ),
            ],
          ),
        ),

        floatingActionButton: FloatingActionButton(onPressed: (){

        },
        child: const Icon(Icons.add),
        ),



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




