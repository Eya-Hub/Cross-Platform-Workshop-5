@GenerateMocks([GeolocationService])
void main() {
  test('addClient saves client with geolocation', () async {
    final mockGeo = MockGeolocationService();
    final mockPos = Position(
      latitude: 37.7749,
      longitude: -122.4194,
      timestamp: DateTime.now(),
      accuracy: 5.0,
      // ... other required fields
    );

    when(mockGeo.getCurrentPosition()).thenAnswer((_) async => mockPos);

    final provider = QueueProvider();
    // Inject mock (you may need to refactor QueueProvider to accept geoService in constructor)
    provider._geoService = mockGeo; // Or use dependency injection

    await provider.addClient('Test User');
    final client = provider.clients.last;

    expect(client['lat'], 37.7749);
    expect(client['lng'], -122.4194);
  });
}
