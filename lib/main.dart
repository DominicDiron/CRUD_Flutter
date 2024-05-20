import 'dart:io';
import 'package:crud/model/user.dart';
import 'package:crud/database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  // sqfliteFfiInit();
  // databaseFactory = databaseFactoryFfi;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CRUD Application',
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<User> users = [];
  final nameController = TextEditingController();
  String? imagePath;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void dispose() {
    nameController.dispose();
    DatabaseHelper.close();
    super.dispose();
  }

  Future<void> refresh() async {
    final data = await DatabaseHelper.readAll();
    setState(() {
      users = data;
    });
  }

  Future<void> pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        imagePath = pickedFile.path;
      });
    }
  }

  Future<void> editUser({User? user}) async {
    if (user != null) {
      nameController.text = user.name;
      imagePath = user.imagePath;
    } else {
      nameController.clear();
      imagePath = null;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Form(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10,),
                ElevatedButton(
                  onPressed: pickImage,
                  child: const Text('Pick Image'),
                ),
                if (imagePath != null) Image.file(File(imagePath!)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () async {
                if (nameController.text.isNotEmpty && imagePath != null) {
                  if (user == null) {
                    await DatabaseHelper.create(
                        nameController.text, imagePath!);
                  } else {
                    await DatabaseHelper.update(User(
                        id: user.id,
                        name: nameController.text,
                        imagePath: imagePath!));
                  }
                  Navigator.of(context).pop();
                  refresh();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CRUD"),
      ),
      body: FutureBuilder<List<User>>(
        future: DatabaseHelper.readAll(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No users'));
          } else {
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: Image.file(File(users[index].imagePath)),
                  title: Text(users[index].name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          await editUser(user: users[index]);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await DatabaseHelper.delete(users[index]);
                          refresh();
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                content: Form(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (value) {
                          if (value!.isEmpty) {
                            return 'Please enter a name';
                          }
                          return null;
                        },
                      ),
                      ElevatedButton(
                        onPressed: pickImage,
                        child: const Text('Pick Image'),
                      ),
                      if (imagePath != null) Image.file(File(imagePath!)),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: const Text('Save'),
                    onPressed: () async {
                      if (nameController.text.isNotEmpty && imagePath != null) {
                        await DatabaseHelper.create(
                            nameController.text, imagePath!);
                        nameController.clear();
                        imagePath = null;
                        Navigator.of(context).pop();
                        refresh();
                      }
                    },
                  ),
                ],
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
