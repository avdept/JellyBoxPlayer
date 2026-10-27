CREATE TABLE IF NOT EXISTS PlayedSongs (
    ServerId TEXT NOT NULL,
    SongId TEXT NOT NULL,
    Item TEXT NOT NULL,
    UpdatedAt INTEGER NOT NULL,
    PRIMARY KEY (ServerId, SongId)
)
