# AoNW Server Native

Fail-closed Native Assets adapter for the stateless engine multiplayer
host. The package contains no C stub and no Dart gameplay fallback. Serverpod
must verify `AonwServerNativeIdentity` before accepting traffic.

`AonwPreparedServerWorld` owns only immutable compiled map/rules content. Match
state, command correlation, transactions, offsets, delivery, and reconnect stay
in Serverpod/PostgreSQL.
