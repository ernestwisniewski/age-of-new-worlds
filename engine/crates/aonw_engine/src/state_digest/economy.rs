use aonw_domain::{EconomyState, ResourceType};

use super::writer::DigestWriter;

pub(super) fn hash_economy(writer: &mut DigestWriter, economy: &EconomyState) {
    hash_accounts(writer, economy.player_gold());
    hash_accounts(writer, economy.player_war_weariness());
    hash_accounts(writer, economy.player_stability_net());

    writer.usize(economy.strategic_resources().len());
    for (player, stockpile) in economy.strategic_resources() {
        writer.text(player.as_str());
        hash_stockpile(writer, stockpile);
    }

    let distribution = economy.initial_resource_distribution();
    writer.i64(distribution.seed());
    writer.usize(distribution.placements().len());
    for placement in distribution.placements() {
        writer.coordinate(placement.coordinate());
        writer.u8(resource_tag(placement.resource()));
    }
}

pub(super) fn hash_stockpile(
    writer: &mut DigestWriter,
    stockpile: &aonw_domain::StrategicResourceStockpile,
) {
    writer.usize(stockpile.amounts().len());
    for (resource, amount) in stockpile.amounts() {
        writer.u8(resource_tag(*resource));
        writer.i64(*amount);
    }
}

fn hash_accounts(
    writer: &mut DigestWriter,
    accounts: &std::collections::BTreeMap<aonw_domain::PlayerId, i64>,
) {
    writer.usize(accounts.len());
    for (player, value) in accounts {
        writer.text(player.as_str());
        writer.i64(*value);
    }
}

pub(super) const fn resource_tag(resource: ResourceType) -> u8 {
    match resource {
        ResourceType::Wheat => 0,
        ResourceType::Fish => 1,
        ResourceType::Deer => 2,
        ResourceType::Sheep => 3,
        ResourceType::Rice => 4,
        ResourceType::Cow => 5,
        ResourceType::Apple => 6,
        ResourceType::Banana => 7,
        ResourceType::Citrus => 8,
        ResourceType::Gold => 9,
        ResourceType::Silver => 10,
        ResourceType::Gems => 11,
        ResourceType::Silk => 12,
        ResourceType::Spices => 13,
        ResourceType::Cotton => 14,
        ResourceType::Grapes => 15,
        ResourceType::Ivory => 16,
        ResourceType::Pearls => 17,
        ResourceType::Coffee => 18,
        ResourceType::Cocoa => 19,
        ResourceType::Tobacco => 20,
        ResourceType::Sugar => 21,
        ResourceType::Iron => 22,
        ResourceType::Coal => 23,
        ResourceType::Oil => 24,
        ResourceType::Aluminium => 25,
        ResourceType::Uranium => 26,
        ResourceType::Horses => 27,
        ResourceType::Marble => 28,
    }
}
