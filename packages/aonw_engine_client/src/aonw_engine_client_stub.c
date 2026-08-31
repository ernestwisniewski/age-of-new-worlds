#include <stddef.h>
#include <stdint.h>

#if defined(_WIN32)
#define AONW_EXPORT __declspec(dllexport)
#else
#define AONW_EXPORT __attribute__((visibility("default"))) __attribute__((used))
#endif

AONW_EXPORT uint8_t aonw_flutter_is_available(void) { return 0; }
AONW_EXPORT uint16_t aonw_flutter_client_api_version(void) { return 0; }
AONW_EXPORT size_t aonw_flutter_build_identity_len(void) { return 0; }
AONW_EXPORT const uint8_t *aonw_flutter_build_identity_data(void) { return NULL; }
AONW_EXPORT void *aonw_flutter_session_new(void) { return NULL; }
AONW_EXPORT void aonw_flutter_session_free(void *session) { (void)session; }
AONW_EXPORT void *aonw_flutter_session_request(
    void *session,
    const uint8_t *request,
    size_t request_len) {
  (void)session;
  (void)request;
  (void)request_len;
  return NULL;
}
AONW_EXPORT size_t aonw_flutter_response_len(const void *response) {
  (void)response;
  return 0;
}
AONW_EXPORT const uint8_t *aonw_flutter_response_data(const void *response) {
  (void)response;
  return NULL;
}
AONW_EXPORT void aonw_flutter_response_free(void *response) { (void)response; }
