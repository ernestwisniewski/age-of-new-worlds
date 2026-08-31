import 'package:aonw_engine_client/src/api.dart';
import 'package:aonw_engine_client/src/native_identity.dart';

AonwNativeIdentity get aonwEngineClientIdentity => const AonwNativeIdentity(
  status: AonwNativeIdentityStatus.unavailable,
  clientApiVersion: 0,
  buildIdentity: '',
);

bool get aonwEngineClientAvailable => false;

Future<AonwEngineSession?> createAonwEngineSession() async => null;
