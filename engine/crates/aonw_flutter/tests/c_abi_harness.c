#include "aonw_flutter.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const uint8_t CAPABILITIES_REQUEST[] =
    "{\"apiVersion\":7,\"request\":{\"type\":\"capabilities\"}}";

static void require(int condition, const char *message) {
  if (!condition) {
    fprintf(stderr, "C ABI harness failed: %s\n", message);
    exit(1);
  }
}

static void require_response_contains(void *response, const char *expected) {
  const size_t length = aonw_flutter_response_len(response);
  const uint8_t *data = aonw_flutter_response_data(response);
  require(response != NULL, "response handle is null");
  require(data != NULL, "response data is null");
  char *copy = malloc(length + 1);
  require(copy != NULL, "response copy allocation failed");
  memcpy(copy, data, length);
  copy[length] = '\0';
  require(strstr(copy, expected) != NULL, "response payload differs");
  free(copy);
}

static void lifecycle(void) {
  require(aonw_flutter_is_available() == 1, "adapter is unavailable");
  require(aonw_flutter_client_api_version() == 7, "client API differs");
  require(aonw_flutter_build_identity_len() > 0, "build identity is empty");
  require(
      aonw_flutter_build_identity_data() != NULL,
      "build identity data is null");

  void *session = aonw_flutter_session_new();
  require(session != NULL, "session handle is null");
  void *response = aonw_flutter_session_request(
      session,
      CAPABILITIES_REQUEST,
      sizeof(CAPABILITIES_REQUEST) - 1);
  require_response_contains(response, "\"status\":\"success\"");
  aonw_flutter_response_free(response);
  aonw_flutter_session_free(session);
}

static void null_arguments(void) {
  require(aonw_flutter_response_len(NULL) == 0, "null response length differs");
  require(aonw_flutter_response_data(NULL) == NULL, "null response data differs");
  aonw_flutter_response_free(NULL);
  aonw_flutter_session_free(NULL);

  void *response = aonw_flutter_session_request(NULL, NULL, 1);
  require_response_contains(response, "\"code\":\"invalid_ffi_argument\"");
  aonw_flutter_response_free(response);
}

static void response_double_free(void) {
  void *session = aonw_flutter_session_new();
  void *response = aonw_flutter_session_request(
      session,
      CAPABILITIES_REQUEST,
      sizeof(CAPABILITIES_REQUEST) - 1);
  aonw_flutter_response_free(response);
  aonw_flutter_response_free(response);
  aonw_flutter_session_free(session);
}

static void session_double_free(void) {
  void *session = aonw_flutter_session_new();
  aonw_flutter_session_free(session);
  aonw_flutter_session_free(session);
}

int main(int argc, char **argv) {
  require(argc == 2, "expected exactly one case name");
  if (strcmp(argv[1], "lifecycle") == 0) {
    lifecycle();
  } else if (strcmp(argv[1], "null_arguments") == 0) {
    null_arguments();
  } else if (strcmp(argv[1], "response_double_free") == 0) {
    response_double_free();
  } else if (strcmp(argv[1], "session_double_free") == 0) {
    session_double_free();
  } else {
    require(0, "unknown case name");
  }
  return 0;
}
