use aonw_domain::{DiplomaticScoreEntry, PlayerId};

pub(super) fn observer_id<'entry>(
    entry: &'entry DiplomaticScoreEntry,
    attacker: &PlayerId,
) -> &'entry PlayerId {
    if entry.pair().first() == attacker {
        entry.pair().second()
    } else {
        entry.pair().first()
    }
}
