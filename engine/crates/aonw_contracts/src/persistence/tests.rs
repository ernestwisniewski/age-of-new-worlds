use super::{
    MAX_SAVE_GAME_JSON_BYTES, PersistenceCodecError, ReplayCommandDto, ReplayEventDto,
    ReplayLogDto, SaveGameDto,
};

#[test]
fn strict_save_codec_rejects_unknown_duplicate_and_oversized_input() {
    let base = r#"{"formatVersion":2,"behaviorFingerprint":"b","mapId":"m","mapHash":"h","rulesetId":"r","rulesetHash":"h","actorPlayerId":"p","eventOffset":0,"stateDigest":"d","state":{"revision":0,"turn":0,"matchIdentity":{"matchRules":{"gameLength":{"kind":"unlimited","targetMinutes":null,"turnLimit":null,"paceProfile":"unlimited","scoreFallbackEnabled":false},"victory":{"conquestEnabled":true,"dominationEnabled":true,"dominationControlPercent":60,"dominationHoldTurns":5,"scoreFallbackEnabled":false,"turnLimit":null,"hardTimeLimitMinutes":null,"culturalEnabled":true,"culturalRequiredArtifacts":6,"culturalHoldTurns":5},"balance":{}},"participants":[],"gameMode":"hotSeat"},"turnLifecycle":{"turnStatesByPlayerId":{},"requiredSubmissionPlayerIds":[],"submittedPlayerIds":[],"timeoutStreaksByPlayerId":{},"afkPlayerIds":[],"kickedPlayerIds":[],"turnStartedAt":null},"economy":{"playerGold":{},"playerWarWeariness":{},"playerStabilityNet":{},"strategicResources":{},"initialResourceDistribution":{"seed":0,"placements":[]}},"research":{"players":{}},"wonderRegistry":{},"intendedAttacks":[],"cols":1,"rows":1,"occupancyPolicy":"exclusive","units":[],"cities":[],"artifacts":[],"fieldImprovements":[],"interaction":{"cityFoundingDraft":null,"pending":null},"fogOfWar":[],"diplomacy":{"contacts":[],"relations":[],"pendingProposals":[],"messages":[],"scoreHistory":[]},"resourceTradeAgreements":[],"dominationHoldTurnsByPlayerId":{},"culturalVictoryHoldTurnsByPlayerId":{},"mapObjectiveHoldStates":[],"outcome":{"condition":"ongoing","winnerPlayerId":null,"scoreByPlayerId":{}},"transportNetwork":[]}}"#;
    assert!(SaveGameDto::from_json(base).is_ok());
    let unknown = base.replacen("\"state\":", "\"extra\":true,\"state\":", 1);
    assert!(SaveGameDto::from_json(&unknown).is_err());
    let duplicate = base.replacen("\"mapId\":\"m\",", "\"mapId\":\"m\",\"mapId\":\"m\",", 1);
    assert!(SaveGameDto::from_json(&duplicate).is_err());
    let exact_boundary = format!(
        "{base}{}",
        " ".repeat(MAX_SAVE_GAME_JSON_BYTES - base.len())
    );
    assert_eq!(exact_boundary.len(), MAX_SAVE_GAME_JSON_BYTES);
    assert!(SaveGameDto::from_json(&exact_boundary).is_ok());

    let oversized = format!("{exact_boundary} ");
    assert!(matches!(
        SaveGameDto::from_json(&oversized),
        Err(PersistenceCodecError::TooLarge {
            actual,
            maximum: MAX_SAVE_GAME_JSON_BYTES,
        }) if actual == MAX_SAVE_GAME_JSON_BYTES + 1
    ));
}

#[test]
fn strict_replay_codec_rejects_unknown_and_duplicate_fields() {
    let base = r#"{"formatVersion":2,"behaviorFingerprint":"b","mapId":"m","mapHash":"h","rulesetId":"r","rulesetHash":"h","actorPlayerId":"p","segments":[{"initialEventOffset":0,"initialStateDigest":"d","initialState":{"revision":0,"turn":0,"matchIdentity":{"matchRules":{"gameLength":{"kind":"unlimited","targetMinutes":null,"turnLimit":null,"paceProfile":"unlimited","scoreFallbackEnabled":false},"victory":{"conquestEnabled":true,"dominationEnabled":true,"dominationControlPercent":60,"dominationHoldTurns":5,"scoreFallbackEnabled":false,"turnLimit":null,"hardTimeLimitMinutes":null,"culturalEnabled":true,"culturalRequiredArtifacts":6,"culturalHoldTurns":5},"balance":{}},"participants":[],"gameMode":"hotSeat"},"turnLifecycle":{"turnStatesByPlayerId":{},"requiredSubmissionPlayerIds":[],"submittedPlayerIds":[],"timeoutStreaksByPlayerId":{},"afkPlayerIds":[],"kickedPlayerIds":[],"turnStartedAt":null},"economy":{"playerGold":{},"playerWarWeariness":{},"playerStabilityNet":{},"strategicResources":{},"initialResourceDistribution":{"seed":0,"placements":[]}},"research":{"players":{}},"wonderRegistry":{},"intendedAttacks":[],"cols":1,"rows":1,"occupancyPolicy":"exclusive","units":[],"cities":[],"artifacts":[],"fieldImprovements":[],"interaction":{"cityFoundingDraft":null,"pending":null},"fogOfWar":[],"diplomacy":{"contacts":[],"relations":[],"pendingProposals":[],"messages":[],"scoreHistory":[]},"resourceTradeAgreements":[],"dominationHoldTurnsByPlayerId":{},"culturalVictoryHoldTurnsByPlayerId":{},"mapObjectiveHoldStates":[],"outcome":{"condition":"ongoing","winnerPlayerId":null,"scoreByPlayerId":{}},"transportNetwork":[]},"entries":[]}]}"#;
    assert!(ReplayLogDto::from_json(base).is_ok());
    let unknown = base.replacen("\"entries\":", "\"extra\":true,\"entries\":", 1);
    assert!(ReplayLogDto::from_json(&unknown).is_err());
    let duplicate = base.replacen("\"mapId\":\"m\",", "\"mapId\":\"m\",\"mapId\":\"m\",", 1);
    assert!(ReplayLogDto::from_json(&duplicate).is_err());
    let mut empty = ReplayLogDto::from_json(base).expect("archive");
    empty.segments.clear();
    assert!(empty.to_json().is_err());
}

#[test]
fn every_unit_action_command_has_a_strict_wire_shape() {
    for kind in ["cancelUnitAction", "skipUnitTurn", "fortifyUnit"] {
        let json = format!(r#"{{"type":"{kind}","expectedRevision":7,"unitId":"unit-1"}}"#);
        assert!(serde_json::from_str::<ReplayCommandDto>(&json).is_ok());
        let unknown = json.replacen('}', ",\"unknown\":true}", 1);
        assert!(serde_json::from_str::<ReplayCommandDto>(&unknown).is_err());
    }
}

#[test]
fn every_logistics_command_has_a_strict_wire_shape() {
    let commands = [
        r#"{"type":"autoExploreUnit","expectedRevision":7,"unitId":"scout-1"}"#,
        r#"{"type":"assignMerchantTradeRoute","expectedRevision":7,"unitId":"merchant-1","destinationCityId":"city-2"}"#,
        r#"{"type":"moveMerchantToCity","expectedRevision":7,"unitId":"merchant-1","destinationCityId":"city-2"}"#,
        r#"{"type":"detachTroop","expectedRevision":7,"unitId":"army-1","troopKind":"archer"}"#,
    ];
    for json in commands {
        assert!(serde_json::from_str::<ReplayCommandDto>(json).is_ok());
        let unknown = json.replacen('}', ",\"unexpectedField\":true}", 1);
        assert!(serde_json::from_str::<ReplayCommandDto>(&unknown).is_err());
    }
}

#[test]
fn every_production_command_has_a_strict_wire_shape() {
    let commands = [
        r#"{"type":"startBuilding","expectedRevision":7,"cityId":"city-1","building":"workshop"}"#,
        r#"{"type":"startUnitProduction","expectedRevision":7,"cityId":"city-1","unit":"warrior","resourceOptionIndex":null}"#,
        r#"{"type":"startCityProject","expectedRevision":7,"cityId":"city-1","project":"research"}"#,
        r#"{"type":"startWonder","expectedRevision":7,"cityId":"city-1","wonder":"greatLibrary"}"#,
        r#"{"type":"setCitySpecialization","expectedRevision":7,"cityId":"city-1","specialization":"industry"}"#,
        r#"{"type":"rushProduction","expectedRevision":7,"cityId":"city-1"}"#,
    ];
    for json in commands {
        assert!(serde_json::from_str::<ReplayCommandDto>(json).is_ok());
        let unknown = json.replacen('}', ",\"unexpectedField\":true}", 1);
        assert!(serde_json::from_str::<ReplayCommandDto>(&unknown).is_err());
    }
}

#[test]
fn diplomacy_commands_have_strict_wire_shapes() {
    let commands = [
        r#"{"type":"declareWar","expectedRevision":7,"targetPlayerId":"player-2"}"#,
        r#"{"type":"sendGoldGift","expectedRevision":7,"targetPlayerId":"player-2","amount":10}"#,
        r#"{"type":"sendDiplomaticProposal","expectedRevision":7,"targetPlayerId":"player-2","kind":"truce","proposalId":null,"goldPayment":5}"#,
        r#"{"type":"respondDiplomaticProposal","expectedRevision":8,"proposalId":"proposal-1","accepted":true}"#,
        r#"{"type":"sendDiplomaticMessage","expectedRevision":8,"targetPlayerId":"player-2","topic":"withdrawScouts","messageId":null}"#,
        r#"{"type":"respondDiplomaticMessage","expectedRevision":9,"messageId":"message-1","response":"conciliatory"}"#,
    ];
    for json in commands {
        assert!(serde_json::from_str::<ReplayCommandDto>(json).is_ok());
        let unknown = json.replacen('}', ",\"unexpectedField\":true}", 1);
        assert!(serde_json::from_str::<ReplayCommandDto>(&unknown).is_err());
    }
}

#[test]
fn production_completion_events_have_strict_replay_shapes() {
    let events = [
        r#"{"type":"cityBuiltBuilding","cityId":"city-1","buildingType":"workshop"}"#,
        r#"{"type":"cityProducedUnit","cityId":"city-1","unitType":"warrior","producedUnitId":"city-1_warrior_1"}"#,
        r#"{"type":"cityBuiltWonder","cityId":"city-1","ownerPlayerId":"player-1","wonderType":"greatLibrary"}"#,
        r#"{"type":"wonderProductionRefunded","cityId":"city-2","ownerPlayerId":"player-2","wonderType":"greatLibrary","refundedProduction":17}"#,
        r#"{"type":"technologyResearched","playerId":"player-1","technologyId":"writing"}"#,
        r#"{"type":"researchPointsGained","playerId":"player-1","points":7}"#,
    ];
    for json in events {
        assert!(serde_json::from_str::<ReplayEventDto>(json).is_ok());
        let unknown = json.replacen('}', ",\"unexpectedField\":true}", 1);
        assert!(serde_json::from_str::<ReplayEventDto>(&unknown).is_err());
    }
}

#[test]
fn diplomacy_events_have_strict_replay_shapes() {
    let events = [
        r#"{"type":"diplomaticProposalSent","proposalId":"proposal-1","fromPlayerId":"player-1","toPlayerId":"player-2","kind":"friendship","expiresOnTurn":12}"#,
        r#"{"type":"diplomaticProposalResponded","proposalId":"proposal-1","fromPlayerId":"player-1","toPlayerId":"player-2","kind":"friendship","accepted":true}"#,
        r#"{"type":"diplomaticProposalExpired","proposalId":"proposal-1","fromPlayerId":"player-1","toPlayerId":"player-2","kind":"friendship"}"#,
        r#"{"type":"diplomaticRelationChanged","playerAId":"player-1","playerBId":"player-2","oldStatus":"neutral","newStatus":"friendly","reason":"proposalAccepted","expiresOnTurn":null}"#,
        r#"{"type":"diplomaticMessageSent","messageId":"message-1","fromPlayerId":"player-1","toPlayerId":"player-2","topic":"withdrawScouts","category":"request","expiresOnTurn":12}"#,
        r#"{"type":"diplomaticMessageResponded","messageId":"message-1","fromPlayerId":"player-1","toPlayerId":"player-2","topic":"withdrawScouts","response":"conciliatory","relationDelta":12,"relationScoreAfter":12,"promiseDueTurn":10}"#,
        r#"{"type":"diplomaticPromiseBroken","messageId":"message-1","playerAId":"player-1","playerBId":"player-2","delta":-15,"scoreAfter":-3}"#,
    ];
    for json in events {
        assert!(serde_json::from_str::<ReplayEventDto>(json).is_ok());
        let unknown = json.replacen('}', ",\"unexpectedField\":true}", 1);
        assert!(serde_json::from_str::<ReplayEventDto>(&unknown).is_err());
    }
}
