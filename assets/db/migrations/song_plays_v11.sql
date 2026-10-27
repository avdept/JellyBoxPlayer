CREATE TABLE IF NOT EXISTS SongPlays (
    ServerId TEXT NOT NULL,
    UserId TEXT NOT NULL,
    SongId TEXT NOT NULL,
    PlayedAt INTEGER NOT NULL,
    Source TEXT NOT NULL DEFAULT 'local',
    PRIMARY KEY (ServerId, UserId, SongId, PlayedAt, Source)
)
