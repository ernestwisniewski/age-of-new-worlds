import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_panel.dart';
import '../../../design_system/widgets/aonw_progress_indicator.dart';
import '../../map/read_model/map_view.dart';
import '../application/diplomacy_state.dart';
import '../read_model/diplomacy_view.dart';
import 'diplomacy_copy.dart';

final class DiplomacyOverlay extends StatefulWidget {
  const DiplomacyOverlay({
    required this.actorPlayerId,
    required this.view,
    required this.state,
    required this.onAction,
    super.key,
  });

  final String actorPlayerId;
  final DiplomacyView view;
  final DiplomacyState state;
  final ValueChanged<DiplomacyActionView> onAction;

  @override
  State<DiplomacyOverlay> createState() => _DiplomacyOverlayState();
}

final class _DiplomacyOverlayState extends State<DiplomacyOverlay> {
  var _open = false;

  @override
  Widget build(BuildContext context) {
    final copy = DiplomacyCopy.of(context);
    return Stack(
      children: [
        Positioned(
          top: 128,
          left: AonwSpacing.md,
          child: IconButton.filledTonal(
            key: const ValueKey('open-diplomacy'),
            tooltip: copy.open,
            onPressed: _open ? null : () => setState(() => _open = true),
            icon: const Icon(Icons.handshake),
          ),
        ),
        if (_open)
          Positioned(
            top: 72,
            left: 72,
            bottom: AonwSpacing.md,
            child: SafeArea(
              child: AonwPanel(
                semanticLabel: copy.title,
                maxWidth: 720,
                padding: const EdgeInsets.all(AonwSpacing.md),
                child: SizedBox(
                  width: 680,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              copy.title,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          IconButton(
                            key: const ValueKey('close-diplomacy'),
                            tooltip: copy.close,
                            onPressed: () => setState(() => _open = false),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      Expanded(
                        child: DiplomacyPanel(
                          actorPlayerId: widget.actorPlayerId,
                          view: widget.view,
                          state: widget.state,
                          onAction: widget.onAction,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

final class DiplomacyPanel extends StatelessWidget {
  const DiplomacyPanel({
    required this.actorPlayerId,
    required this.view,
    required this.state,
    required this.onAction,
    super.key,
  });

  final String actorPlayerId;
  final DiplomacyView view;
  final DiplomacyState state;
  final ValueChanged<DiplomacyActionView> onAction;

  @override
  Widget build(BuildContext context) {
    final copy = DiplomacyCopy.of(context);
    return ListView(
      key: const ValueKey('diplomacy-content'),
      children: [
        if (state.commandPending)
          AonwProgressIndicator(semanticLabel: copy.pending, compact: true),
        if (state.failure case final failure?)
          Text(
            copy.failure(failure),
            key: const ValueKey('diplomacy-error'),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        _DiplomacyComposer(
          relations: view.relations,
          enabled: !state.commandPending,
          onAction: onAction,
        ),
        _heading(context, copy.relations),
        if (view.relations.isEmpty) Text(copy.noContacts),
        for (final relation in view.relations)
          _RelationCard(relation: relation),
        _heading(context, copy.proposals),
        for (final proposal in view.proposals)
          _ProposalCard(
            actorPlayerId: actorPlayerId,
            proposal: proposal,
            enabled: !state.commandPending,
            onAction: onAction,
          ),
        _heading(context, copy.messages),
        for (final message in view.messages)
          _MessageCard(
            actorPlayerId: actorPlayerId,
            message: message,
            enabled: !state.commandPending,
            onAction: onAction,
          ),
        _heading(context, copy.agreements),
        for (final agreement in view.resourceTradeAgreements)
          _AgreementCard(agreement: agreement),
      ],
    );
  }
}

Widget _heading(BuildContext context, String value) => Padding(
  padding: const EdgeInsets.only(top: AonwSpacing.md),
  child: Text(value, style: Theme.of(context).textTheme.titleMedium),
);

enum _ComposerAction {
  declareWar,
  goldGift,
  friendshipProposal,
  truceProposal,
  message,
  resourceTrade,
  resourceExchange,
}

final class _DiplomacyComposer extends StatefulWidget {
  const _DiplomacyComposer({
    required this.relations,
    required this.enabled,
    required this.onAction,
  });

  final List<DiplomaticRelationView> relations;
  final bool enabled;
  final ValueChanged<DiplomacyActionView> onAction;

  @override
  State<_DiplomacyComposer> createState() => _DiplomacyComposerState();
}

final class _DiplomacyComposerState extends State<_DiplomacyComposer> {
  final _amount = TextEditingController(text: '1');
  final _duration = TextEditingController(text: '5');
  var _action = _ComposerAction.declareWar;
  var _topic = DiplomaticMessageTopicView.avoidEscalation;
  var _resource = MapResource.iron;
  var _requestedResource = MapResource.marble;
  String? _target;
  var _invalid = false;

  @override
  void dispose() {
    _amount.dispose();
    _duration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final copy = DiplomacyCopy.of(context);
    final targets = widget.relations
        .map((relation) => relation.counterpartPlayerId)
        .toList(growable: false);
    final target = targets.contains(_target) ? _target : targets.firstOrNull;
    _target = target;
    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(AonwSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(copy.compose, style: Theme.of(context).textTheme.titleMedium),
            DropdownButtonFormField<String>(
              key: const ValueKey('diplomacy-target'),
              initialValue: target,
              decoration: InputDecoration(labelText: copy.target),
              items: [
                for (final value in targets)
                  DropdownMenuItem(value: value, child: Text(value)),
              ],
              onChanged: widget.enabled
                  ? (value) => setState(() => _target = value)
                  : null,
            ),
            DropdownButtonFormField<_ComposerAction>(
              key: const ValueKey('diplomacy-action'),
              initialValue: _action,
              decoration: InputDecoration(labelText: copy.action),
              items: [
                for (final value in _ComposerAction.values)
                  DropdownMenuItem(value: value, child: Text(copy.name(value))),
              ],
              onChanged: widget.enabled
                  ? (value) => setState(() => _action = value!)
                  : null,
            ),
            ..._fields(copy),
            if (_invalid)
              Text(
                copy.invalid,
                key: const ValueKey('diplomacy-form-error'),
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                key: const ValueKey('submit-diplomacy-action'),
                onPressed: widget.enabled && target != null ? _submit : null,
                child: Text(copy.send),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _fields(DiplomacyCopy copy) => switch (_action) {
    _ComposerAction.declareWar => const [],
    _ComposerAction.goldGift || _ComposerAction.truceProposal => [
      _numberField(copy.amount, _amount, 'diplomacy-amount'),
    ],
    _ComposerAction.friendshipProposal => const [],
    _ComposerAction.message => [
      DropdownButtonFormField<DiplomaticMessageTopicView>(
        key: const ValueKey('diplomacy-topic'),
        initialValue: _topic,
        decoration: InputDecoration(labelText: copy.topic),
        items: [
          for (final value in DiplomaticMessageTopicView.values)
            DropdownMenuItem(value: value, child: Text(copy.name(value))),
        ],
        onChanged: widget.enabled
            ? (value) => setState(() => _topic = value!)
            : null,
      ),
    ],
    _ComposerAction.resourceTrade => [
      _resourceField(
        copy,
        copy.resource,
        _resource,
        (value) => _resource = value,
      ),
      _numberField(copy.goldPerTurn, _amount, 'diplomacy-amount'),
      _numberField(copy.duration, _duration, 'diplomacy-duration'),
    ],
    _ComposerAction.resourceExchange => [
      _resourceField(
        copy,
        copy.offered,
        _resource,
        (value) => _resource = value,
      ),
      _resourceField(
        copy,
        copy.requested,
        _requestedResource,
        (value) => _requestedResource = value,
      ),
      _numberField(copy.duration, _duration, 'diplomacy-duration'),
    ],
  };

  Widget _numberField(
    String label,
    TextEditingController controller,
    String key,
  ) => TextField(
    key: ValueKey(key),
    controller: controller,
    decoration: InputDecoration(labelText: label),
    keyboardType: TextInputType.number,
  );

  Widget _resourceField(
    DiplomacyCopy copy,
    String label,
    MapResource value,
    ValueChanged<MapResource> update,
  ) => DropdownButtonFormField<MapResource>(
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: [
      for (final resource in MapResource.values)
        DropdownMenuItem(value: resource, child: Text(copy.name(resource))),
    ],
    onChanged: widget.enabled ? (next) => setState(() => update(next!)) : null,
  );

  void _submit() {
    final target = _target;
    final amount = int.tryParse(_amount.text);
    final duration = int.tryParse(_duration.text);
    final action = switch (_action) {
      _ComposerAction.declareWar when target != null => DeclareWarActionView(
        target,
      ),
      _ComposerAction.goldGift
          when target != null && amount != null && amount > 0 =>
        SendGoldGiftActionView(targetPlayerId: target, amount: amount),
      _ComposerAction.friendshipProposal when target != null =>
        SendDiplomaticProposalActionView(
          targetPlayerId: target,
          kind: DiplomaticProposalKindView.friendship,
          goldPayment: 0,
        ),
      _ComposerAction.truceProposal
          when target != null && amount != null && amount >= 0 =>
        SendDiplomaticProposalActionView(
          targetPlayerId: target,
          kind: DiplomaticProposalKindView.truce,
          goldPayment: amount,
        ),
      _ComposerAction.message when target != null =>
        SendDiplomaticMessageActionView(targetPlayerId: target, topic: _topic),
      _ComposerAction.resourceTrade
          when target != null &&
              amount != null &&
              amount >= 0 &&
              duration != null &&
              duration > 0 =>
        OpenResourceTradeActionView(
          targetPlayerId: target,
          resource: _resource,
          goldPerTurn: amount,
          durationTurns: duration,
        ),
      _ComposerAction.resourceExchange
          when target != null &&
              _resource != _requestedResource &&
              duration != null &&
              duration > 0 =>
        OpenResourceExchangeActionView(
          targetPlayerId: target,
          offeredResource: _resource,
          requestedResource: _requestedResource,
          durationTurns: duration,
        ),
      _ => null,
    };
    if (action == null) {
      setState(() => _invalid = true);
      return;
    }
    setState(() => _invalid = false);
    widget.onAction(action);
  }
}

final class _RelationCard extends StatelessWidget {
  const _RelationCard({required this.relation});

  final DiplomaticRelationView relation;

  @override
  Widget build(BuildContext context) {
    final copy = DiplomacyCopy.of(context);
    return Card.outlined(
      key: ValueKey(('diplomatic-relation', relation.counterpartPlayerId)),
      child: ListTile(
        title: Text(relation.counterpartPlayerId),
        subtitle: Text(
          '${copy.name(relation.status)} · ${relation.relationScore}'
          '${relation.statusExpiresOnTurn == null ? '' : ' · ${relation.statusExpiresOnTurn}'}',
        ),
      ),
    );
  }
}

final class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    required this.actorPlayerId,
    required this.proposal,
    required this.enabled,
    required this.onAction,
  });

  final String actorPlayerId;
  final DiplomaticProposalView proposal;
  final bool enabled;
  final ValueChanged<DiplomacyActionView> onAction;

  @override
  Widget build(BuildContext context) {
    final copy = DiplomacyCopy.of(context);
    final incoming = proposal.toPlayerId == actorPlayerId;
    return Card.outlined(
      key: ValueKey(('diplomatic-proposal', proposal.id)),
      child: Padding(
        padding: const EdgeInsets.all(AonwSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${copy.name(proposal.kind)} · ${proposal.id}'),
            Text('${proposal.fromPlayerId} → ${proposal.toPlayerId}'),
            Text(
              '${proposal.createdTurn}–${proposal.expiresOnTurn} · ${proposal.goldPayment}',
            ),
            if (incoming)
              Wrap(
                spacing: AonwSpacing.sm,
                children: [
                  FilledButton(
                    key: ValueKey(('accept-proposal', proposal.id)),
                    onPressed: enabled
                        ? () => onAction(
                            RespondDiplomaticProposalActionView(
                              proposalId: proposal.id,
                              accepted: true,
                            ),
                          )
                        : null,
                    child: Text(copy.accept),
                  ),
                  OutlinedButton(
                    key: ValueKey(('reject-proposal', proposal.id)),
                    onPressed: enabled
                        ? () => onAction(
                            RespondDiplomaticProposalActionView(
                              proposalId: proposal.id,
                              accepted: false,
                            ),
                          )
                        : null,
                    child: Text(copy.reject),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

final class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.actorPlayerId,
    required this.message,
    required this.enabled,
    required this.onAction,
  });

  final String actorPlayerId;
  final DiplomaticMessageView message;
  final bool enabled;
  final ValueChanged<DiplomacyActionView> onAction;

  @override
  Widget build(BuildContext context) {
    final copy = DiplomacyCopy.of(context);
    final incoming =
        message.toPlayerId == actorPlayerId && message.response == null;
    return Card.outlined(
      key: ValueKey(('diplomatic-message', message.id)),
      child: Padding(
        padding: const EdgeInsets.all(AonwSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${copy.name(message.topic)} · ${copy.name(message.category)}',
            ),
            Text('${message.fromPlayerId} → ${message.toPlayerId}'),
            Text(
              '${message.createdTurn}–${message.expiresOnTurn} · '
              '${message.response == null ? '-' : copy.name(message.response!)} · '
              '${message.relationScoreDelta}',
            ),
            if (incoming)
              Wrap(
                spacing: AonwSpacing.xs,
                children: [
                  for (final response in DiplomaticMessageResponseView.values)
                    OutlinedButton(
                      key: ValueKey((
                        'respond-message',
                        message.id,
                        response.name,
                      )),
                      onPressed: enabled
                          ? () => onAction(
                              RespondDiplomaticMessageActionView(
                                messageId: message.id,
                                response: response,
                              ),
                            )
                          : null,
                      child: Text(copy.name(response)),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

final class _AgreementCard extends StatelessWidget {
  const _AgreementCard({required this.agreement});

  final ResourceTradeAgreementView agreement;

  @override
  Widget build(BuildContext context) {
    final copy = DiplomacyCopy.of(context);
    return Card.outlined(
      key: ValueKey(('resource-trade-agreement', agreement.id)),
      child: ListTile(
        title: Text('${copy.name(agreement.resource)} · ${agreement.id}'),
        subtitle: Text(
          '${agreement.exporterPlayerId} → ${agreement.importerPlayerId} · '
          '${agreement.amountPerTurn} · ${agreement.goldPerTurn} · '
          '${agreement.remainingTurns}',
        ),
      ),
    );
  }
}
