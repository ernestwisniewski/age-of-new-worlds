import '../../../l10n/l10n.dart';
import '../../map/read_model/player_map_view.dart';
import 'resource_strip.dart';
import 'victory_status_copy.dart';

part 'resource_economy_details.dart';
part 'resource_progress_details.dart';

typedef ResourceDetail = ({String label, String value, bool warning});

List<ResourceDetail> resourceDetails(
  PlayerMapView player,
  ResourcePopup kind,
  AonwLocalizations l10n,
) => switch (kind) {
  ResourcePopup.gold => _goldDetails(player, l10n),
  ResourcePopup.science => _scienceDetails(player, l10n),
  ResourcePopup.stability => _stabilityDetails(player, l10n),
  ResourcePopup.resources => _strategicDetails(player, l10n),
  ResourcePopup.turn => _turnDetails(player, l10n),
  ResourcePopup.victory => _victoryDetails(player, l10n),
};

ResourceDetail _detail(AonwLocalizations l10n, String key, Object value) =>
    (label: l10n.resourceText(key), value: '$value', warning: key == 'warning');

String _cityName(PlayerMapView player, String id, AonwLocalizations l10n) =>
    player.cities.where((city) => city.id == id).firstOrNull?.name ??
    l10n.cityText('title');
