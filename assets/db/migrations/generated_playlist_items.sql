CREATE TABLE GeneratedPlaylistItems (
    PlaylistId TEXT NOT NULL,
    UserId TEXT NOT NULL,
    LibraryId TEXT NOT NULL,
    DayKey TEXT NOT NULL,
    Position INTEGER NOT NULL,
    SongId TEXT NOT NULL,
    Data TEXT NOT NULL,
    PRIMARY KEY (PlaylistId, UserId, LibraryId, DayKey, Position)
)
