use std::collections::BTreeMap;

use aonw_contracts::{
    AiDifficultyDto, AiPersonaDto, AiPlayerDto, AiStrategyIdDto, ArmyTroopDto, CityBuildingTypeDto,
    CityConquestActionDto, CityDto, CityFoundingDraftDto, CityFoundingJobDto,
    CityProductionQueueDto, CityProductionTargetDto, CitySpecializationTypeDto, CoordinateDto,
    DiplomacyStateDto, DiplomaticMessageCategoryDto, DiplomaticMessageDto,
    DiplomaticMessageResponseDto, DiplomaticMessageTopicDto, DiplomaticProposalDto,
    DiplomaticProposalKindDto, DiplomaticRelationChangeReasonDto, DiplomaticRelationDto,
    DiplomaticRelationStatusDto, DiplomaticScoreChangeReasonDto, DiplomaticScoreEntryDto,
    EconomyStateDto, FieldImprovementDto, FieldImprovementKindDto, GameModeDto,
    GameOutcomeConditionDto, GameOutcomeDto, GameStateDto, InitialResourceDistributionDto,
    InitialResourcePlacementDto, IntendedAttackDto, InteractionStateDto, MapObjectiveHoldStateDto,
    MatchIdentityDto, MatchRulesDto, MerchantTradeRouteDto, MovementStepDto, ParticipantDto,
    PendingInteractionDto, PlayerCountryDto, PlayerFogDto, PlayerKindDto, PlayerPairDto,
    PlayerResearchStateDto, PlayerTurnStateDto, QueuedMovePathDto, ResearchStateDto,
    ResourceTradeAgreementDto, ResourceTypeDto, RuleValueDto, StrategicResourceStockpileDto,
    TechnologyIdDto, TransportConditionDto, TransportSegmentDto, TransportSegmentKindDto,
    TroopKindDto, TurnLifecycleDto, TurnModeDto, UnitActivityDto, UnitDto, UnitKindDto,
    UnitOccupancyPolicyDto, UnitPostureDto, WonderRegistryDto, WonderTypeDto, WorkerJobDto,
    WorldArtifactDto, WorldArtifactLocationDto, WorldArtifactTypeDto,
};

pub(super) fn complete_state_contract() -> GameStateDto {
    GameStateDto {
        revision: 9,
        turn: 3,
        match_identity: complete_match_identity(),
        turn_lifecycle: complete_turn_lifecycle(),
        economy: complete_economy(),
        research: ResearchStateDto {
            players: BTreeMap::from([(
                "player-1".to_owned(),
                PlayerResearchStateDto {
                    unlocked_technology_ids: vec![TechnologyIdDto::Logistics],
                    active_technology_id: Some(TechnologyIdDto::Agriculture),
                    progress_by_technology_id: BTreeMap::from([(TechnologyIdDto::Agriculture, 4)]),
                    science_overflow: 3,
                },
            )]),
        },
        wonder_registry: WonderRegistryDto(BTreeMap::from([
            (WonderTypeDto::CentralBank, "player-2".to_owned()),
            (WonderTypeDto::GreatLibrary, "player-1".to_owned()),
            (WonderTypeDto::GreatWall, "player-1".to_owned()),
        ])),
        intended_attacks: vec![IntendedAttackDto {
            attacker_unit_id: "unit-1".to_owned(),
            defender_col: 2,
            defender_row: 1,
            declared_at_tick: 41,
            declaring_player_id: "player-1".to_owned(),
            city_conquest_action: CityConquestActionDto::Destroy,
        }],
        cols: 5,
        rows: 5,
        occupancy_policy: UnitOccupancyPolicyDto::FriendlyStacking,
        units: vec![complete_unit()],
        cities: vec![complete_city(), secondary_city()],
        artifacts: vec![
            WorldArtifactDto {
                id: "artifact-1".to_owned(),
                artifact_type: WorldArtifactTypeDto::AstronomersTablets,
                location: WorldArtifactLocationDto::Excavation {
                    unit_id: "unit-1".to_owned(),
                    coordinate: coordinate(1, 1),
                    remaining_turns: 2,
                },
            },
            WorldArtifactDto {
                id: "artifact-2".to_owned(),
                artifact_type: WorldArtifactTypeDto::HeroSword,
                location: WorldArtifactLocationDto::Map {
                    coordinate: coordinate(4, 2),
                },
            },
        ],
        field_improvements: vec![FieldImprovementDto {
            coordinate: coordinate(0, 1),
            kind: FieldImprovementKindDto::Farm,
            built_by_city_id: Some("city-1".to_owned()),
        }],
        interaction: InteractionStateDto {
            city_founding_draft: Some(CityFoundingDraftDto {
                unit_id: "unit-1".to_owned(),
                owner_player_id: "player-1".to_owned(),
                center: coordinate(2, 2),
                controlled_hexes: vec![coordinate(2, 3)],
            }),
            pending: Some(PendingInteractionDto::WorkerActionSelection {
                owner_player_id: "player-1".to_owned(),
                unit_id: "unit-1".to_owned(),
                improvement: Some(FieldImprovementKindDto::Mine),
            }),
        },
        fog_of_war: complete_fog(),
        diplomacy: complete_diplomacy(),
        resource_trade_agreements: complete_resource_trades(),
        domination_hold_turns_by_player_id: BTreeMap::from([("player-1".to_owned(), 2)]),
        cultural_victory_hold_turns_by_player_id: BTreeMap::from([("player-2".to_owned(), 4)]),
        map_objective_hold_states: vec![MapObjectiveHoldStateDto {
            objective_id: "strategic-pass-1".to_owned(),
            player_id: "player-1".to_owned(),
            hold_turns: 3,
        }],
        outcome: GameOutcomeDto {
            condition: GameOutcomeConditionDto::Ongoing,
            winner_player_id: None,
            score_by_player_id: BTreeMap::new(),
        },
        transport_network: vec![TransportSegmentDto {
            coordinate: coordinate(1, 1),
            kind: TransportSegmentKindDto::Road,
            condition: TransportConditionDto::Operational,
            built_by_player_id: "player-1".to_owned(),
            built_by_city_id: Some("city-1".to_owned()),
        }],
    }
}

fn complete_fog() -> Vec<PlayerFogDto> {
    vec![
        PlayerFogDto {
            player_id: "player-1".to_owned(),
            discovered_hexes: vec![coordinate(0, 0), coordinate(1, 1)],
            visible_hexes: vec![coordinate(1, 1)],
        },
        PlayerFogDto {
            player_id: "player-2".to_owned(),
            discovered_hexes: vec![coordinate(4, 4)],
            visible_hexes: vec![coordinate(4, 4)],
        },
    ]
}

fn complete_diplomacy() -> DiplomacyStateDto {
    DiplomacyStateDto {
        contacts: vec![PlayerPairDto {
            first_player_id: "player-1".to_owned(),
            second_player_id: "player-2".to_owned(),
        }],
        relations: vec![DiplomaticRelationDto {
            player_a_id: "player-1".to_owned(),
            player_b_id: "player-2".to_owned(),
            status: DiplomaticRelationStatusDto::Truce,
            relation_score: 12,
            status_expires_on_turn: Some(20),
            last_changed_turn: Some(3),
            last_change_reason: Some(DiplomaticRelationChangeReasonDto::ProposalAccepted),
        }],
        pending_proposals: vec![DiplomaticProposalDto {
            id: "proposal-1".to_owned(),
            from_player_id: "player-1".to_owned(),
            to_player_id: "player-2".to_owned(),
            kind: DiplomaticProposalKindDto::Friendship,
            created_turn: 3,
            expires_on_turn: 8,
            gold_payment: 0,
        }],
        messages: vec![DiplomaticMessageDto {
            id: "message-1".to_owned(),
            from_player_id: "player-2".to_owned(),
            to_player_id: "player-1".to_owned(),
            topic: DiplomaticMessageTopicDto::BlockedRoutes,
            category: DiplomaticMessageCategoryDto::Request,
            created_turn: 3,
            expires_on_turn: 8,
            response: Some(DiplomaticMessageResponseDto::Conciliatory),
            responded_turn: Some(4),
            relation_score_delta: 12,
            relation_score_after: Some(24),
            promise_due_turn: Some(7),
            promise_broken: false,
        }],
        score_history: vec![DiplomaticScoreEntryDto {
            player_a_id: "player-1".to_owned(),
            player_b_id: "player-2".to_owned(),
            turn: 4,
            delta: 12,
            score_after: 24,
            reason: DiplomaticScoreChangeReasonDto::MessageResponse,
            source_id: Some("message-1".to_owned()),
        }],
    }
}

fn complete_resource_trades() -> Vec<ResourceTradeAgreementDto> {
    vec![ResourceTradeAgreementDto {
        id: "trade-1".to_owned(),
        exporter_player_id: "player-2".to_owned(),
        importer_player_id: "player-1".to_owned(),
        resource: ResourceTypeDto::Horses,
        gold_per_turn: 3,
        remaining_turns: 5,
        amount_per_turn: 2,
        exchange_group_id: Some("exchange-1".to_owned()),
    }]
}

fn complete_city() -> CityDto {
    CityDto {
        id: "city-1".to_owned(),
        owner_player_id: "player-1".to_owned(),
        founding_owner_player_id: Some("player-2".to_owned()),
        name: "Warsaw".to_owned(),
        population: 7,
        stored_food: 3,
        max_hexes: 10,
        territory_radius: 3,
        center: coordinate(0, 0),
        controlled_hexes: vec![coordinate(0, 1)],
        worked_hexes: vec![coordinate(0, 1)],
        buildings: vec![CityBuildingTypeDto::Granary, CityBuildingTypeDto::Workshop],
        wonders: vec![WonderTypeDto::GreatLibrary],
        production_queue: Some(CityProductionQueueDto {
            target: CityProductionTargetDto::Building {
                building_type: CityBuildingTypeDto::Factory,
            },
            invested_production: 23,
            resource_allocation: StrategicResourceStockpileDto(BTreeMap::from([(
                ResourceTypeDto::Oil,
                2,
            )])),
        }),
        production_overflow: 5,
        specialization: Some(CitySpecializationTypeDto::Science),
        preferred_expansion_hex: Some(coordinate(1, 0)),
        hit_points: Some(41),
    }
}

fn secondary_city() -> CityDto {
    CityDto {
        id: "city-2".to_owned(),
        owner_player_id: "player-1".to_owned(),
        founding_owner_player_id: None,
        name: "Gdansk".to_owned(),
        population: 3,
        stored_food: 0,
        max_hexes: 6,
        territory_radius: 2,
        center: coordinate(4, 4),
        controlled_hexes: vec![coordinate(4, 3)],
        worked_hexes: Vec::new(),
        buildings: Vec::new(),
        wonders: Vec::new(),
        production_queue: None,
        production_overflow: 0,
        specialization: None,
        preferred_expansion_hex: None,
        hit_points: None,
    }
}

fn complete_economy() -> EconomyStateDto {
    EconomyStateDto {
        player_gold: BTreeMap::from([("player-1".to_owned(), 100), ("player-2".to_owned(), 4)]),
        player_war_weariness: BTreeMap::from([("player-1".to_owned(), 3)]),
        player_stability_net: BTreeMap::from([("player-2".to_owned(), -2)]),
        strategic_resources: BTreeMap::from([(
            "player-1".to_owned(),
            StrategicResourceStockpileDto(BTreeMap::from([
                (ResourceTypeDto::Oil, 7),
                (ResourceTypeDto::Aluminium, 2),
            ])),
        )]),
        initial_resource_distribution: InitialResourceDistributionDto {
            seed: -31,
            placements: vec![
                InitialResourcePlacementDto {
                    col: 3,
                    row: 3,
                    resource: ResourceTypeDto::Wheat,
                },
                InitialResourcePlacementDto {
                    col: 4,
                    row: 2,
                    resource: ResourceTypeDto::Oil,
                },
            ],
        },
    }
}

fn complete_match_identity() -> MatchIdentityDto {
    let mut rules = MatchRulesDto::default();
    rules.balance.insert(
        "economy".to_owned(),
        RuleValueDto::Object(BTreeMap::from([(
            "growth".to_owned(),
            RuleValueDto::Number(serde_json::Number::from(2)),
        )])),
    );
    MatchIdentityDto {
        match_rules: rules,
        participants: vec![
            ParticipantDto {
                id: "player-1".to_owned(),
                name: "Ada".to_owned(),
                color_value: 0xff3d_5fa8,
                country: PlayerCountryDto::Poland,
                kind: PlayerKindDto::Human,
                ai: None,
            },
            ParticipantDto {
                id: "player-2".to_owned(),
                name: "Turing".to_owned(),
                color_value: 0xffb8_3a3a,
                country: PlayerCountryDto::UnitedKingdom,
                kind: PlayerKindDto::Ai,
                ai: Some(AiPlayerDto {
                    strategy_id: AiStrategyIdDto::Mcts,
                    difficulty: AiDifficultyDto::Hard,
                    persona: AiPersonaDto::Scientific,
                    seed: 41,
                }),
            },
        ],
        game_mode: GameModeDto::Multiplayer,
        turn_mode: Some(TurnModeDto::Simultaneous),
    }
}

fn complete_turn_lifecycle() -> TurnLifecycleDto {
    TurnLifecycleDto {
        turn_states_by_player_id: BTreeMap::from([
            ("player-1".to_owned(), PlayerTurnStateDto::Active),
            ("player-2".to_owned(), PlayerTurnStateDto::Finished),
        ]),
        required_submission_player_ids: vec!["player-1".to_owned(), "player-2".to_owned()],
        submitted_player_ids: vec!["player-2".to_owned()],
        timeout_streaks_by_player_id: BTreeMap::from([("player-2".to_owned(), 2)]),
        afk_player_ids: vec!["player-2".to_owned()],
        kicked_player_ids: Vec::new(),
        resigned_player_ids: Vec::new(),
        turn_started_at: Some("2026-08-23T12:34:56.123456Z".to_owned()),
    }
}

fn complete_unit() -> UnitDto {
    UnitDto {
        id: "unit-1".to_owned(),
        owner_player_id: "player-1".to_owned(),
        kind: UnitKindDto::Worker,
        name: "unit.worker".to_owned(),
        col: 1,
        row: 1,
        movement_units: 4,
        army: vec![ArmyTroopDto {
            kind: TroopKindDto::Settler,
            count: 2,
        }],
        queued_path: Some(QueuedMovePathDto {
            target_col: 2,
            target_row: 1,
            steps: vec![movement_step(1, 1, 0, 0), movement_step(2, 1, 2, 2)],
        }),
        merchant_trade_route: Some(MerchantTradeRouteDto {
            origin_city_id: "city-1".to_owned(),
            destination_city_id: "city-2".to_owned(),
            steps: vec![movement_step(1, 1, 0, 0), movement_step(2, 1, 2, 2)],
            transport_network_fingerprint: "network-1".to_owned(),
        }),
        activity: UnitActivityDto {
            worker_job: Some(WorkerJobDto::FieldImprovement {
                target: coordinate(1, 1),
                improvement: FieldImprovementKindDto::Farm,
                remaining_turns: 1,
                total_turns: 3,
            }),
            city_founding_job: Some(CityFoundingJobDto {
                center: coordinate(2, 2),
                controlled_hexes: vec![coordinate(2, 3)],
                remaining_turns: 2,
                total_turns: 4,
            }),
            worker_assignment: Some(coordinate(1, 1)),
            excavating_artifact_id: Some("artifact-1".to_owned()),
        },
        worker_build_charges: 4,
        hit_points: Some(7),
        experience_points: 11,
        posture: UnitPostureDto::AutoWorking,
        carried_artifact_id: None,
    }
}

pub(super) const fn coordinate(col: i32, row: i32) -> CoordinateDto {
    CoordinateDto { col, row }
}

fn movement_step(
    col: i32,
    row: i32,
    enter_cost_units: u32,
    cumulative_cost_units: u32,
) -> MovementStepDto {
    MovementStepDto {
        col,
        row,
        enter_cost_units,
        cumulative_cost_units,
    }
}
