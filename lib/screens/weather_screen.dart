import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart'; 
import 'package:provider/provider.dart';
import '../services/weather_service.dart';
import '../services/risk_analysis_service.dart';
import '../models/weather_model.dart';
import '../models/plant_type.dart';
import '../widgets/risk_chart_widget.dart';
import '../widgets/city_search_sheet.dart';
import '../providers/map_controller.dart'; 
import '../data/turkey_cities.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();
  final RiskAnalysisService _riskService = RiskAnalysisService();

  WeatherData? _currentWeather;
  List<ForecastData> _forecast = [];
  bool _loading = true;
  String? _errorMessage;
  
  // States for Presentation / Logic
  PlantType _selectedPlant = PlantType.corn;
  bool _isGreenhouse = false; // Sera modu

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather({double? lat, double? lng}) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      late double latitude;
      late double longitude;
      
      if (lat != null && lng != null) {
        latitude = lat;
        longitude = lng;
      } else {
        final pos = await _determinePosition();
        latitude = pos.latitude;
        longitude = pos.longitude;
      }

      final current = await _weatherService.getCurrentWeather(latitude, longitude);
      final forecast = await _weatherService.getForecast(latitude, longitude);

      if (mounted) {
        setState(() {
          _currentWeather = current;
          _forecast = forecast;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _onCitySelected(City city) async {
    try {
        await _loadWeather(lat: city.lat, lng: city.lng);
        
        if (mounted) {
           Provider.of<MapController>(context, listen: false)
               .updateManualLocation(city.lat, city.lng);
               
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Konum güncellendi: ${city.name}"))
           );
        }
    } catch (e) {
      debugPrint("City selection error: $e");
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }
  
  String _formatDate(DateTime date) {
    return DateFormat('E, d MMM').format(date);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentWeather == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Hata")),
        body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Hata oluştu: $_errorMessage"),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () => _loadWeather(), child: const Text("Tekrar Dene"))
              ],
            )
        ),
      );
    }
    
    // ANALYZE RISK based on currently displayed data AND Greenhouse context
    final alerts = _riskService.analyzePlantAwareRisk(_currentWeather!, _forecast, _selectedPlant, isGreenhouse: _isGreenhouse);
    final explanation = _riskService.buildExplanation(_currentWeather!, _forecast, _selectedPlant, isGreenhouse: _isGreenhouse);

    final rainExpected = _forecast.any((f) => f.description.toLowerCase().contains("rain"));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              
              // GREENHOUSE TOGGLE
              Container(
                decoration: BoxDecoration(
                  color: _isGreenhouse ? Colors.green.shade50 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _isGreenhouse ? Colors.green : Colors.grey.shade300),
                ),
                child: SwitchListTile(
                  title: Text(
                    "Sera / Kapalı Alan Üretimi",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _isGreenhouse ? Colors.green.shade900 : Colors.grey.shade700
                    ),
                  ),
                  subtitle: const Text("Sera içi risk analizi için açın", style: TextStyle(fontSize: 12)),
                  value: _isGreenhouse,
                  // activeTrackColor removed to use theme default
                  onChanged: (val) {
                    setState(() {
                      _isGreenhouse = val;
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),

              _buildWeatherCard(_currentWeather!),
              const SizedBox(height: 20),
              _buildCropSelector(),
              const SizedBox(height: 24),
              const Row(
                children: [
                   Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
                   SizedBox(width: 8),
                   Text("Risk Uyarıları",
                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2E3E2E)),
                   ),
                ],
              ),
              const SizedBox(height: 12),
              ...alerts.map((alert) => _buildRiskCard(alert)),
               if (alerts.isEmpty && !rainExpected)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text("Yüksek risk tespit edilmedi.", style: TextStyle(color: Colors.green)),
                ),

              if (rainExpected) _buildRainWarningCard(),
              const SizedBox(height: 20),
              
                  _buildExplanationTile(explanation),
                  const SizedBox(height: 20),
              
              if (_forecast.isNotEmpty) ...[
                _buildRiskChartSection(_forecast),
                const SizedBox(height: 24),
              ],
              
              const Text("5 Günlük Tahmin",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2E3E2E)),
              ),
              const SizedBox(height: 12),
              _buildForecastList(_forecast),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Hava Durumu Analizi",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A4A4A),
          ),
        ),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50), 
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          onPressed: () async {
            final result = await showModalBottomSheet(
              context: context, 
              isScrollControlled: true,
              builder: (context) => const CitySearchSheet(),
            );
            
            if (result != null && result is City) {
               await _onCitySelected(result);
            } 
          },
          icon: const Icon(Icons.location_on, size: 16, color: Colors.white),
          label: const Text("Şehir Seç", style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }

  Widget _buildWeatherCard(WeatherData weather) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD), 
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                weather.city, 
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${weather.temp.toStringAsFixed(1)}°C",
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              Text(
                "Nem: %${weather.humidity}",
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          if (weather.icon.isNotEmpty)
            Image.network(
              'https://openweathermap.org/img/wn/${weather.icon}@2x.png',
              width: 80,
              height: 80,
              errorBuilder: (_, __, ___) => const Icon(Icons.wb_sunny, size: 60, color: Colors.orange),
            )
          else
             const Icon(Icons.wb_sunny, size: 60, color: Colors.orange),
        ],
      ),
    );
  }

  Widget _buildCropSelector() {
    return Stack(
      children: [
        Container(
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF43A047), width: 1.5),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<PlantType>(
              value: _selectedPlant,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              items: PlantType.values.map((PlantType plant) {
                return DropdownMenuItem<PlantType>(
                  value: plant,
                  child: Text(
                    plant.name.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                );
              }).toList(),
              onChanged: (PlantType? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedPlant = newValue;
                  });
                }
              },
            ),
          ),
        ),
        Positioned(
          left: 12,
          top: -0, 
          child: Container(
            color: Colors.white, 
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: const Text(
              "Ürün Seçin",
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF43A047),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRiskCard(RiskAlert alert) {
    Color bg = const Color(0xFFFFE0B2); 
    if (alert.severity == "High") bg = const Color(0xFFFFCDD2); 
    if (alert.severity == "Low") bg = const Color(0xFFC8E6C9); 

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning, color: Color(0xFF5D4037)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF4E342E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  alert.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRainWarningCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE0B2), 
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning, color: Color(0xFF5D4037)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Yağmur Tahmini",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF4E342E),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Yakında yağmur bekleniyor. Zirai ilaçlamayı ertelemeniz önerilir.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF5D4037),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
  
  Widget _buildExplanationTile(RiskExplanation explanation) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: Text(
          explanation.summary,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Color(0xFF333333),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...explanation.factors.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("• ", style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: _parseFormattedText(f)),
                    ],
                  ),
                )),
                
                if (explanation.suggestedAction.isNotEmpty) ...[
                   const SizedBox(height: 12),
                   _parseFormattedText(
                     "Önerilen Eylem:",
                     baseStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)
                   ),
                   const SizedBox(height: 4),
                   Container(
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(
                       color: Colors.green.shade50,
                       borderRadius: BorderRadius.circular(8),
                       border: Border.all(color: Colors.green.shade200),
                     ),
                     child: _parseFormattedText(
                       explanation.suggestedAction,
                       baseStyle: TextStyle(color: Colors.green.shade900)
                     ),
                   )
                ]
              ],
            ),
          )
        ],
      ),
    );
  }
  
  /// Helper to parse "**bold**" markdown into RichText
  Widget _parseFormattedText(String text, {TextStyle? baseStyle}) {
    final parts = text.split('**');
    List<TextSpan> spans = [];

    // Default styles
    TextStyle normalStyle = baseStyle ?? const TextStyle(color: Colors.black87);
    TextStyle boldStyle = normalStyle.copyWith(fontWeight: FontWeight.bold);

    for (int i = 0; i < parts.length; i++) {
      if (i % 2 == 0) {
        // Even index -> Normal text
        spans.add(TextSpan(text: parts[i], style: normalStyle));
      } else {
        // Odd index -> Bold text (inside **)
        spans.add(TextSpan(text: parts[i], style: boldStyle));
      }
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _buildForecastList(List<ForecastData> forecastList) {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: forecastList.length,
        itemBuilder: (context, index) {
          final f = forecastList[index];
          return Container(
            width: 100,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatDate(f.date),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (f.icon.isNotEmpty)
                  Image.network(
                    'https://openweathermap.org/img/wn/${f.icon}.png',
                    width: 40,
                    height: 40,
                    errorBuilder: (_,__,___) => const Icon(Icons.cloud, size: 30),
                  )
                else
                  const Icon(Icons.cloud, size: 30),
                const SizedBox(height: 4),
                Text(
                  "${f.temp.toStringAsFixed(1)}°C",
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRiskChartSection(List<ForecastData> forecastList) {
    if (forecastList.isEmpty) return const SizedBox.shrink();

    final scores = _riskService.calculateDailyRisks(forecastList, isGreenhouse: _isGreenhouse);
    final limit = scores.length > 7 ? 7 : scores.length;
    final limitedScores = scores.sublist(0, limit);
    
    final days = forecastList.take(limit).map((f) => DateFormat('E').format(f.date)).toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        title: const Row(
          children: [
            Icon(Icons.show_chart, color: Colors.blueGrey),
            SizedBox(width: 8),
            Text(
              "7 Günlük Kümülatif Risk Grafiği",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: Color(0xFF333333),
              ),
            ),
          ],
        ),
        children: [
           Padding(
             padding: const EdgeInsets.only(bottom: 16.0),
             child: RiskChartWidget(riskScores: limitedScores, days: days),
           ),
           const Padding(
             padding: EdgeInsets.only(bottom: 12.0),
             child: Text(
               "Nem ve Sıcaklık Bazlı Risk Skoru (%0-100)",
               style: TextStyle(fontSize: 12, color: Colors.grey),
             ),
           ),
        ],
      ),
    );
  }
}

