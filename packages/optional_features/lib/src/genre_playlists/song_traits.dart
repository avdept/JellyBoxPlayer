abstract class SongTraits<S> {
  String idOf(S song);

  String? albumIdOf(S song);

  List<String> genresOf(S song);

  int playCountOf(S song);

  bool hasCoverOf(S song);
}
