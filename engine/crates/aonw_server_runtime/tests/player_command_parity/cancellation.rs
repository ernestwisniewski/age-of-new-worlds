use aonw_contracts::client::ClientCommandDto;
use aonw_domain::{PendingInteraction, ResearchStateUpdate};

use super::{player, support, verify_command_shape};

#[test]
fn cancellation_matches_both_runtimes_for_owned_foreign_and_submitted_choices() {
    for (owner, submitted) in [("player-1", false), ("player-2", false), ("player-1", true)] {
        let submissions = if submitted {
            vec![player("player-1")]
        } else {
            vec![]
        };
        let mut fixture = support::fixture(submissions);
        fixture.state = fixture
            .state
            .clone()
            .into_after_research(ResearchStateUpdate {
                revision: fixture.state.revision(),
                knowledge: fixture.state.knowledge().clone(),
                interaction: fixture.state.interaction().clone().with_pending(Some(
                    PendingInteraction::ResearchSelection {
                        owner_player_id: player(owner),
                    },
                )),
            })
            .expect("pending research state");
        verify_command_shape(
            &format!("cancelResearchSelection owner={owner} submitted={submitted}"),
            &fixture,
            &support::map(2),
            ClientCommandDto::CancelResearchSelection {
                expected_revision: 7,
            },
        );
    }
}
