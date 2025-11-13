import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'local_queue_service.dart';
import 'geolocation_service.dart';

class QueueProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final LocalQueueService _localDb = LocalQueueService();
  final GeolocationService _geoService = GeolocationService();
  // Added in Part 2
  List<Map<String, dynamic>> _clients = [];
  List<Map<String, dynamic>> get clients => _clients;

  Future<void> initialize() async {
    await _loadQueue();
  }

  Future<void> _loadQueue() async {
    // 1. Load from local DB immediately (offline support)
    _clients = await _localDb.getClients();
    notifyListeners();
    // 2. Sync unsynced records to Supabase
    await _syncLocalToRemote();
    // 3. Subscribe to real-time updates
    _setupRealtimeSubscription();
  }

  Future<void> _syncLocalToRemote() async {
    final unsynced = await _localDb.getUnsyncedClients();
    for (var client in unsynced) {
      try {
        final remoteClient = Map<String, dynamic>.from(client)
          ..remove('is_synced');
        await _supabase.from('clients').upsert(remoteClient);
        await _localDb.markClientAsSynced(client['id'] as String);
        // Optional: update local _clients list to reflect sync status
      } catch (e) {
        // Log error but continue syncing other items
        print('Sync failed for ${client['id']}: $e');
        // In production: consider retry logic or user notification
      }
    }
    // Refresh UI if any sync succeeded
    _clients = await _localDb.getClients();
    notifyListeners();
  }

  Future<void> addClient(String name) async {
    final position = await _geoService.getCurrentPosition();
    final newClient = {
      'id': const Uuid().v4(),
      'name': name,
      'lat': position?.latitude,
      'lng': position?.longitude,
      'created_at': DateTime.now().toIso8601String(),
      'is_synced': 0,
    };
    // Save locally immediately
    await _localDb.insertClientLocally(newClient);
    // Update UI instantly
    _clients.add(newClient);
    _clients.sort((a, b) => a['created_at'].compareTo(b['created_at']));
    notifyListeners();
    // Attempt sync (non-blocking for UX)
    unawaited(_syncLocalToRemote());
  }

  Future<void> removeClient(String id) async {
    try {
      final supabase = Supabase.instance.client;

      // Remove from Supabase
      await supabase.from('clients').delete().eq('id', id);

      // Keep local state in sync
      clients.removeWhere((c) => c['id'] == id);
      notifyListeners();
    } catch (e) {
      // optional: log the error
      // import 'package:flutter/foundation.dart' if debugPrint is needed
      debugPrint('removeClient error: $e');
    }
  }

  Map<String, dynamic>? nextClient() {
    if (clients.isEmpty) return null;
    final next = clients.removeAt(0);
    notifyListeners();
    return next;
  }

  void _setupRealtimeSubscription() {
    // Your existing Supabase subscription logic
  }
}
