use aonw_domain::{FogOfWar, HexCoord, PlayerFog, PlayerId};

pub(super) fn actor_fog(
    actor: &PlayerId,
    discovered: impl IntoIterator<Item = HexCoord>,
    visible: impl IntoIterator<Item = HexCoord>,
) -> FogOfWar {
    let discovered = discovered.into_iter().collect::<Vec<_>>();
    let visible = visible.into_iter().collect::<Vec<_>>();
    FogOfWar::try_new(super::identity().participants().iter().map(|participant| {
        if participant.id() == actor {
            PlayerFog::new(
                participant.id().clone(),
                discovered.iter().copied(),
                visible.iter().copied(),
            )
        } else {
            PlayerFog::new(participant.id().clone(), [], [])
        }
    }))
    .expect("fog")
}
