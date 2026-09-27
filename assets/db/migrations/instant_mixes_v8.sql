CREATE TABLE InstantMixes (
    Id TEXT NOT NULL,
    ServerId TEXT NOT NULL,
    UserId TEXT NOT NULL,
    LibraryId TEXT NOT NULL,
    Seed TEXT NOT NULL,
    Songs TEXT NOT NULL,
    LastUsedAt INTEGER NOT NULL,
    PRIMARY KEY (Id, ServerId, UserId)
)
