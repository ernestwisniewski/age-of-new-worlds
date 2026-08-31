use aonw_contracts::PlayerKindDto;
use aonw_contracts::client::{
    ClientParticipantControlDto, ClientResponseBodyDto, ClientResponseDto,
};

use crate::{LocalRuntime, RuntimeError};

use super::{decode, encode, failure, success};

pub(super) fn dispatch_open_save(
    runtime: &mut LocalRuntime,
    map_document: &str,
    save_document: &str,
) -> ClientResponseDto {
    match decode::map(map_document) {
        Ok(map) => match runtime.open_save_json(
            map,
            aonw_content::RulesetDefinition::standard().clone(),
            save_document,
        ) {
            Ok(stamp) => match restored_control(runtime) {
                Ok((actor_player_id, participants)) => success(ClientResponseBodyDto::SaveOpened {
                    stamp: encode::stamp(stamp),
                    actor_player_id,
                    participants,
                }),
                Err(error) => failure("save_open_failed", error),
            },
            Err(error) => failure("save_open_failed", error),
        },
        Err(error) => error.into_response(),
    }
}

fn restored_control(
    runtime: &LocalRuntime,
) -> Result<(String, Vec<ClientParticipantControlDto>), RuntimeError> {
    let session = runtime.session_ref()?;
    let identity = session.state().match_lifecycle().identity();
    let participants = identity
        .participants()
        .iter()
        .map(|participant| ClientParticipantControlDto {
            id: participant.id().as_str().to_owned(),
            name: participant.name().to_owned(),
            kind: match participant.kind() {
                aonw_domain::PlayerKind::Human => PlayerKindDto::Human,
                aonw_domain::PlayerKind::Ai => PlayerKindDto::Ai,
            },
        })
        .collect();
    Ok((session.actor().as_str().to_owned(), participants))
}
