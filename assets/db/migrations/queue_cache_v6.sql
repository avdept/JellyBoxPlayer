CREATE TABLE QueueCache (
    Id TEXT NOT NULL,
    ServerId TEXT NOT NULL DEFAULT '',
    FilePath TEXT NOT NULL,
    SizeInBytes INTEGER NOT NULL,
    CachedDate INTEGER NOT NULL,
    LastUsedDate INTEGER NOT NULL,
    Data TEXT NOT NULL,
    PRIMARY KEY (Id, ServerId)
)
