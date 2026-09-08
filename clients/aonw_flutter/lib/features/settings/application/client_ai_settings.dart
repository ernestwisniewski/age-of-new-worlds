final class ClientAiSettings {
  const ClientAiSettings({this.batterySaver = false});

  final bool batterySaver;

  ClientAiSettings copyWith({bool? batterySaver}) =>
      ClientAiSettings(batterySaver: batterySaver ?? this.batterySaver);

  @override
  bool operator ==(Object other) =>
      other is ClientAiSettings && other.batterySaver == batterySaver;

  @override
  int get hashCode => batterySaver.hashCode;
}
