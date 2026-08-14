CREATE TABLE Downloads (
    Id TEXT PRIMARY KEY,
    AlbumId TEXT,
    FilePath TEXT NOT NULL,
    SizeInBytes INTEGER NOT NULL,
    DownloadDate INTEGER NOT NULL,
    Data TEXT NOT NULL
)
