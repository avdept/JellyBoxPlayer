CREATE TABLE PlaylistSongs (
    PlaylistId TEXT NOT NULL,
    SongId TEXT NOT NULL,
    ServerId TEXT NOT NULL DEFAULT '',
    Position INTEGER NOT NULL,
    PRIMARY KEY (PlaylistId, SongId, ServerId)
)
