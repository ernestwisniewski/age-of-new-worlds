import 'package:flutter/foundation.dart';

@immutable
final class ClientCityPlanningSettings {
  const ClientCityPlanningSettings({
    this.showSites = false,
    this.showGrowth = false,
  });

  final bool showSites;
  final bool showGrowth;

  ClientCityPlanningSettings copyWith({bool? showSites, bool? showGrowth}) =>
      ClientCityPlanningSettings(
        showSites: showSites ?? this.showSites,
        showGrowth: showGrowth ?? this.showGrowth,
      );

  @override
  bool operator ==(Object other) =>
      other is ClientCityPlanningSettings &&
      other.showSites == showSites &&
      other.showGrowth == showGrowth;
  @override
  int get hashCode => Object.hash(showSites, showGrowth);
}
