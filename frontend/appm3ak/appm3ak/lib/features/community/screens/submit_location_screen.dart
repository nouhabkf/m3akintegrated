import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/location/current_position.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../data/models/location_model.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/community_providers.dart';

/// Écran de soumission d'un nouveau lieu accessible.
class SubmitLocationScreen extends ConsumerStatefulWidget {
  const SubmitLocationScreen({super.key});

  @override
  ConsumerState<SubmitLocationScreen> createState() =>
      _SubmitLocationScreenState();
}

class _SubmitLocationScreenState extends ConsumerState<SubmitLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomController = TextEditingController();
  final _adresseController = TextEditingController();
  final _villeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _horairesController = TextEditingController();

  LocationCategory _selectedCategory = LocationCategory.other;
  List<File> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _useCurrentLocation = false;
  bool _loadingLocation = false;
  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _nomController.dispose();
    _adresseController.dispose();
    _villeController.dispose();
    _descriptionController.dispose();
    _telephoneController.dispose();
    _horairesController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final images = await _imagePicker.pickMultiImage();
    setState(() {
      _selectedImages = images.map((img) => File(img.path)).toList();
    });
    }

  Future<void> _pickImageFromCamera() async {
    final image = await _imagePicker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _selectedImages = [File(image.path)];
      });
    }
  }

  Future<void> _fetchCurrentLocation(AppStrings strings) async {
    if (kIsWeb) return;
    setState(() => _loadingLocation = true);
    try {
      final pos = await getCurrentPositionOrNull();
      if (!mounted) return;
      if (pos == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.locationUnavailable)),
        );
        return;
      }
      setState(() {
        _latitude = pos.latitude;
        _longitude = pos.longitude;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.locationUpdated)),
      );
    } finally {
      if (mounted) setState(() => _loadingLocation = false);
    }
  }

  Future<void> _submitLocation() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.fr().errorGeneric)),
      );
      return;
    }

    // Fallback Tunis si l'utilisateur ne veut pas joindre sa position.
    const fallbackLat = 36.8065;
    const fallbackLng = 10.1815;

    if (_useCurrentLocation && (_latitude == null || _longitude == null)) {
      await _fetchCurrentLocation(strings);
      if (_latitude == null || _longitude == null) return;
    }
    final lat = _useCurrentLocation ? _latitude! : fallbackLat;
    final lng = _useCurrentLocation ? _longitude! : fallbackLng;

    try {
      final repository = ref.read(locationRepositoryProvider);
      await repository.submitLocation(
        nom: _nomController.text.trim(),
        categorie: _selectedCategory.toApiString(),
        adresse: _adresseController.text.trim(),
        ville: _villeController.text.trim(),
        latitude: lat,
        longitude: lng,
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        telephone: _telephoneController.text.trim().isEmpty
            ? null
            : _telephoneController.text.trim(),
        horaires: _horairesController.text.trim().isEmpty
            ? null
            : _horairesController.text.trim(),
        amenities: null, // TODO: Ajouter un champ pour les amenities
        images: _selectedImages.isEmpty ? null : _selectedImages,
      );
      
      // Invalider la liste des lieux pour rafraîchir
      ref.invalidate(locationsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.fromPreferredLanguage(user.preferredLanguage?.name)
                .locationSubmittedSuccess),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      print('❌ [SubmitLocationScreen] Erreur: $e');
      if (e is DioException) {
        print('   Status Code: ${e.response?.statusCode}');
        print('   Response Data: ${e.response?.data}');
        print('   Request URL: ${e.requestOptions.uri}');
        print('   Request Data: ${e.requestOptions.data}');
      }
      
      if (mounted) {
        String errorMessage = AppStrings.fr().errorGeneric;
        if (e is DioException) {
          if (e.response?.statusCode == 401) {
            errorMessage = 'Vous devez être connecté pour soumettre un lieu';
          } else if (e.response?.statusCode == 400) {
            errorMessage = 'Données invalides: ${e.response?.data}';
          } else if (e.response?.data != null) {
            final data = e.response?.data;
            if (data is Map && data.containsKey('message')) {
              errorMessage = data['message'] as String;
            } else {
              errorMessage = 'Erreur: ${e.response?.data}';
            }
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final strings =
        AppStrings.fromPreferredLanguage(user?.preferredLanguage?.name);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(strings.submitNewPlace),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              strings.submitLocationDescription,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            // Nom du lieu
            TextFormField(
              controller: _nomController,
              decoration: InputDecoration(
                labelText: strings.placeName,
                hintText: strings.placeNameHint,
                prefixIcon: const Icon(Icons.place),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return strings.fieldRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Catégorie
            DropdownButtonFormField<LocationCategory>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: strings.category,
                prefixIcon: const Icon(Icons.category),
              ),
              items: LocationCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category.displayName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
            ),
            const SizedBox(height: 16),
            // Adresse
            TextFormField(
              controller: _adresseController,
              decoration: InputDecoration(
                labelText: strings.address,
                hintText: strings.addressHint,
                prefixIcon: const Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return strings.fieldRequired;
                }
                return null;
              },
            ),
            if (!kIsWeb) ...[
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _useCurrentLocation,
                        onChanged: (v) async {
                          setState(() => _useCurrentLocation = v);
                          if (v && (_latitude == null || _longitude == null)) {
                            await _fetchCurrentLocation(strings);
                          }
                        },
                        title: Text(strings.useCurrentLocation),
                        subtitle: Text(strings.locationHelpMessage),
                      ),
                      if (_useCurrentLocation) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: _loadingLocation
                                  ? null
                                  : () => _fetchCurrentLocation(strings),
                              icon: _loadingLocation
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.my_location),
                              label: Text(strings.location),
                            ),
                            if (_latitude != null && _longitude != null)
                              Chip(
                                avatar: const Icon(
                                  Icons.gps_fixed,
                                  size: 18,
                                ),
                                label: Text(
                                  '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            // Ville
            TextFormField(
              controller: _villeController,
              decoration: InputDecoration(
                labelText: strings.city,
                hintText: strings.cityHint,
                prefixIcon: const Icon(Icons.location_city),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return strings.fieldRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            // Téléphone (optionnel)
            TextFormField(
              controller: _telephoneController,
              decoration: InputDecoration(
                labelText: '${strings.phoneNumber} (${strings.optional})',
                hintText: '+216 XX XXX XXX',
                prefixIcon: const Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            // Horaires (optionnel)
            TextFormField(
              controller: _horairesController,
              decoration: InputDecoration(
                labelText: '${strings.openingHours} (${strings.optional})',
                hintText: 'Lun-Ven: 9h-18h',
                prefixIcon: const Icon(Icons.access_time),
              ),
            ),
            const SizedBox(height: 16),
            // Description (optionnel)
            TextFormField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: '${strings.description} (${strings.optional})',
                hintText: strings.descriptionHint,
                prefixIcon: const Icon(Icons.description),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            // Images
            Text(
              strings.images,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_selectedImages.isEmpty)
              Container(
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outline,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: _pickImages,
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate,
                        size: 32,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        strings.addImages,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              _selectedImages[index],
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.red,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                color: Colors.white,
                                onPressed: () {
                                  setState(() {
                                    _selectedImages.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton.icon(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.photo_library),
                  label: Text(strings.fromGallery),
                ),
                TextButton.icon(
                  onPressed: _pickImageFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(strings.fromCamera),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Bouton soumettre
            ElevatedButton(
              onPressed: _submitLocation,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                strings.submit,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              strings.submitLocationNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

