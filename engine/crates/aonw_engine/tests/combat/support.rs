use aonw_domain::{FogOfWarState, HexCoord, PlayerFogState, PlayerId};

pub(super) fn actor_fog(
    actor: &PlayerId,
    discovered: impl IntoIterator<Item = HexCoord>,
    visible: impl IntoIterator<Item = HexCoord>,
) -> FogOfWarState {
    let discovered = discovered.into_iter().collect::<Vec<_>>();
    let visible = visible.into_iter().collect::<Vec<_>>();
    FogOfWarState::try_new(super::identity().participants().iter().map(|participant| {
        if participant.id() == actor {
            PlayerFogState::new(
                participant.id().clone(),
                discovered.iter().copied(),
                visible.iter().copied(),
            )
        } else {
            PlayerFogState::new(participant.id().clone(), [], [])
        }
    }))
    .expect("fog")
}
