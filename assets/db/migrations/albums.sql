CREATE TABLE Albums (
    Id TEXT PRIMARY KEY,
    Name TEXT NOT NULL,
    Type TEXT NOT NULL,
    Overview TEXT,
    RunTimeTicks INTEGER,
    ProductionYear INTEGER,
    AlbumArtist TEXT,
    ImageTags TEXT,
    BackdropImageTags TEXT,
    DownloadDate INTEGER NOT NULL,
    SizeInBytes INTEGER NOT NULL
)
