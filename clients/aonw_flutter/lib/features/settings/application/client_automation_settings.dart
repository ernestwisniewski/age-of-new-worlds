final class ClientAutomationSettings {
  const ClientAutomationSettings({
    this.advanceActions = true,
    this.endTurn = false,
  });

  final bool advanceActions;
  final bool endTurn;

  ClientAutomationSettings copyWith({bool? advanceActions, bool? endTurn}) =>
      ClientAutomationSettings(
        advanceActions: advanceActions ?? this.advanceActions,
        endTurn: endTurn ?? this.endTurn,
      );

  @override
  bool operator ==(Object other) =>
      other is ClientAutomationSettings &&
      other.advanceActions == advanceActions &&
      other.endTurn == endTurn;

  @override
  int get hashCode => Object.hash(advanceActions, endTurn);
}
