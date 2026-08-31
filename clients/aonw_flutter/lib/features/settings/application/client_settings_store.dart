import 'client_settings.dart';

abstract interface class ClientSettingsStore {
  Future<ClientSettings> load();

  Future<void> save(ClientSettings settings);
}
