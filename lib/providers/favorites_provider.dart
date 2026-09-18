import 'package:flutter/material.dart';
import 'package:food_app/models/item_model.dart';
import 'package:food_app/helpers/db_helper.dart';

class FavoritesProvider with ChangeNotifier {
  List<Item> _favoriteItems = [];

  /// Newest first. The list came back in whatever order SQLite happened to
  /// return rows, so an item favourited just now could appear anywhere and
  /// customers reported that favouriting "did nothing".
  List<Item> get favoriteItems => _favoriteItems.reversed.toList();

  int get favoriteCount => _favoriteItems.length;

  // Load favorites from SQL specifically for the logged-in user.
  //
  // The favorites table only stores what the list tile needs — id, title,
  // price, image — so rebuilding an Item straight from a row left category and
  // description empty. That is invisible on this screen and wrong on the next
  // one: opening a favourite showed the detail page with no description at all.
  // The menu is the source of truth for those fields, so look the row up there
  // and fall back to the stored columns only for an item the menu no longer has.
  Future<void> fetchFavorites(String userId) async {
    final dataList = await DBHelper.getData('favorites', where: 'userId = ?', whereArgs: [userId]);
    final menuById = {for (final item in dummyMenu) item.id: item};
    _favoriteItems = dataList.map((row) {
      final id = row['id'] as String;
      final menuItem = menuById[id];
      return Item(
        id: id,
        title: row['title'],
        price: row['price'],
        imageUrl: row['imageUrl'],
        category: menuItem?.category ?? '',
        description: menuItem?.description ?? '',
      );
    }).toList();
    notifyListeners();
  }

  // Clear favorites from memory (called on logout)
  void clearFavorites() {
    _favoriteItems = [];
    notifyListeners();
  }

  bool isFavorite(Item item) {
    return _favoriteItems.any((fav) => fav.id == item.id);
  }

  Future<void> toggleFavorite(Item item, String userId) async {
    final isFav = isFavorite(item);
    if (isFav) {
      // Remove from DB specifically for this user
      await DBHelper.delete('favorites', where: 'id = ? AND userId = ?', whereArgs: [item.id, userId]);
      _favoriteItems.removeWhere((fav) => fav.id == item.id);
    } else {
      // Insert into DB with userId
      await DBHelper.insert('favorites', {
        'id': item.id,
        'userId': userId,
        'title': item.title,
        'price': item.price,
        'imageUrl': item.imageUrl,
      });
      _favoriteItems.add(item);
    }
    notifyListeners();
  }
}
