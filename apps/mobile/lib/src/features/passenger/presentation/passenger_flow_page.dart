import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../design/app_spacing.dart';
import '../../../design/components/app_button.dart';
import '../../../design/components/app_card.dart';
import '../../../design/components/app_scaffold.dart';
import '../../../design/components/app_text_field.dart';
import '../../auth/data/api_exception.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/location_reader.dart';
import '../data/passenger_repository.dart';
import '../domain/passenger_models.dart';
import '../domain/passenger_validators.dart';

class PassengerFlowPage extends StatefulWidget {
  const PassengerFlowPage({
    super.key,
    this.token,
    this.repository,
    this.locationReader,
  });

  final String? token;
  final PassengerRepository? repository;
  final LocationReader? locationReader;

  @override
  State<PassengerFlowPage> createState() => _PassengerFlowPageState();
}

class _PassengerFlowPageState extends State<PassengerFlowPage> {
  final _formKey = GlobalKey<FormState>();
  final _pickupLatitudeController = TextEditingController();
  final _pickupLongitudeController = TextEditingController();
  final _destinationNameController = TextEditingController();
  final _destinationLatitudeController = TextEditingController();
  final _destinationLongitudeController = TextEditingController();

  late String _token;
  bool _initialized = false;
  bool _isBusy = false;
  String? _error;
  PassengerProfile? _profile;
  PassengerRequest? _activeRequest;
  LocationReadResult? _locationResult;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_initialized) {
      return;
    }

    _token = widget.token ?? context.read<AuthController>().token ?? '';
    _initialized = true;
    _loadPassengerData();
  }

  @override
  void dispose() {
    _pickupLatitudeController.dispose();
    _pickupLongitudeController.dispose();
    _destinationNameController.dispose();
    _destinationLatitudeController.dispose();
    _destinationLongitudeController.dispose();
    super.dispose();
  }

  PassengerRepository get _repository =>
      widget.repository ?? const PassengerRepository();

  LocationReader get _locationReader =>
      widget.locationReader ?? const DeviceLocationReader();

  Future<void> _loadPassengerData() async {
    _setBusy(true);

    try {
      final profile = await _repository.fetchProfile(_token);
      final activeRequest = await _repository.fetchActiveRequest(_token);

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
        _activeRequest = activeRequest;
        _error = null;
        if (profile.hasCurrentLocation && _pickupLatitudeController.text.isEmpty) {
          _pickupLatitudeController.text = profile.currentLatitude.toString();
          _pickupLongitudeController.text = profile.currentLongitude.toString();
        }
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _useCurrentLocation() async {
    _setBusy(true);

    try {
      final result = await _locationReader.readCurrentLocation();

      if (!mounted) {
        return;
      }

      setState(() => _locationResult = result);

      if (!result.isSuccess) {
        return;
      }

      final profile = await _repository.updateCurrentLocation(
        token: _token,
        latitude: result.latitude!,
        longitude: result.longitude!,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
        _pickupLatitudeController.text = result.latitude.toString();
        _pickupLongitudeController.text = result.longitude.toString();
        _error = null;
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      _setBusy(false);
    }
  }

  Future<void> _submitWaitingHere() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _setBusy(true);

    try {
      final request = await _repository.createWaitingRequest(
        token: _token,
        pickupLatitude: double.parse(_pickupLatitudeController.text.trim()),
        pickupLongitude: double.parse(_pickupLongitudeController.text.trim()),
        destinationName: _destinationNameController.text.trim(),
        destinationLatitude:
            double.parse(_destinationLatitudeController.text.trim()),
        destinationLongitude:
            double.parse(_destinationLongitudeController.text.trim()),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _activeRequest = request;
        _error = null;
      });
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
      }
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool busy) {
    if (!mounted) {
      return;
    }
    setState(() {
      _isBusy = busy;
      if (busy) {
        _error = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'I’m Waiting Here',
      subtitle: 'Passenger request',
      actions: [
        IconButton(
          tooltip: 'Back to passenger home',
          onPressed: () => context.go('/passenger/home'),
          icon: const Icon(Icons.home_outlined),
        ),
      ],
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 860),
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AppCard(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Text(_error!),
                  ),
                ),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Passenger profile',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Class: ${_profile?.passengerClass ?? 'loading'}',
                    ),
                    Text(
                      'Saved location: ${_formatSavedLocation(_profile)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Current location',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Capture your GPS coordinates or enter them manually. '
                            'Verified MPDC zone boundaries are not yet available.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppButton(
                            label: 'Use my current GPS location',
                            icon: Icons.my_location,
                            variant: AppButtonVariant.outlined,
                            onPressed: _isBusy ? null : _useCurrentLocation,
                          ),
                          if (_locationResult != null &&
                              _locationResult!.status == LocationReadStatus.disabled)
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.md),
                              child: AppButton(
                                label: 'Enable GPS',
                                icon: Icons.settings,
                                variant: AppButtonVariant.text,
                                onPressed: _locationReader.openLocationSettings,
                              ),
                            ),
                          if (_locationResult != null)
                            Padding(
                              padding: const EdgeInsets.only(top: AppSpacing.md),
                              child: Text(_locationResult!.message),
                            ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Pickup latitude',
                            controller: _pickupLatitudeController,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            validator: validateLatitude,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Pickup longitude',
                            controller: _pickupLongitudeController,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            validator: validateLongitude,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildMapPreview(context),
                    const SizedBox(height: AppSpacing.md),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Destination',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Destination name',
                            controller: _destinationNameController,
                            prefixIcon: Icons.place_outlined,
                            validator: validateDestinationName,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Destination latitude',
                            controller: _destinationLatitudeController,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            validator: validateLatitude,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppTextField(
                            label: 'Destination longitude',
                            controller: _destinationLongitudeController,
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                            validator: validateLongitude,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    if (_isBusy)
                      const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.md),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                    AppButton(
                      label: 'I’m Waiting Here',
                      icon: Icons.person_pin_circle_outlined,
                      onPressed: _activeRequest == null && !_isBusy
                          ? _submitWaitingHere
                          : null,
                    ),
                  ],
                ),
              ),
              if (_activeRequest != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.lg),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active waiting request',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Status: ${_activeRequest!.status}'),
                        Text('Destination: ${_activeRequest!.destinationName}'),
                        Text('Requested: ${_activeRequest!.requestedAt.toLocal()}'),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMapPreview(BuildContext context) {
    final latitude = double.tryParse(_pickupLatitudeController.text.trim());
    final longitude = double.tryParse(_pickupLongitudeController.text.trim());

    if (latitude == null || longitude == null) {
      return AppCard(
        child: Text(
          'Enter valid pickup coordinates to preview the location on an OpenStreetMap map.',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final center = LatLng(latitude, longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 15),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.tricycle_matching',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 36,
                  height: 36,
                  child: const Icon(
                    Icons.person_pin_circle,
                    color: Colors.deepOrange,
                    size: 36,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatSavedLocation(PassengerProfile? profile) {
    if (profile == null || !profile.hasCurrentLocation) {
      return 'not captured';
    }
    return '${profile.currentLatitude}, ${profile.currentLongitude}';
  }
}
