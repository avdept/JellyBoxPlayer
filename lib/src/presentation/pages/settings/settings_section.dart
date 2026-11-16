import 'package:flutter/material.dart';

enum SettingsSection {
  servers('Servers', Icons.dns_outlined),
  connection('Connection', Icons.wifi),
  home('Home', Icons.home_outlined),
  interface('Interface', Icons.tune),
  player('Player', Icons.play_circle_outline),
  integrations('Integrations', Icons.extension_outlined),
  support('Support', Icons.help_outline),
  about('About', Icons.info_outline);

  const SettingsSection(this.title, this.icon);

  final String title;
  final IconData icon;

  String summary({required bool mobile}) => switch (this) {
    servers => 'Accounts and addresses',
    connection => 'Jellybox Link, streaming quality, cache, downloads',
    home => 'Rows and pins on the home page',
    interface => 'Start page, browse lists, colours',
    player => mobile ? 'Landscape player and lyrics' : 'Studio Mode and lyrics',
    integrations => 'Scrobbling, artwork, Lidarr',
    support => 'Email, app log, Discord, GitHub',
    about => 'Privacy, changelog, version',
  };

  static SettingsSection? byName(String? name) =>
      name == null ? null : values.asNameMap()[name];
}
