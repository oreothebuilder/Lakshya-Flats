import 'package:flutter_test/flutter_test.dart';
import 'package:lakshya_residency/models/building_model.dart';

void main() {
  group('BuildingModel tests', () {
    test('Calculates occupancy rates and vacancies accurately', () {
      final building = BuildingModel(
        id: 'test_bld',
        name: 'Test Residency',
        totalCapacity: 100,
        occupiedCount: 85,
        totalRooms: 50,
      );

      expect(building.occupancyRate, 0.85);
      expect(building.occupancyPercentage, 85);
      expect(building.availableBeds, 15);
      expect(building.isFull, false);
      expect(building.isNearCapacity, false);
    });

    test('Near capacity and full flags work properly', () {
      final nearFull = BuildingModel(
        id: 'test_bld_2',
        name: 'Near Full Residency',
        totalCapacity: 100,
        occupiedCount: 95,
      );

      expect(nearFull.isNearCapacity, true);
      expect(nearFull.isFull, false);
      expect(nearFull.availableBeds, 5);

      final fullBuilding = BuildingModel(
        id: 'test_bld_3',
        name: 'Full Residency',
        totalCapacity: 100,
        occupiedCount: 100,
      );

      expect(fullBuilding.isFull, true);
      expect(fullBuilding.availableBeds, 0);
    });

    test('Pre-seeded default catalog contains 8 properties with valid assets', () {
      final defaults = BuildingModel.defaultBuildings;
      expect(defaults.length, 8);

      final names = defaults.map((b) => b.name).toList();
      expect(names, containsAll([
        'Lakshya',
        'Ishaan',
        'Univ Homes',
        'Rameshwaram',
        'Shivalay',
        'Somnath',
        'Tirupati',
        'Livano',
      ]));

      for (final b in defaults) {
        expect(b.imageAsset.startsWith('assets/buildings/'), isTrue);
        expect(b.totalCapacity, greaterThan(0));
        expect(b.occupiedCount, greaterThanOrEqualTo(0));
        expect(b.totalRooms, greaterThan(0));
      }
    });

    test('Built-in assets catalog has all 8 images mapped', () {
      expect(BuildingModel.builtInAssets.length, 8);
    });

    test('Fuzzy building matching correctly maps variations', () {
      bool matches(String b1, String b2) {
        final t1 = b1.toLowerCase().replaceAll('residency', '').replaceAll('homes', '').replaceAll('villa', '').trim();
        final t2 = b2.toLowerCase().replaceAll('residency', '').replaceAll('homes', '').replaceAll('villa', '').trim();
        if (t1.isEmpty || t2.isEmpty) return false;
        return t1.contains(t2) || t2.contains(t1);
      }

      expect(matches('Lakshya', 'Lakshya'), isTrue);
      expect(matches('Lakshya', 'Lakshya Residency'), isTrue);
      expect(matches('Univ Homes', 'Univ'), isTrue);
      expect(matches('Univ Homes', 'Univ Homes'), isTrue);
      expect(matches('Livano', 'Livano Villa'), isTrue);
      expect(matches('Ishaan', 'Ishaan'), isTrue);
      expect(matches('Rameshwaram', 'Rameshwaram Residency'), isTrue);
      expect(matches('Lakshya', 'Ishaan'), isFalse);
    });
  });
}
