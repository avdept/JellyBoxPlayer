CREATE TABLE IF NOT EXISTS CatalogCache (
    Source TEXT NOT NULL,
    Key TEXT NOT NULL,
    Json TEXT NOT NULL,
    FetchedAt INTEGER NOT NULL,
    ExpiresAt INTEGER NOT NULL,
    PRIMARY KEY (Source, Key)
)
