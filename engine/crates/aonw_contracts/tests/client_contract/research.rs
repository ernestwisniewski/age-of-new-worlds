use std::collections::BTreeMap;

use aonw_contracts::TechnologyIdDto;
use aonw_contracts::client::{
    ClientCommandDto, ClientQueryDto, ClientQueryResultDto, ClientRequestBodyDto,
    ClientResponseBodyDto, ResearchOptionDto, ScienceYieldBreakdownDto, ScienceYieldSourceDto,
    ScienceYieldSourceKindDto, TechnologyAvailabilityDto,
};

use super::stamp;

#[test]
fn cancellation_accepts_only_a_revision_bound_actor_free_payload() {
    let command = serde_json::json!({
        "type": "cancelResearchSelection",
        "expectedRevision": 8,
    });
    assert!(serde_json::from_value::<ClientCommandDto>(command.clone()).is_ok());
    for field in ["actorPlayerId", "playerId", "technologyId", "unexpected"] {
        let mut invalid = command.clone();
        invalid[field] = serde_json::json!("player-1");
        assert!(serde_json::from_value::<ClientCommandDto>(invalid).is_err());
    }
    for revision in [
        serde_json::Value::Null,
        serde_json::json!(-1),
        serde_json::json!("8"),
    ] {
        let mut invalid = command.clone();
        invalid["expectedRevision"] = revision;
        assert!(serde_json::from_value::<ClientCommandDto>(invalid).is_err());
    }
    assert!(
        serde_json::from_str::<ClientCommandDto>(r#"{"type":"cancelResearchSelection"}"#,).is_err()
    );
    assert!(
        serde_json::from_str::<ClientCommandDto>(
            r#"{"type":"cancelResearchSelection","expectedRevision":8,"expectedRevision":8}"#,
        )
        .is_err()
    );
}

pub(super) fn requests() -> [ClientRequestBodyDto; 3] {
    [
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::CancelResearchSelection {
                expected_revision: 8,
            },
        },
        ClientRequestBodyDto::Query {
            query: ClientQueryDto::ResearchOptions {
                expected_revision: 8,
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::SelectTechnology {
                expected_revision: 8,
                technology_id: TechnologyIdDto::Agriculture,
            },
        },
    ]
}

pub(super) fn response() -> ClientResponseBodyDto {
    ClientResponseBodyDto::Query {
        result: ClientQueryResultDto::ResearchOptions {
            stamp: stamp(),
            player_id: "player-1".to_owned(),
            active_technology_id: None,
            science_overflow: 3,
            science_yield: ScienceYieldBreakdownDto {
                total: 2,
                by_city_id: BTreeMap::from([("capital".to_owned(), 2)]),
                sources: vec![ScienceYieldSourceDto {
                    city_id: "capital".to_owned(),
                    amount: 2,
                    kind: ScienceYieldSourceKindDto::CityScience,
                }],
            },
            options: vec![ResearchOptionDto {
                technology_id: TechnologyIdDto::Agriculture,
                availability: TechnologyAvailabilityDto::Available,
                effective_cost: 10,
                progress: 2,
                boost_discount_basis_points: 2_500,
                prerequisites: Vec::new(),
                blocked_by: Vec::new(),
                unlocks: Vec::new(),
            }],
        },
    }
}
