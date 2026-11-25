import 'package:flutter_test/flutter_test.dart';
import 'package:panel_puzzle/sprite/sprite_data.dart';

void main() {
  testWidgets('preloads every atlas into the shared cache, including after a partial load',
      (tester) async {
    await tester.runAsync(() async {
      final kirb = await SpriteDataCollection.acquireData('Kirb');
      expect(SpriteDataCollection.numOfAssetsLoaded, 1);

      final preload = SpriteDataCollection.loadAll();
      final groove = await SpriteDataCollection.acquireData('Kirb Groove');
      await preload;

      expect(SpriteDataCollection.numOfAssetsLoaded, 2);
      expect(identical(await SpriteDataCollection.acquireData('Kirb'), kirb), isTrue);
      expect(identical(await SpriteDataCollection.acquireData('Kirb Groove'), groove), isTrue);
      expect(kirb.frameCollection.numOfFrames, greaterThan(0));
      expect(groove.frameCollection.numOfFrames, greaterThan(0));

      await SpriteDataCollection.loadAll();
      expect(SpriteDataCollection.numOfAssetsLoaded, 2);
      await expectLater(
        SpriteDataCollection.acquireData('missing'),
        throwsStateError,
      );
    });
  });
}
