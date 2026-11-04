CREATE TABLE IF NOT EXISTS Pins (
    ServerId TEXT NOT NULL,
    UserId TEXT NOT NULL,
    ItemId TEXT NOT NULL,
    ItemType TEXT NOT NULL,
    Name TEXT NOT NULL,
    ImageUrl TEXT,
    PinnedAt INTEGER NOT NULL,
    PRIMARY KEY (ServerId, UserId, ItemId)
)
