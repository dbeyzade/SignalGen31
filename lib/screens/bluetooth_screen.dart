import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import '../services/bluetooth_service.dart';
import '../theme/app_theme.dart';

class BluetoothConnectionScreen extends StatefulWidget {
  const BluetoothConnectionScreen({Key? key}) : super(key: key);

  @override
  State<BluetoothConnectionScreen> createState() =>
      _BluetoothConnectionScreenState();
}

class _BluetoothConnectionScreenState extends State<BluetoothConnectionScreen> {
  bool _showFavorites = false;

  @override
  void initState() {
    super.initState();
    _checkBluetoothAndStart();
  }

  Future<void> _checkBluetoothAndStart() async {
    final bluetoothService = context.read<BluetoothService>();
    
    // Check if Bluetooth is available
    if (await fbp.FlutterBluePlus.isSupported == false) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth not supported on this device'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Start scanning
    await bluetoothService.startScan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.darkGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Consumer<BluetoothService>(
                  builder: (context, bluetoothService, child) {
                    if (_showFavorites) {
                      return _buildFavoritesView(bluetoothService);
                    } else if (bluetoothService.isConnected) {
                      return _buildConnectedView(bluetoothService);
                    } else if (bluetoothService.isScanning || bluetoothService.scanResults.isNotEmpty) {
                      return _buildScanningView(bluetoothService);
                    } else {
                      return _buildIdleView(bluetoothService);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bluetooth Connection',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Select oscilloscope device',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Consumer<BluetoothService>(
            builder: (context, bluetoothService, child) {
              return IconButton(
                icon: Icon(
                  _showFavorites ? Icons.bluetooth : Icons.favorite,
                  color: _showFavorites ? AppTheme.neonBlue : AppTheme.neonPink,
                  size: 28,
                ),
                onPressed: () {
                  setState(() {
                    _showFavorites = !_showFavorites;
                  });
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildScanningView(BluetoothService bluetoothService) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: AppTheme.multiColorGlow(),
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/logo.jpg',
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          bluetoothService.isScanning 
              ? 'Scanning for Devices...' 
              : 'Devices Found',
          style: Theme.of(context).textTheme.displayMedium,
        ),
        if (bluetoothService.isScanning)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              'Please wait...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
          ),
        const SizedBox(height: 40),
        Expanded(
          child: bluetoothService.scanResults.isEmpty
              ? Center(
                  child: bluetoothService.isScanning
                      ? CircularProgressIndicator(
                          color: AppTheme.neonBlue,
                        )
                      : Text(
                          'No devices found',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 16,
                          ),
                        ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: bluetoothService.scanResults.length,
                  itemBuilder: (context, index) {
                    final result = bluetoothService.scanResults[index];
                    return _buildDeviceCard(result, bluetoothService);
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: bluetoothService.isScanning
              ? ElevatedButton(
                  onPressed: () => bluetoothService.stopScan(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withOpacity(0.8),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: const Text('Stop Scanning'),
                )
              : ElevatedButton(
                  onPressed: () => bluetoothService.startScan(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonBlue.withOpacity(0.8),
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: const Text('Scan Again'),
                ),
        ),
      ],
    );
  }

  Widget _buildDeviceCard(fbp.ScanResult result, BluetoothService bluetoothService) {
    final device = result.device;
    final rssi = result.rssi;
    final deviceId = device.remoteId.toString();
    final isFav = bluetoothService.isFavorite(deviceId);
    final customName = bluetoothService.getCustomName(deviceId);
    
    // Try multiple sources for device name
    String deviceName = device.platformName;
    
    // If platformName is empty, try advName from advertisement data
    if (deviceName.isEmpty && result.advertisementData.advName.isNotEmpty) {
      deviceName = result.advertisementData.advName;
    }
    
    // If still empty, try localName
    if (deviceName.isEmpty && result.advertisementData.localName.isNotEmpty) {
      deviceName = result.advertisementData.localName;
    }
    
    // Check manufacturer data for Apple devices
    if (deviceName.isEmpty || deviceName == 'Unknown Device') {
      final mfgData = result.advertisementData.manufacturerData;
      if (mfgData.isNotEmpty) {
        // Apple company ID is 0x004C
        if (mfgData.containsKey(76)) {
          deviceName = 'Apple Device';
        }
      }
    }
    
    // If still empty, use a generic name with the last 4 chars of ID
    if (deviceName.isEmpty) {
      final id = device.remoteId.toString();
      final shortId = id.length > 4 ? id.substring(id.length - 4) : id;
      deviceName = 'BT Device ($shortId)';
    }

    // Calculate signal strength
    String signalStrength;
    Color signalColor;
    int signalBars;
    
    if (rssi >= -50) {
      signalStrength = 'Excellent';
      signalColor = Colors.green;
      signalBars = 4;
    } else if (rssi >= -70) {
      signalStrength = 'Good';
      signalColor = Colors.lightGreen;
      signalBars = 3;
    } else if (rssi >= -85) {
      signalStrength = 'Fair';
      signalColor = Colors.orange;
      signalBars = 2;
    } else {
      signalStrength = 'Weak';
      signalColor = Colors.red;
      signalBars = 1;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isFav ? AppTheme.neonPink.withOpacity(0.5) : AppTheme.neonBlue.withOpacity(0.3),
          width: isFav ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.neonBlue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bluetooth,
                color: AppTheme.neonBlue,
                size: 24,
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  return Container(
                    width: 3,
                    height: 4 + (index * 2),
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: BoxDecoration(
                      color: index < signalBars ? signalColor : Colors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (customName != null) ...[
                    Text(
                      customName,
                      style: const TextStyle(
                        color: AppTheme.neonPink,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      deviceName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ] else ...[
                    Text(
                      deviceName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                isFav ? Icons.star : Icons.star_border,
                color: isFav ? Colors.amber : Colors.grey,
                size: 24,
              ),
              onPressed: () async {
                if (isFav) {
                  await bluetoothService.removeFromFavorites(deviceId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Removed from favorites'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                } else {
                  final added = await bluetoothService.addToFavorites(deviceId, deviceName);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(added ? '⭐ Added to favorites!' : 'Already in favorites'),
                        backgroundColor: added ? Colors.green : Colors.orange,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  }
                }
              },
            ),
            if (isFav)
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  color: AppTheme.neonBlue,
                  size: 20,
                ),
                onPressed: () => _showRenameDialog(context, bluetoothService, deviceId, customName ?? deviceName),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              device.remoteId.toString(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.signal_cellular_alt,
                  size: 14,
                  color: signalColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '$signalStrength ($rssi dBm)',
                  style: TextStyle(
                    color: signalColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () async {
          // Show connecting message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text('Connecting to ${customName ?? deviceName}...'),
                ],
              ),
              duration: const Duration(seconds: 10),
              backgroundColor: AppTheme.neonBlue,
            ),
          );
          
          await bluetoothService.stopScan();
          final success = await bluetoothService.connectToDevice(device);
          
          // Clear the connecting message
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          
          if (success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Connected & Paired with ${customName ?? deviceName}'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
            Navigator.pop(context);
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('❌ Connection failed'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildConnectedView(BluetoothService bluetoothService) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.neonGreen.withOpacity(0.2),
              border: Border.all(
                color: AppTheme.neonGreen,
                width: 3,
              ),
              boxShadow: [
                AppTheme.neonGlow(AppTheme.neonGreen, blur: 20),
              ],
            ),
            child: const Icon(
              Icons.bluetooth_connected,
              size: 60,
              color: AppTheme.neonGreen,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Connected Successfully',
            style: Theme.of(context).textTheme.displayMedium,
          ),
          const SizedBox(height: 12),
          Text(
            bluetoothService.connectedDevice?.platformName ?? 'Device',
            style: TextStyle(
              color: AppTheme.neonGreen,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: ElevatedButton(
              onPressed: () {
                bluetoothService.disconnect();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.8),
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text('Disconnect'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleView(BluetoothService bluetoothService) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.neonBlue.withOpacity(0.2),
                border: Border.all(
                  color: AppTheme.neonBlue,
                  width: 3,
                ),
              ),
              child: const Icon(
                Icons.bluetooth,
                size: 60,
                color: AppTheme.neonBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Devices Found',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Press the button below to scan for Bluetooth devices',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => bluetoothService.startScan(),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text('Scan for Devices'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoritesView(BluetoothService bluetoothService) {
    final favorites = bluetoothService.favoriteDevices;

    if (favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border,
                size: 80,
                color: AppTheme.neonPink.withOpacity(0.5),
              ),
              const SizedBox(height: 24),
              Text(
                'No Favorites Yet',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 12),
              Text(
                'Add devices to favorites by tapping the ⭐ star icon when scanning',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                Icons.favorite,
                color: AppTheme.neonPink,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Favorite Devices',
                style: Theme.of(context).textTheme.displayMedium,
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              return _buildFavoriteCard(favorites[index], bluetoothService);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoriteCard(dynamic favorite, BluetoothService bluetoothService) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBg.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.neonPink.withOpacity(0.5),
          width: 2,
        ),
        boxShadow: [
          AppTheme.neonGlow(AppTheme.neonPink, blur: 10),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: AppTheme.neonPink.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.bluetooth,
            color: AppTheme.neonPink,
            size: 28,
          ),
        ),
        title: Text(
          favorite.displayName,
          style: const TextStyle(
            color: AppTheme.neonPink,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (favorite.customName != null) ...[
              const SizedBox(height: 4),
              Text(
                'Original: ${favorite.name}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              favorite.id,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.edit,
                color: AppTheme.neonBlue,
                size: 20,
              ),
              onPressed: () => _showRenameDialog(
                context,
                bluetoothService,
                favorite.id,
                favorite.customName ?? favorite.name,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
                size: 20,
              ),
              onPressed: () async {
                await bluetoothService.removeFromFavorites(favorite.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Removed from favorites'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
          ],
        ),
        onTap: () async {
          // Quick connect from favorites
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Text('Connecting to ${favorite.displayName}...')),
                ],
              ),
              duration: const Duration(seconds: 10),
              backgroundColor: AppTheme.neonPink,
            ),
          );
          
          // Start scan to find the device
          await bluetoothService.startScan();
          
          // Wait a bit for scan to find devices
          await Future.delayed(const Duration(seconds: 3));
          
          // Try to find and connect to the device
          final scanResult = bluetoothService.scanResults
              .where((r) => r.device.remoteId.toString() == favorite.id)
              .firstOrNull;
          
          // Clear connecting message
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          
          if (scanResult != null) {
            await bluetoothService.stopScan();
            final success = await bluetoothService.connectToDevice(scanResult.device);
            
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✅ Connected to ${favorite.displayName}'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
              Navigator.pop(context);
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('❌ Connection failed'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else {
            await bluetoothService.stopScan();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('❌ ${favorite.displayName} not found'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _showRenameDialog(BuildContext context, BluetoothService bluetoothService, String deviceId, String currentName) {
    final controller = TextEditingController(text: currentName);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.cardBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppTheme.neonBlue.withOpacity(0.5),
            width: 2,
          ),
        ),
        title: const Text(
          '📝 Rename Device',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter custom name',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.neonBlue.withOpacity(0.5)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppTheme.neonBlue, width: 2),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.white.withOpacity(0.7)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                await bluetoothService.updateDeviceName(deviceId, newName);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Renamed to "$newName"'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.neonBlue,
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
