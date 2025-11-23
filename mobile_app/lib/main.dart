import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue.shade600,
          brightness: Brightness.light,
        ),
      ),
      home: const TaskScreen(),
    );
  }
}

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  final String apiUrl = "http://10.0.2.2:5000/tasks";
  
  List tasks = [];
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        setState(() {
          tasks = json.decode(response.body);
        });
      }
    } catch (e) {
      print("Hata: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> addTask(String title) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"title": title}),
      );
      if (response.statusCode == 201) {
        fetchTasks();
        Navigator.pop(context);
      }
    } catch (e) {
      print("Ekleme Hatası: $e");
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      final response = await http.delete(Uri.parse("$apiUrl/$id"));
      if (response.statusCode == 200) {
        fetchTasks();
      }
    } catch (e) {
      print("Silme Hatası: $e");
    }
  }

  void showAddDialog() {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Yeni Görev Ekle"),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: "Görev adı giriniz",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) addTask(controller.text);
            },
            child: const Text("Ekle"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(" Görev Yöneticisi", style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 70,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.task_alt, size: 80, color: Colors.blue.shade400),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Henüz görev yok",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Yeni bir görev ekleyerek başlayın",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchTasks,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: tasks.length,
                    itemBuilder: (ctx, index) {
                      final task = tasks[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Dismissible(
                          key: Key(task['id'].toString()),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            decoration: BoxDecoration(
                              color: Colors.red.shade500,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (direction) => deleteTask(task['id']),
                          child: Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade400, Colors.blue.shade600],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "${index + 1}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              title: Text(
                                task['title'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => deleteTask(task['id']),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddDialog,
        icon: const Icon(Icons.add, size: 28),
        label: const Text("Görev Ekle"),
        elevation: 8,
      ),
    );
  }
}