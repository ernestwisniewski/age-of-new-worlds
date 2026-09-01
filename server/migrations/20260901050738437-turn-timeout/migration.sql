BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "aonw_game_match" ADD COLUMN "turnDeadlineAt" timestamp without time zone;
UPDATE "aonw_game_match"
SET "turnDeadlineAt" = (CURRENT_TIMESTAMP AT TIME ZONE 'UTC') + INTERVAL '24 hours'
WHERE "state" = 'running';
CREATE INDEX "aonw_game_match_turn_deadline_idx" ON "aonw_game_match" USING btree ("turnDeadlineAt", "publicId");

--
-- MIGRATION VERSION FOR aonw
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('aonw', '20260901050738437-turn-timeout', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260901050738437-turn-timeout', "timestamp" = now();

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
