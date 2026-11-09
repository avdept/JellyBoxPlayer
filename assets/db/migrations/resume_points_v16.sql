CREATE TABLE IF NOT EXISTS ResumePoints (
    ServerId TEXT NOT NULL,
    UserId TEXT NOT NULL,
    SourceId TEXT NOT NULL,
    Item TEXT NOT NULL,
    SongId TEXT NOT NULL,
    SongName TEXT NOT NULL,
    SongIndex INTEGER NOT NULL,
    SongCount INTEGER NOT NULL,
    PositionMs INTEGER NOT NULL,
    UpdatedAt INTEGER NOT NULL,
    PRIMARY KEY (ServerId, UserId, SourceId)
)
