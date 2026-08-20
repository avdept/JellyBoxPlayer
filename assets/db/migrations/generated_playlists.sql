CREATE TABLE GeneratedPlaylists (
    Id TEXT NOT NULL,
    UserId TEXT NOT NULL,
    LibraryId TEXT NOT NULL,
    DayKey TEXT NOT NULL,
    Position INTEGER NOT NULL,
    GeneratedAt INTEGER NOT NULL,
    RemoteId TEXT,
    SyncedAt INTEGER,
    Data TEXT NOT NULL,
    CoverSongs TEXT NOT NULL,
    PRIMARY KEY (Id, UserId, LibraryId, DayKey)
)
