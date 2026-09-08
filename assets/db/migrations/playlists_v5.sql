CREATE TABLE Playlists (
    Id TEXT NOT NULL,
    ServerId TEXT NOT NULL DEFAULT '',
    SizeInBytes INTEGER NOT NULL,
    DownloadDate INTEGER NOT NULL,
    Data TEXT NOT NULL,
    PRIMARY KEY (Id, ServerId)
)
