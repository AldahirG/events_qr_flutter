import 'package:flutter/material.dart';
import '../models/event.dart';

class EventCard extends StatelessWidget {
  final Event event;
  const EventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.qr_code),
      title: Text(event.name ?? event.qrValue),
      subtitle: Text('Registrado: ${event.createdAt.toLocal()}'),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
