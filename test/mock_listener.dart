import 'package:mocktail/mocktail.dart';

class MockListener<State> extends Mock {
  void call(State? previous, State next);
}
