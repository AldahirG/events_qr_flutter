import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../providers/evento_provider.dart';
import 'show_info_screen.dart';

const String BASE_URL = 'https://tu-api-aqui.com';

class ListScreen extends ConsumerStatefulWidget {
  const ListScreen({super.key});

  @override
  ConsumerState<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends ConsumerState<ListScreen> {
  String _search = '';
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String _eventoActual = '';

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _loading = true);
    final evento = ref.read(eventoProvider);
    if (evento.isEmpty) return;

    try {
      final url = Uri.parse('$BASE_URL/registros?conferencista=${Uri.encodeComponent(evento)}');
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          _users = List<Map<String, dynamic>>.from(data);
        } else {
          _users = [];
        }
        _eventoActual = evento;
      } else {
        _users = [];
      }
    } catch (e) {
      debugPrint('Error fetching users: $e');
      _users = [];
    } finally {
      setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    final searchText = _search.trim().toLowerCase();
    if (searchText.isEmpty) return _users;

    return _users.where((user) {
      final nombre = (user['nombre'] ?? '').toString().toLowerCase();
      final telefono = (user['telefono'] ?? '').toString();
      return nombre.contains(searchText) || telefono.contains(searchText);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Registros')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_eventoActual.isNotEmpty)
                    Text(
                      _eventoActual,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: colors.primary),
                    ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre o teléfono',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      filled: true,
                      fillColor: colors.surface,
                    ),
                    onChanged: (v) => setState(() => _search = v),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _fetchUsers,
                    child: const Text('Buscar'),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _filteredUsers.isEmpty
                        ? Center(
                            child: Text(
                              'No se encontraron usuarios',
                              style: TextStyle(color: colors.onSurface),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                color: colors.surface,
                                child: ListTile(
                                  title: Text(user['nombre']?.trim() ?? 'Sin nombre'),
                                  subtitle: Text(
                                      '${user['telefono'] ?? 'Sin teléfono'} • ${user['correo']?.toLowerCase() ?? 'Sin correo'}'),
                                  onTap: () {
                                    // Navegar a ShowInfoScreen pasando idregistro_conferencias
                                    final idRegistro = user['idregistro_conferencias'];
                                    if (idRegistro != null) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ShowInfoScreen(id: idRegistro),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }
}
