import '../../../l10n/l10n.dart';
import '../../map/read_model/player_map_view.dart';
import '../../turns/read_model/recipient_turn_view.dart';

String playerStatus(PlayerMapView player, String id, AonwLocalizations l10n) {
  if (player.turnView.outcome.isTerminal) return l10n.playerText('ended');
  if (id != player.actorPlayerId) return l10n.playerText('privateStatus');
  if (player.turnView.ownSubmitted) return l10n.playerText('submitted');
  return l10n.playerText(switch (player.turnView.ownState) {
    RecipientTurnStateView.active => 'active',
    RecipientTurnStateView.finished => 'finished',
    null => 'waiting',
  });
}
