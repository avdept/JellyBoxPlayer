CREATE TABLE Downloads (
    Id TEXT PRIMARY KEY,
    RunTimeTicks INTEGER NOT NULL,
    IndexNumber INTEGER NOT NULL,
    Type TEXT NOT NULL,
    AlbumArtist TEXT,
    PlaylistItemId TEXT,
    Album TEXT,
    AlbumId TEXT,
    Name TEXT,
    UserData TEXT NOT NULL,
    ImageTags TEXT,
    DownloadDate INTEGER NOT NULL,
    FilePath TEXT NOT NULL,
    SizeInBytes INTEGER NOT NULL
)
