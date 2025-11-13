import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waiting_room_app/queue_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TEMPORARY: Replace with your actual credentials
  await Supabase.initialize(
    url: 'https://oigosuipigmzzrswynaa.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9pZ29zdWlwaWdtenpyc3d5bmFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTkxNjk0NTgsImV4cCI6MjA3NDc0NTQ1OH0.MjCmNFd5RSNwIoCJaxCYUWlAxtOSyVCFHCfycKqiV38',
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => QueueProvider(),
      child: const WaitingRoomApp(),
    ),
  );
}

class WaitingRoomApp extends StatelessWidget {
  const WaitingRoomApp({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    return MaterialApp(
      title: 'Waiting Room',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: Scaffold(
        appBar: AppBar(title: const Text('Waiting Room'), centerTitle: true),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Input Field
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: const InputDecoration(hintText: 'Enter name'),
                      onSubmitted: (name) {
                        context.read<QueueProvider>().addClient(name);
                        controller.clear();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final name = controller.text.trim();
                      if (name.isNotEmpty) {
                        context.read<QueueProvider>().addClient(name);
                        controller.clear();
                      }
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Queue List
              Expanded(
                child: Consumer<QueueProvider>(
                  builder: (context, provider, _) {
                    if (provider.clients.isEmpty) {
                      return const Center(
                        child: Text('No one in queue yet...'),
                      );
                    }

                    return ListView.builder(
                      itemCount: provider.clients.length,
                      itemBuilder: (context, index) {
                        final client = provider.clients[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            title: Text(client['name'] ?? 'Unknown'),
                            subtitle: Text(
                              client['lat'] == null
                                  ? '📍 Location not captured'
                                  : '📍 ${client['lat']?.toStringAsFixed(4)}, ${client['lng']?.toStringAsFixed(4)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                context.read<QueueProvider>().removeClient(client['id'] as String);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Next Button
              ElevatedButton.icon(
                onPressed: () {
                  context.read<QueueProvider>().nextClient();
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Next Client'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
