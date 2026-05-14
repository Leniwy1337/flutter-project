import 'package:flutter/material.dart';
import 'Services/task_api_service.dart';
import 'Services/task_local_database.dart';
import 'Services/task_sync_service.dart';
import 'Models/task.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'dart:math';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox("tasks");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const HomeScreen());
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int allTasksCount = 0;
  int doneTasksCount = 0;
  int todoTasksCount = 0;

  void updateCounters(List<Task> tasks) {
    setState(() {
      allTasksCount = tasks.length;
      doneTasksCount = tasks.where((task) => task.done).length;
      todoTasksCount = tasks.where((task) => !task.done).length;
    });
  }

  String selectedFilter = "wszystkie";
  late Future<List<Task>> tasksFuture;

  @override
  void initState() {
    super.initState();
    tasksFuture = TaskApiService.fetchTasks();
  }

  Future<List<Task>> loadTasks() async {
    await TaskSyncService.loadInitialDataIfNeeded();
    return TaskLocalDatabase.getTasks();
  }

  Future<void> addTask(Task task) async {
    await TaskLocalDatabase.addTask(task);
    setState(() {
      tasksFuture = loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("KrakFlow"),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final tasks = await tasksFuture;
              if (context.mounted) {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Potwierdzenie"),
                      content: const Text("Czy na pewno chcesz usunąć wszystkie zadania?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Anuluj"),
                        ),
                        TextButton(
                          onPressed: () async {
                            await TaskLocalDatabase.deleteAllTasks();
                            if (!context.mounted) return;
                            setState(() {
                              tasksFuture = loadTasks();
                            });
                            Navigator.pop(context);

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Wszystkie zadania zostały usunięte"),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Text("Usuń"),
                        ),
                      ],
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Task>>(
        future: tasksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Text("Błąd: ${snapshot.error}"),
            );
          }
          
          final tasks = snapshot.data ?? [];
          WidgetsBinding.instance.addPostFrameCallback((_) {
            updateCounters(tasks);
          });
          int completedCount = tasks.where((t) => t.done).length;

          List<Task> filteredTasks = tasks;
          if (selectedFilter == "wykonane") {
            filteredTasks = tasks.where((task) => task.done).toList();
          } else if (selectedFilter == "do zrobienia") {
            filteredTasks = tasks.where((task) => !task.done).toList();
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Masz dziś ${tasks.length} zadania",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text("Wykonano: $completedCount"),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: () {
                        setState(() {
                          selectedFilter = "wszystkie";
                        });
                      },
                      child: Text(
                        "Wszystkie",
                        style: TextStyle(
                          color: selectedFilter == "wszystkie"
                              ? Colors.blue
                              : Colors.grey,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          selectedFilter = "do zrobienia";
                        });
                      },
                      child: Text(
                        "Do zrobienia",
                        style: TextStyle(
                          color: selectedFilter == "do zrobienia"
                              ? Colors.blue
                              : Colors.grey,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          selectedFilter = "wykonane";
                        });
                      },
                      child: Text(
                        "Wykonane",
                        style: TextStyle(
                          color: selectedFilter == "wykonane"
                              ? Colors.blue
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  "Dzisiejsze zadania",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return Dismissible(
                        key: ValueKey(task.title),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20.0),
                          child: const Icon(Icons.delete, color: Colors.white)
                        ),
                        onDismissed: (direction) async {
                          await TaskLocalDatabase.deleteTask(task.id);
                          setState(() {
                            tasksFuture = loadTasks();
                          });

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Zadanie usunięte: ${task.title}"),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        child: TaskCard(
                          title: task.title,
                          subtitle: "termin: ${task.deadline} | priorytet: ${task.priority}",
                          done: task.done,
                          onChanged: (value) async {
                            final updatedTask = Task(
                              id: task.id,
                              title: task.title,
                              deadline: task.deadline,
                              priority: task.priority,
                              done: value ?? false,
                            );

                            await TaskLocalDatabase.updateTask(updatedTask);
                            setState(() {
                              tasksFuture = loadTasks();
                            });
                          },
                          onTap: () async {
                            final Task? updatedTask = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EditTaskScreen(task: task),
                              ),
                            );
                            if (updatedTask != null) {
                              await TaskLocalDatabase.updateTask(updatedTask);
                              setState(() {
                                tasksFuture = loadTasks();
                              });
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final tasks = await tasksFuture;
          if (context.mounted) {
            final Task? newTask = await Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    AddTaskScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      final curvedAnimation = CurvedAnimation(
                        parent: animation,
                        curve: Curves.bounceOut,
                      );

                      final offsetAnimation = Tween<Offset>(
                        begin: const Offset(0.0, 1.0),
                        end: Offset.zero,
                      ).animate(curvedAnimation);

                      return SlideTransition(
                        position: offsetAnimation,
                        child: child,
                      );
                    },
              ),
            );
            if (newTask != null) {
              await addTask(newTask);
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}


class TaskCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool done;
  final ValueChanged<bool?>? onChanged;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.done,
    this.onChanged,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Checkbox(
          value: done,
          onChanged: onChanged,
        ),
        title: Text(
          title,
          style: TextStyle(
            decoration: done
              ? TextDecoration.lineThrough
              : TextDecoration.none,
            color: done ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
        ),
      ),
    );
  }
}

class AddTaskScreen extends StatelessWidget {
  AddTaskScreen({super.key});

  final TextEditingController titleController = TextEditingController();
  final TextEditingController deadlineController = TextEditingController();
  final TextEditingController priorityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Nowe zadanie")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Tytuł zadania",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: deadlineController,
              decoration: const InputDecoration(
                labelText: "Termin",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priorityController,
              decoration: const InputDecoration(
                labelText: "Priorytet",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final newTask = Task(
                  id: Random().nextInt(1000000),
                  title: titleController.text,
                  deadline: deadlineController.text,
                  priority: priorityController.text,
                  done: false,
                );
                Navigator.pop(context, newTask);
              },
              child: const Text("Zapisz"),
            ),
          ],
        ),
      ),
    );
  }
}

class EditTaskScreen extends StatefulWidget {
  final Task task;

  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  late TextEditingController titleController;
  late TextEditingController deadlineController;
  late TextEditingController priorityController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.task.title);
    deadlineController = TextEditingController(text: widget.task.deadline);
    priorityController = TextEditingController(text: widget.task.priority);
  }

  @override
  void dispose() {
    titleController.dispose();
    deadlineController.dispose();
    priorityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edytuj zadanie")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Tytuł zadania",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: deadlineController,
              decoration: const InputDecoration(
                labelText: "Termin",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priorityController,
              decoration: const InputDecoration(
                labelText: "Priorytet",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                final updatedTask = Task(
                  id: widget.task.id,
                  title: titleController.text,
                  deadline: deadlineController.text,
                  priority: priorityController.text,
                  done: widget.task.done,
                );
                Navigator.pop(context, updatedTask);
              },
              child: const Text("Zapisz zmiany"),
            ),
          ],
        ),
      ),
    );
  }
}
