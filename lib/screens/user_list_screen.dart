import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'add_edit_user_screen.dart';

class UserListScreen extends StatefulWidget {
  final ApiService apiService;

  const UserListScreen({Key? key, required this.apiService}) : super(key: key);

  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late Future<List<User>> futureUsers;
  List<User> _localUsers = []; // Local list to track changes

  @override
  void initState() {
    super.initState();
    futureUsers = _fetchUsers();
  }

  Future<List<User>> _fetchUsers() async {
    try {
      final apiUsers = await widget.apiService.getUsers();
      _localUsers = List.from(apiUsers); // Create a new list from API data
      return _localUsers;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching users: ${e.toString()}')),
      );
      return _localUsers; // Return local users even if API fails
    }
  }

  void _addUserLocally(User newUser) {
    setState(() {
      _localUsers.insert(0, newUser); // Add to beginning of list
    });
  }

  void _updateUserLocally(User updatedUser) {
    setState(() {
      final index = _localUsers.indexWhere((u) => u.id == updatedUser.id);
      if (index != -1) {
        _localUsers[index] = updatedUser;
      }
    });
  }

  void _deleteUserLocally(int id) {
    setState(() {
      _localUsers.removeWhere((u) => u.id == id);
    });
  }

  Future<void> _refreshUsers() async {
    setState(() {
      futureUsers = _fetchUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshUsers,
          ),
        ],
      ),
      body: FutureBuilder<List<User>>(
        future: futureUsers,
        builder: (context, snapshot) {
          // Show local users if we have them, fallback to snapshot
          final usersToShow = _localUsers.isNotEmpty ? _localUsers : snapshot.data ?? [];

          if (snapshot.connectionState == ConnectionState.waiting && _localUsers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError && _localUsers.isEmpty) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          return ListView.builder(
            itemCount: usersToShow.length,
            itemBuilder: (context, index) {
              User user = usersToShow[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  title: Text(user.name),
                  subtitle: Text(user.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () async {
                          final updatedUser = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEditUserScreen(
                                apiService: widget.apiService,
                                user: user,
                              ),
                            ),
                          );
                          if (updatedUser != null) {
                            _updateUserLocally(updatedUser);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          try {
                            await widget.apiService.deleteUser(user.id);
                            _deleteUserLocally(user.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('User deleted')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error deleting user: ${e.toString()}')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final newUser = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditUserScreen(
                apiService: widget.apiService,
              ),
            ),
          );
          if (newUser != null) {
            _addUserLocally(newUser);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User added')),
            );
          }
        },
      ),
    );
  }
}