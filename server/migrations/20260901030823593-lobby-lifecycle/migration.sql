BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "aonw_game_match" ADD COLUMN "hostPlayerId" text;
ALTER TABLE "aonw_game_match" ALTER COLUMN "startedAt" DROP NOT NULL;
--
-- ACTION ALTER TABLE
--
ALTER TABLE "aonw_game_participant" ADD COLUMN "readyAt" timestamp without time zone;
ALTER TABLE "aonw_game_participant" ADD COLUMN "leftAt" timestamp without time zone;
ALTER TABLE "aonw_game_participant" ADD COLUMN "resignedAt" timestamp without time zone;
ALTER TABLE "aonw_game_participant" ADD COLUMN "kickedAt" timestamp without time zone;
ALTER TABLE "aonw_game_participant" ADD COLUMN "kickReason" text;

--
-- MIGRATION VERSION FOR aonw
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('aonw', '20260901030823593-lobby-lifecycle', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260901030823593-lobby-lifecycle', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260129181112269', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129181112269', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260213194423028', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260213194423028', "timestamp" = now();


COMMIT;
