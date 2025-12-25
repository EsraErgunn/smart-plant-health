import 'package:flutter/material.dart';
import '../services/geocoding_service.dart';
import '../models/city_model.dart';

class CitySearchSheet extends StatefulWidget {
  const CitySearchSheet({super.key});

  @override
  State<CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends State<CitySearchSheet> {
  final GeocodingService _service = GeocodingService();
  final TextEditingController _controller = TextEditingController();

  List<City> _results = [];
  bool _loading = false;

  // 🔍 DÜZELTİLMİŞ SEARCH
  Future<void> _search(String value) async {
    final query = value.trim().toLowerCase();

    if (query.length < 3) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);

    try {
      final cities = await _service.searchCity(query);
      setState(() => _results = cities);
    } catch (_) {
      setState(() => _results = []);
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Column(
            children: [
              const SizedBox(height: 8),

              const Text(
                "Select City",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _controller,
                  onChanged: _search,
                  decoration: const InputDecoration(
                    hintText: "Search city...",
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),

              // ⬇️ DÜZELTİLMİŞ EXPANDED
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _results.isEmpty
                        ? Center(
                            child: Text(
                              _controller.text.length < 3
                                  ? "Type at least 3 characters"
                                  : "No city found",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: _results.length,
                            itemBuilder: (_, i) {
                              final city = _results[i];
                              return ListTile(
                                leading:
                                    const Icon(Icons.location_city),
                                title: Text(city.name),
                                subtitle: Text(city.country),
                                onTap: () =>
                                    Navigator.pop(context, city),
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
