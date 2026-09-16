BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "aonw_game_lobby_connection" (
    "id" bigserial PRIMARY KEY,
    "matchId" bigint NOT NULL,
    "participantId" bigint NOT NULL,
    "userIdentifier" text NOT NULL,
    "joinedAt" timestamp without time zone NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE INDEX "aonw_game_lobby_connection_active_idx" ON "aonw_game_lobby_connection" USING btree ("matchId", "expiresAt");

--
-- ACTION CREATE FOREIGN KEY
--
ALTER TABLE ONLY "aonw_game_lobby_connection"
    ADD CONSTRAINT "aonw_game_lobby_connection_fk_0"
    FOREIGN KEY("matchId")
    REFERENCES "aonw_game_match"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;
ALTER TABLE ONLY "aonw_game_lobby_connection"
    ADD CONSTRAINT "aonw_game_lobby_connection_fk_1"
    FOREIGN KEY("participantId")
    REFERENCES "aonw_game_participant"("id")
    ON DELETE CASCADE
    ON UPDATE NO ACTION;


--
-- MIGRATION VERSION FOR aonw
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('aonw', '20260919155523413-lobby-presence', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260919155523413-lobby-presence', "timestamp" = now();

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
