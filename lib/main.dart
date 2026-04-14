import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:file_picker/file_picker.dart';
import 'package:gal/gal.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:location/location.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  runApp(AccessResourcesApp(cameras: cameras));
}

class AccessResourcesApp extends StatelessWidget {
  const AccessResourcesApp({super.key, required this.cameras});

  final List<CameraDescription> cameras;

  @override
  Widget build(BuildContext context) {
    final CameraDescription? firstCamera =
        cameras.isNotEmpty ? cameras.first : null;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Access Resources',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: ResourceHomePage(camera: firstCamera),
    );
  }
}

class ResourceHomePage extends StatelessWidget {
  const ResourceHomePage({super.key, required this.camera});

  final CameraDescription? camera;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('2 Access Resources')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MenuTile(
            title: 'Camera',
            subtitle: 'Preview camera and save photos to gallery album',
            icon: Icons.camera_alt,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CameraPreviewScreen(camera: camera),
                ),
              );
            },
          ),
          _MenuTile(
            title: 'GPS',
            subtitle: 'Track and show current location on Google Maps',
            icon: Icons.location_on,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapWithLocation()),
              );
            },
          ),
          _MenuTile(
            title: 'File Manager',
            subtitle: 'Pick files and browse directories',
            icon: Icons.folder,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FilePickerScreen()),
              );
            },
          ),
          _MenuTile(
            title: 'Gallery / Image Picker',
            subtitle: 'Pick image from gallery',
            icon: Icons.photo_library,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GalleryScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class CameraPreviewScreen extends StatefulWidget {
  const CameraPreviewScreen({super.key, required this.camera});

  final CameraDescription? camera;

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    if (widget.camera != null) {
      _controller = CameraController(widget.camera!, ResolutionPreset.high);
      _initializeControllerFuture = _controller!.initialize();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || _initializeControllerFuture == null) {
      return;
    }

    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();
      await Gal.putImage(image.path, album: 'flutter_access_device_app');

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Picture saved to Gallery/flutter_access_device_app'),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error taking picture: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.camera == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Camera Access')),
        body: const Center(child: Text('No camera found on this device.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Camera Access')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done &&
              _controller != null) {
            return CameraPreview(_controller!);
          }
          if (snapshot.hasError) {
            return Center(child: Text('Failed to initialize camera: ${snapshot.error}'));
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: const Icon(Icons.camera),
      ),
    );
  }
}

class MapWithLocation extends StatefulWidget {
  const MapWithLocation({super.key});

  @override
  State<MapWithLocation> createState() => _MapWithLocationState();
}

class _MapWithLocationState extends State<MapWithLocation> {
  final Location _location = Location();
  LocationData? _currentLocation;
  GoogleMapController? _mapController;
  StreamSubscription<LocationData>? _locationSubscription;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _locationSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    final hasPermission = await _checkPermission();
    if (!hasPermission) {
      return;
    }

    final loc = await _location.getLocation();
    if (!mounted) {
      return;
    }

    setState(() {
      _currentLocation = loc;
      _updateMarker();
    });

    _locationSubscription = _location.onLocationChanged.listen((newLoc) {
      if (!mounted) {
        return;
      }

      setState(() {
        _currentLocation = newLoc;
        _updateMarker();
      });

      if (_mapController != null &&
          newLoc.latitude != null &&
          newLoc.longitude != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLng(LatLng(newLoc.latitude!, newLoc.longitude!)),
        );
      }
    });
  }

  Future<bool> _checkPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        return false;
      }
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return false;
      }
    }

    return true;
  }

  void _updateMarker() {
    if (_currentLocation == null ||
        _currentLocation!.latitude == null ||
        _currentLocation!.longitude == null) {
      return;
    }

    _markers
      ..clear()
      ..add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: LatLng(
            _currentLocation!.latitude!,
            _currentLocation!.longitude!,
          ),
          infoWindow: const InfoWindow(title: 'My Location'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentLocation?.latitude == null || _currentLocation?.longitude == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Track My Location')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Track My Location')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
            _currentLocation!.latitude!,
            _currentLocation!.longitude!,
          ),
          zoom: 16,
        ),
        markers: _markers,
        myLocationEnabled: true,
        onMapCreated: (controller) {
          _mapController = controller;
          setState(_updateMarker);
        },
      ),
    );
  }
}

class FilePickerScreen extends StatefulWidget {
  const FilePickerScreen({super.key});

  @override
  State<FilePickerScreen> createState() => _FilePickerScreenState();
}

class _FilePickerScreenState extends State<FilePickerScreen> {
  String _result = 'No file selected';

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _result = result != null
          ? 'Selected: ${result.files.single.name}'
          : 'No file selected';
    });
  }

  Future<void> _pickDirectory() async {
    final path = await FilePicker.platform.getDirectoryPath();

    if (!mounted) {
      return;
    }

    setState(() {
      _result = path != null ? 'Directory: $path' : 'No directory selected';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File Manager')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_result, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _pickFile,
                child: const Text('Pick a File'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickDirectory,
                child: const Text('Pick a Directory'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  Future<void> _pickFromGallery() async {
    final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) {
      return;
    }
    setState(() {
      _selectedImage = File(file.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gallery Picker')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _selectedImage != null
                ? Image.file(_selectedImage!, height: 300)
                : const Text('No image selected'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickFromGallery,
              child: const Text('Pick from Gallery'),
            ),
          ],
        ),
      ),
    );
  }
}
