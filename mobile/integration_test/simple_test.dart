import 'package:flutter_test/flutter_test.dart';
import 'package:cribbage_club/src/rust/frb_generated.dart';
import 'package:cribbage_club/src/rust/api/simple.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async => await RustLib.init());

  test('Can create a Rust game engine', () async {
    final engine = await engineNew(
      gameId: 'test_game',
      player1Id: 'p1',
      player1Name: 'Player 1',
      player2Id: 'p2',
      player2Name: 'Player 2',
      seed: null,
    );
    final stateJson = engineCurrentStateJson(engine: engine);
    expect(stateJson, contains('test_game'));
  });
}
