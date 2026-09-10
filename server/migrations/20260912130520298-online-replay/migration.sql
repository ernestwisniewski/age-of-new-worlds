BEGIN;

--
-- ACTION ALTER TABLE
--
ALTER TABLE "aonw_game_match" ADD COLUMN "initialStateJson" text;
ALTER TABLE "aonw_game_match" ADD COLUMN "initialStateDigest" text;
ALTER TABLE "aonw_game_match" ADD COLUMN "initialRevision" bigint;
ALTER TABLE "aonw_game_match" ADD COLUMN "replayBehaviorFingerprint" text;
--
-- ACTION CREATE TABLE
--
CREATE TABLE "aonw_game_replay_entry" (
    "id" bigserial PRIMARY KEY,
    "matchId" bigint NOT NULL,
    "revision" bigint NOT NULL,
    "actorPlayerId" text,
    "commandKind" text NOT NULL,
    "commandJson" text NOT NULL,
    "stateDigest" text NOT NULL,
    "initialEventOffset" bigint NOT NULL,
    "finalEventOffset" bigint NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "aonw_game_replay_entry_revision_idx" ON "aonw_game_replay_entry" USING btree ("matchId", "revision");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "aonw_game_replay_entry"
    ADD CONSTRAINT "aonw_game_replay_entry_fk_0"
    FOREIGN KEY("matchId")
    REFERENCES "aonw_game_match"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR aonw
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('aonw', '20260912130520298-online-replay', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260912130520298-online-replay', "timestamp" = now();

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
