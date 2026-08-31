#ifndef AONW_FLUTTER_H
#define AONW_FLUTTER_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

uint8_t aonw_flutter_is_available(void);
uint16_t aonw_flutter_client_api_version(void);
size_t aonw_flutter_build_identity_len(void);
const uint8_t *aonw_flutter_build_identity_data(void);

void *aonw_flutter_session_new(void);
void aonw_flutter_session_free(void *session);
void *aonw_flutter_session_request(
    void *session,
    const uint8_t *request,
    size_t request_len);

size_t aonw_flutter_response_len(const void *response);
const uint8_t *aonw_flutter_response_data(const void *response);
void aonw_flutter_response_free(void *response);

#ifdef __cplusplus
}
#endif

#endif
