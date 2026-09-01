enum MapViewMode {
  graphic,
  tile;

  bool get showsReference => this == MapViewMode.graphic;

  bool get showsTerrain => this == MapViewMode.tile;

  bool get showsExtrusion => this == MapViewMode.tile;

  MapViewMode effectiveFor({required bool hasReference}) =>
      this == MapViewMode.graphic && !hasReference ? MapViewMode.tile : this;

  MapViewMode get toggled => switch (this) {
    MapViewMode.graphic => MapViewMode.tile,
    MapViewMode.tile => MapViewMode.graphic,
  };
}
