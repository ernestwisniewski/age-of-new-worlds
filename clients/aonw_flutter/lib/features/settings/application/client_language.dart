enum ClientLanguage {
  system('system'),
  polish('pl'),
  english('en'),
  french('fr'),
  german('de'),
  spanish('es'),
  dutch('nl');

  const ClientLanguage(this.storageValue);

  final String storageValue;

  String? get languageCode => this == system ? null : storageValue;
}
