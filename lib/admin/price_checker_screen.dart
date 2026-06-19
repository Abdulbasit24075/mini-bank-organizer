import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/services/price_check_service.dart';

class PriceCheckerScreen extends StatefulWidget {
  const PriceCheckerScreen({super.key});

  @override
  State<PriceCheckerScreen> createState() => _PriceCheckerScreenState();
}

class _PriceCheckerScreenState extends State<PriceCheckerScreen> {
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _productCtrl = TextEditingController();
  final TextEditingController _customUnitCtrl = TextEditingController();

  String selectedUnit = '1 kg';
  String selectedCategory = 'grocery';
  String selectedPriceType = 'retail';

  bool isLoading = false;
  String? errorMessage;
  PriceCheckResult? result;

  Future<void> checkPrice() async {
    final city = _cityCtrl.text.trim();
    final product = _productCtrl.text.trim();

    final unit = selectedUnit == 'Custom unit'
        ? _customUnitCtrl.text.trim()
        : selectedUnit;

    if (city.isEmpty || product.isEmpty) {
      setState(() {
        errorMessage = 'Please enter city and product name.';
      });
      return;
    }

    if (unit.isEmpty) {
      setState(() {
        errorMessage = 'Please enter custom unit.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
      result = null;
    });

    try {
      final res = await PriceCheckService().checkPrice(
        product: product,
        city: city,
        unit: unit,
        category: selectedCategory,
        priceType: selectedPriceType,
      );

      setState(() {
        result = res;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget inputDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget summaryCard() {
    final r = result!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Estimated Price',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            r.estimatedPrice,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${r.product} in ${r.city}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 6),
          Text(
            'Range: ${r.priceRange} | Unit: ${r.unit}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            'Confidence: ${r.confidence}',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget sourceCard(PriceSource source, int index) {
    final colors = [
      AppColors.card,
      AppColors.card,
      AppColors.card,
      AppColors.card,
      AppColors.card,
    ];

    return Card(
      color: colors[index % colors.length],
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              source.source,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
            const SizedBox(height: 6),
            Text(
              source.price,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              source.title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Text(
              source.snippet,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _productCtrl.dispose();
    _customUnitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = result;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Price Checker'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              color: AppColors.card,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _cityCtrl,
                      decoration: InputDecoration(
                        labelText: 'City Name',
                        hintText: 'Example: Lahore',
                        prefixIcon: const Icon(Icons.location_city),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextField(
                      controller: _productCtrl,
                      decoration: InputDecoration(
                        labelText: 'Product Name',
                        hintText: 'Example: sugar, rice, flour',
                        prefixIcon: const Icon(Icons.shopping_bag),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    inputDropdown(
                      label: 'Unit',
                      value: selectedUnit,
                      items: const [
                        '1 kg',
                        '5 kg',
                        '10 kg',
                        '40 kg',
                        '50 kg',
                        '1 litre',
                        '1 item',
                        'Custom unit',
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedUnit = value!;
                          if (selectedUnit != 'Custom unit') {
                            _customUnitCtrl.clear();
                          }
                        });
                      },
                    ),

                    if (selectedUnit == 'Custom unit') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _customUnitCtrl,
                        decoration: InputDecoration(
                          labelText: 'Enter Custom Unit',
                          hintText: 'Example: 250 gram, 1 dozen, 1 bag',
                          prefixIcon: const Icon(Icons.edit),
                          filled: true,
                          fillColor: AppColors.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    inputDropdown(
                      label: 'Category',
                      value: selectedCategory,
                      items: const [
                        'grocery',
                        'vegetable',
                        'fruit',
                        'meat',
                        'electronics',
                        'construction material',
                        'stationery',
                      ],
                      onChanged: (value) {
                        setState(() => selectedCategory = value!);
                      },
                    ),

                    const SizedBox(height: 12),

                    inputDropdown(
                      label: 'Price Type',
                      value: selectedPriceType,
                      items: const ['retail', 'wholesale', 'market', 'online'],
                      onChanged: (value) {
                        setState(() => selectedPriceType = value!);
                      },
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: isLoading ? null : checkPrice,
                        icon: const Icon(Icons.search),
                        label: Text(isLoading ? 'Checking...' : 'Check Price'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            if (isLoading) const CircularProgressIndicator(),

            if (errorMessage != null)
              Card(
                color: AppColors.card,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ),

            if (r != null) ...[
              summaryCard(),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Source Cards',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              if (r.priceSources.isEmpty)
                const Text('No source cards found.')
              else
                ...r.priceSources.asMap().entries.map(
                  (entry) => sourceCard(entry.value, entry.key),
                ),
              const SizedBox(height: 12),
              Text(r.note, style: TextStyle(color: Colors.grey.shade700)),
            ],
          ],
        ),
      ),
    );
  }
}
