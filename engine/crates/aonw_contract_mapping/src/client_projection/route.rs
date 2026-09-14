use aonw_contracts::client::{MerchantRouteViewDto, QueuedRouteViewDto};
use aonw_domain::{MerchantTradeRoute, QueuedMovePath};
use aonw_projection::OwnedRouteView;

pub(super) fn queued_route(view: &OwnedRouteView<QueuedMovePath>) -> QueuedRouteViewDto {
    let route = crate::encode_queued_path(view.route());
    QueuedRouteViewDto {
        target_col: route.target_col,
        target_row: route.target_row,
        steps: route.steps,
        step_turns: view.step_turns().to_vec(),
        road_step_indices: view.road_step_indices().to_vec(),
    }
}

pub(super) fn merchant_route(view: &OwnedRouteView<MerchantTradeRoute>) -> MerchantRouteViewDto {
    let route = crate::encode_merchant_trade_route(view.route());
    MerchantRouteViewDto {
        origin_city_id: route.origin_city_id,
        destination_city_id: route.destination_city_id,
        steps: route.steps,
        transport_network_fingerprint: route.transport_network_fingerprint,
        step_turns: view.step_turns().to_vec(),
        road_step_indices: view.road_step_indices().to_vec(),
    }
}
