/// Limit for building a mobile or tablet UI
const int kTabletBreakpoint = 600;

const String version = '1.8.2';

const String updatifyProjectId = '0ebf56de-26b5-4107-bc87-1aa89b328924';

const String changelogTitle = "What's new";

/// True for the direct-download (Developer ID / notarized DMG) build, set via
/// `--dart-define=JELLYBOX_DIRECT_DOWNLOAD=true` in the macOS DMG workflow.
/// Those builds are not sandboxed; the App Store build leaves this false.
const bool kDirectDownloadBuild = bool.fromEnvironment(
  'JELLYBOX_DIRECT_DOWNLOAD',
);

const String discordApplicationId = '1547587702344388712';
