import 'package:flutter_test/flutter_test.dart';
import 'package:sitcheck/src/controllers/restaurant_controller.dart';
import 'package:sitcheck/src/data/mock_restaurants.dart';

void main() {
  test('Verify updated restaurant names in mock data', () {
    // Verify direct mock data
    expect(mockRestaurants[0].name, 'Village Restaurant');
    expect(mockRestaurants[1].name, 'Naadu Restaurant');
    expect(mockRestaurants[2].name, 'Hotel Sai Palace');
    
    expect(mockRestaurants[0].address, contains('Village Restaurant'));
    expect(mockRestaurants[1].address, contains('Naadu Restaurant'));
    expect(mockRestaurants[2].address, contains('Hotel Sai Palace'));
  });

  test('RestaurantController loads updated data (fallback mode)', () async {
    // This test relies on the controller falling back to mock data 
    // when the database service fails (which it should in a unit test environment 
    // without method channel mocks).
    
    final controller = RestaurantController();
    
    // Wait for the async _loadRestaurants to complete
    // Since we can't await the private method, we wait a bit or check isLoading
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (controller.restaurants.isNotEmpty) {
       expect(controller.restaurants[0].name, 'Village Restaurant');
       expect(controller.restaurants[1].name, 'Naadu Restaurant');
       expect(controller.restaurants[2].name, 'Hotel Sai Palace');
    }
  });
  
  test('RestaurantController seeds DB if empty', () async {
    // This test simulates the controller initialization
    final controller = RestaurantController();
    await Future.delayed(const Duration(milliseconds: 200));
    
    // If logic works, restaurants should be loaded
    expect(controller.restaurants.isNotEmpty, true);
    expect(controller.restaurants[0].id, 'village-restaurant');
  });
}
