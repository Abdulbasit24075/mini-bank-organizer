import 'dart:convert';
import 'package:http/http.dart' as http;

class PriceSource {
  final String source;
  final String title;
  final String price;
  final String snippet;

  PriceSource({
    required this.source,
    required this.title,
    required this.price,
    required this.snippet,
  });
}

class PriceCheckResult {
  final String product;
  final String city;
  final String estimatedPrice;
  final String priceRange;
  final String unit;
  final String confidence;
  final String note;
  final List<PriceSource> priceSources;

  PriceCheckResult({
    required this.product,
    required this.city,
    required this.estimatedPrice,
    required this.priceRange,
    required this.unit,
    required this.confidence,
    required this.note,
    required this.priceSources,
  });
}

class PriceCheckService {
  static const String _apiKey = 'd4de47c6a5c047df6cf612099a783a220fd61c215b3c75d5bf43c1a66580a0ee';

  Future<PriceCheckResult> checkPrice({
    required String product,
    required String city,
    required String unit,
    required String category,
    required String priceType,
  }) async {
    final query =
        '$product $unit $priceType price in $city Pakistan today $category';

    final uri = Uri.https('serpapi.com', '/search.json', {
      'engine': 'google',
      'q': query,
      'gl': 'pk',
      'hl': 'en',
      'api_key': _apiKey,
    });

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch price. Status: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    final List organicResults = data['organic_results'] ?? [];

    final List<int> prices = [];
    final List<PriceSource> sources = [];

    for (final item in organicResults) {
      final title = item['title']?.toString() ?? '';
      final snippet = item['snippet']?.toString() ?? '';
      final source = item['source']?.toString() ?? 'Unknown';

      final text = '$title $snippet';

      final matches = RegExp(
        r'(?:Rs\.?|PKR)\s?([0-9,]+)',
        caseSensitive: false,
      ).allMatches(text);

      for (final match in matches) {
        final raw = match.group(1)?.replaceAll(',', '');
        final price = int.tryParse(raw ?? '');

        if (price == null) continue;

        // Important filters
        if (unit.toLowerCase().contains('kg')) {
          if (price < 20 || price > 2000) continue;
        } else {
          if (price < 20 || price > 500000) continue;
        }

        prices.add(price);

        sources.add(
          PriceSource(
            source: source,
            title: title,
            price: 'Rs. $price',
            snippet: snippet,
          ),
        );
      }
    }

    if (prices.isEmpty) {
      return PriceCheckResult(
        product: product,
        city: city,
        estimatedPrice: 'Not found',
        priceRange: 'Not available',
        unit: unit,
        confidence: 'Low',
        note: 'No clear PKR price found. Try writing product more specifically.',
        priceSources: [],
      );
    }

    prices.sort();

    final minPrice = prices.first;
    final maxPrice = prices.last;

// Average from source card prices, with outlier removal
    final sourcePrices = sources.map((s) {
      final raw = s.price.replaceAll(RegExp(r'[^0-9]'), '');
      return int.tryParse(raw);
    }).whereType<int>().toList();

    sourcePrices.sort();

    List<int> averagePrices = List.from(sourcePrices);

// Remove lowest and highest outlier only if enough prices exist
    if (averagePrices.length >= 5) {
      averagePrices = averagePrices.sublist(1, averagePrices.length - 1);
    }

    final avgPrice = averagePrices.isEmpty
        ? (prices.reduce((a, b) => a + b) / prices.length).round()
        : (averagePrices.reduce((a, b) => a + b) / averagePrices.length).round();

    return PriceCheckResult(
      product: product,
      city: city,
      estimatedPrice: 'Rs. $avgPrice',
      priceRange: 'Rs. $minPrice - Rs. $maxPrice',
      unit: unit,
      confidence: prices.length >= 3 ? 'Good' : 'Medium',
      note: 'Estimated from Google Pakistan results. Price may vary by shop/date.',
      priceSources: sources.take(5).toList(),
    );
  }
}