import 'package:aonw_rust_client/src/api.dart';
import 'package:aonw_rust_client/src/native_identity.dart';

AonwNativeIdentity get aonwRustClientIdentity => const AonwNativeIdentity(
  status: AonwNativeIdentityStatus.unavailable,
  clientApiVersion: 0,
  buildIdentity: '',
);

bool get aonwRustClientAvailable => false;

Future<AonwRustSession?> createAonwRustSession() async => null;
