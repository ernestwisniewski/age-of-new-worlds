#ifndef AONW_SERVER_NATIVE_H
#define AONW_SERVER_NATIVE_H

#include <stddef.h>
#include <stdint.h>

uint8_t aonw_server_native_is_available(void);
uint16_t aonw_server_native_api_version(void);
size_t aonw_server_native_build_identity_len(void);
const uint8_t *aonw_server_native_build_identity_data(void);

void *aonw_server_native_prepare_world(const uint8_t *request, size_t request_len);
void *aonw_server_native_response_take_world(void *response);
void aonw_server_native_world_free(void *world);

void *aonw_server_native_project_state(
    const void *world,
    const uint8_t *request,
    size_t request_len);

void *aonw_server_native_create_match(
    const void *world,
    const uint8_t *request,
    size_t request_len);

void *aonw_server_native_submit_turn(
    const void *world,
    const uint8_t *request,
    size_t request_len);

void *aonw_server_native_apply_player_command(
    const void *world,
    const uint8_t *request,
    size_t request_len);

void *aonw_server_native_query_player(
    const void *world,
    const uint8_t *request,
    size_t request_len);

size_t aonw_server_native_response_len(const void *response);
const uint8_t *aonw_server_native_response_data(const void *response);
void aonw_server_native_response_free(void *response);

#endif
