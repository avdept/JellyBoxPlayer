CREATE TABLE IF NOT EXISTS CatalogArtistLinks (
    ServerId TEXT NOT NULL,
    ArtistId TEXT NOT NULL,
    Source TEXT NOT NULL,
    CatalogId TEXT,
    CheckedAt INTEGER NOT NULL,
    PRIMARY KEY (ServerId, ArtistId, Source)
)
