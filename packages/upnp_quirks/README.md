# upnp_quirks

What JellyBox knows about how individual UPnP/DLNA renderers actually behave, as
opposed to what they claim in their service descriptions.

**This copy carries no rules.** It is the model plus an empty table, which is
what the app builds against by default: every device resolves to
`DeviceQuirks.defaults` and behaves exactly as it did before quirks existed. The
populated table lives in a separate private repository, because the value in it
is accumulated data about specific hardware rather than code.

## Building with the private table

Put a `pubspec_overrides.yaml` next to the app's `pubspec.yaml` (it is
gitignored, see `pubspec_overrides.yaml.example`):

```yaml
dependency_overrides:
  upnp_quirks:
    git:
      url: git@github.com:<owner>/upnp_quirks.git
```

Then `flutter pub get`. Nothing else in the app changes: the private package
exports the same API from the same package name, with rules in the table.

## The shape

- `DeviceFingerprint` — everything learnable about a renderer without playing
  anything: manufacturer, model name and number, device type, friendly name, the
  AVTransport actions its SCPD advertises, and its ConnectionManager sink.
  `toJson()` is the shape reported alongside errors, so field reports arrive with
  enough detail to write a new rule.
- `DeviceQuirks` — the overrides a rule may apply: next-track prefetch, DIDL
  metadata, stop-before-set-URI, seek unit, device volume range, poll interval,
  idle polls before advancing, and MIME types to ignore even when advertised.
- `QuirkRule` plus `quirksFor(fingerprint)` — matching by substring over the
  fingerprint, defaults with every matching rule applied.

Every rule needs an `evidence` string recording the observation behind it. A
rule without evidence is a guess, and guesses here are worse than defaults:
they silently degrade devices nobody has tested.
