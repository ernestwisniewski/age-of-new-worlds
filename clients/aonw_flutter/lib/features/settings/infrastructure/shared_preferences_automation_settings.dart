part of 'shared_preferences_client_settings_store.dart';

const _advanceActionsKey = 'aonw.settings.automation.advanceActions';
const _endTurnKey = 'aonw.settings.automation.endTurn';

extension _AutomationSettings on SharedPreferencesClientSettingsStore {
  Future<ClientAutomationSettings> _loadAutomation() async =>
      ClientAutomationSettings(
        advanceActions:
            await _preferences.getBool(_advanceActionsKey) ??
            ClientSettings.defaults.automation.advanceActions,
        endTurn:
            await _preferences.getBool(_endTurnKey) ??
            ClientSettings.defaults.automation.endTurn,
      );

  Future<void> _saveAutomation(ClientAutomationSettings settings) async {
    await _preferences.setBool(_advanceActionsKey, settings.advanceActions);
    await _preferences.setBool(_endTurnKey, settings.endTurn);
  }
}
