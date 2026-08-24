import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wastemanagementapp/core/di/service_locator.dart';
import 'package:wastemanagementapp/core/utils/device_capability_service.dart';
import 'package:wastemanagementapp/data/datasources/local/council_rules_datasource.dart';
import 'package:wastemanagementapp/domain/entities/bin_assignment.dart';
import 'package:wastemanagementapp/domain/usecases/classify_waste_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 1 Dublin Council Waste Rules Tests', () {
    late CouncilRulesDataSource rulesDataSource;

    setUp(() {
      rulesDataSource = DublinCouncilRulesDataSourceImpl();
    });

    test('Clean aluminum can maps to Dublin Green Bin (Recycling)', () {
      final bin = rulesDataSource.resolveBin(
        objectName: 'Aluminum Soda Can',
        materialType: 'Metal / Aluminum',
        condition: 'Clean & Empty',
        councilName: 'Dublin City Council',
      );

      expect(bin.binType, BinType.greenRecycling);
      expect(bin.localBinName, contains('Green Bin'));
      expect(bin.councilName, 'Dublin City Council');
    });

    test('Food scraps & apple core map to Dublin Brown Bin (Organic)', () {
      final bin = rulesDataSource.resolveBin(
        objectName: 'Apple Core',
        materialType: 'Organic / Food',
        condition: 'Fresh Peel',
        councilName: 'Dublin City Council',
      );

      expect(bin.binType, BinType.brownCompost);
      expect(bin.localBinName, contains('Brown Bin'));
    });

    test('Greasy food-soiled cardboard pizza box maps to Dublin Black Bin (General Waste)', () {
      final bin = rulesDataSource.resolveBin(
        objectName: 'Cardboard Pizza Box',
        materialType: 'Cardboard',
        condition: 'Food-soiled and greasy',
        councilName: 'Dublin City Council',
      );

      expect(bin.binType, BinType.blackGeneral);
      expect(bin.localBinName, contains('Black / Grey Bin'));
      expect(bin.disposalSteps.first, contains('food-soiled or wet'));
    });
  });

  group('Phase 1 Service Locator & Device Capability Tests', () {
    setUp(() async {
      await sl.reset();
      dotenv.testLoad(fileInput: 'OPENROUTER_API_KEY=test_key');
      await setupServiceLocator();
    });

    test('GetIt correctly resolves ClassifyWasteImage use case', () {
      final usecase = sl<ClassifyWasteImage>();
      expect(usecase, isA<ClassifyWasteImage>());
    });

    test('DeviceCapabilityService detects device tier', () async {
      final capabilityService = sl<DeviceCapabilityService>();
      final capability = await capabilityService.getCapability();

      expect(capability.targetFps, greaterThanOrEqualTo(60.0));
      expect(capability.hardwareModel, isNotEmpty);
    });
  });
}
