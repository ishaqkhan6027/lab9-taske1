import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: CrudApp(),
    );
  }
}

class CrudApp extends StatefulWidget {
  @override
  _CrudAppState createState() => _CrudAppState();
}

class _CrudAppState extends State<CrudApp> {
  List posts = [];
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  int? editingPostId;

  @override
  void initState() {
    super.initState();
    fetchPosts();
  }

  Future<void> fetchPosts() async {
    final response =
        await http.get(Uri.parse('https://jsonplaceholder.typicode.com/posts'));
    if (response.statusCode == 200) {
      setState(() {
        posts = jsonDecode(response.body);
      });
    } else {
      showError('Failed to fetch posts.');
    }
  }

  Future<void> createPost(String title, String body) async {
    final response = await http.post(
      Uri.parse('https://jsonplaceholder.typicode.com/posts'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'body': body}),
    );
    if (response.statusCode == 201) {
      setState(() {
        posts.add(jsonDecode(response.body));
      });
    } else {
      showError('Failed to create post.');
    }
  }

  Future<void> updatePost(int id, String title, String body) async {
    final response = await http.put(
      Uri.parse('https://jsonplaceholder.typicode.com/posts/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'body': body}),
    );
    if (response.statusCode == 200) {
      setState(() {
        final index = posts.indexWhere((post) => post['id'] == id);
        if (index != -1) posts[index] = jsonDecode(response.body);
      });
    } else {
      showError('Failed to update post.');
    }
  }

  Future<void> deletePost(int id) async {
    final response = await http
        .delete(Uri.parse('https://jsonplaceholder.typicode.com/posts/$id'));
    if (response.statusCode == 200) {
      setState(() {
        posts.removeWhere((post) => post['id'] == id);
      });
    } else {
      showError('Failed to delete post.');
    }
  }

  void showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void showForm({int? id, String? title, String? body}) {
    editingPostId = id;
    _titleController.text = title ?? '';
    _bodyController.text = body ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    value!.isEmpty ? 'Title is required' : null,
              ),
              TextFormField(
                controller: _bodyController,
                decoration: InputDecoration(labelText: 'Body'),
                validator: (value) =>
                    value!.isEmpty ? 'Body is required' : null,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    if (editingPostId != null) {
                      updatePost(editingPostId!, _titleController.text,
                          _bodyController.text);
                    } else {
                      createPost(_titleController.text, _bodyController.text);
                    }
                    Navigator.pop(context);
                  }
                },
                child: Text(editingPostId != null ? 'Update' : 'Create'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Color getTextColor(String type) {
    switch (type) {
      case 'title':
        return Colors.black;
      case 'body':
        return Colors.blue;
      case 'icon':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.amberAccent,
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        title: Text(
          'CRUD Application',
          style: TextStyle(color: Colors.green),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: posts.length,
        itemBuilder: (context, index) {
          final post = posts[index];
          return ListTile(
            title: Text(
              post['title'] ?? '',
              style: TextStyle(color: getTextColor('title')),
            ),
            subtitle: Text(
              post['body'] ?? '',
              style: TextStyle(color: getTextColor('body')),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: getTextColor('icon')),
                  onPressed: () => showForm(
                    id: post['id'],
                    title: post['title'],
                    body: post['body'],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: getTextColor('icon')),
                  onPressed: () => deletePost(post['id']),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showForm(),
        child: Icon(Icons.add),
      ),
    );
  }
}
