import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/map_controller.dart';
import '../models/place_model.dart';
import '../widgets/city_search_sheet.dart'; 
import '../data/turkey_cities.dart'; 

class MapScreen extends StatefulWidget {
  final String diseaseName;
  
  const MapScreen({
    super.key, 
    required this.diseaseName,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<MapController>(context, listen: false)
          .loadCurrentLocationAndDealers(widget.diseaseName);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Nearby Dealers"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: "Search City",
            onPressed: () async {
              final result = await showModalBottomSheet(
                context: context, 
                isScrollControlled: true, // Allow full height
                builder: (context) => const CitySearchSheet()
              );
              
              if (result != null && result is City) {
                 // Trigger global sync & animation
                 if (context.mounted) {
                   Provider.of<MapController>(context, listen: false)
                       .updateManualLocation(result.lat, result.lng);
                   
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text("Flying to ${result.name}..."))
                   );
                 }
              }
            },
          )
        ],
      ),
      body: Consumer<MapController>(
        builder: (context, controller, child) {
          if (controller.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.error_outline, color: Colors.red, size: 48),
                   const SizedBox(height: 16),
                   Text("Error loading map", style: Theme.of(context).textTheme.titleLarge),
                   Padding(
                     padding: const EdgeInsets.all(16.0),
                     child: Text(controller.errorMessage!, textAlign: TextAlign.center),
                   ),
                   ElevatedButton(
                     onPressed: () => controller.loadCurrentLocationAndDealers(widget.diseaseName), 
                     child: const Text("Retry"),
                   )
                ],
              ),
            );
          }

          return Stack(
            children: [
              controller.currentPosition == null
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: controller.currentPosition!,
                      zoom: 12, 
                    ),
                    onMapCreated: controller.onMapCreated,
                    onCameraMove: controller.onCameraMove,
                    onCameraIdle: controller.onCameraIdle,
                    markers: controller.markers,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    padding: const EdgeInsets.only(bottom: 300, top: 40),
                    onTap: (_) => controller.clearSelection(),
                    zoomControlsEnabled: false, 
                  ),
              
              if (controller.isLoading)
                 Align(
                   alignment: Alignment.topCenter,
                   child: Container(
                     margin: const EdgeInsets.only(top: 80),
                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                     decoration: BoxDecoration(
                       color: Colors.white,
                       borderRadius: BorderRadius.circular(20),
                       boxShadow: [BoxShadow(blurRadius: 4, color: Colors.black26)]
                     ),
                     child: const Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                         SizedBox(width: 8),
                         Text("Searching area...", style: TextStyle(fontWeight: FontWeight.bold)),
                       ],
                     ),
                   ),
                 ),

              // Bottom Panel
              if (!controller.isLoading && controller.currentPosition != null)
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: _buildBottomCard(context, controller),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomCard(BuildContext context, MapController controller) {
    final PlaceModel? selected = controller.selectedPlace;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: AnimatedSize(
          duration: const Duration(milliseconds: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (selected != null) ...[
                // Selected Dealer View
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        selected.name,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => controller.clearSelection(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      selected.rating.toString(), 
                      style: const TextStyle(fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: selected.isOpen ? Colors.green.shade100 : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        selected.isOpen ? "OPEN" : "CLOSED",
                        style: TextStyle(
                          fontSize: 12, 
                          color: selected.isOpen ? Colors.green.shade800 : Colors.red.shade800,
                          fontWeight: FontWeight.bold
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.directions, color: Colors.white),
                  label: const Text("Get Directions", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => controller.launchDirections(selected.lat, selected.lng),
                ),
              ] else ...[
                // Default View
                Row(
                  children: [
                     const Icon(Icons.medical_services, color: Colors.green),
                     const SizedBox(width: 8),
                     Expanded(
                       child: Text(
                         'Searching: ${controller.targetDisease.isEmpty ? "All" : controller.targetDisease}',
                         style: const TextStyle(fontWeight: FontWeight.bold),
                       ),
                     ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Recommended: ${controller.recommendedMedicine}',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Move map or click Search for other cities.',
                  style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
