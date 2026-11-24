enum PanelStyle {
  hard,
  floating,
  infiniteFloating;

  bool get isFloating => this != hard;
}
