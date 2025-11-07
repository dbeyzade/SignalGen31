import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/signal_type.dart';
import '../models/signal_parameters.dart';
import '../models/signal_generator.dart';
import '../services/bluetooth_service.dart';
import '../services/audio_output_service.dart';
import '../services/ble_server_service.dart';
import '../theme/app_theme.dart';
import '../widgets/waveform_widget.dart';
import '../widgets/signal_type_selector.dart';
import '../widgets/neon_slider.dart';
import 'bluetooth_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  SignalType _selectedSignalType = SignalType.sine;
  SignalParameters _parameters = SignalParameters();
  bool _isTransmitting = false;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getSignalColor() {
    switch (_selectedSignalType) {
      case SignalType.sine:
        return AppTheme.neonBlue;
      case SignalType.square:
        return AppTheme.neonPurple;
      case SignalType.triangle:
        return AppTheme.neonGreen;
      case SignalType.sawtooth:
        return AppTheme.neonOrange;
    }
  }

  Future<void> _sendSignal() async {
    setState(() {
      _isTransmitting = true;
    });

    final bluetoothService = context.read<BluetoothService>();
    final bleServerService = context.read<BLEServerService>();
    
    // Generate samples (static method)
    final samples = SignalGenerator.generateSamples(
      _selectedSignalType,
      _parameters,
    );

    bool success = false;
    
    // Önce BLE server üzerinden dene (iPad için)
    if (bleServerService.isAdvertising) {
      debugPrint('🔵 Trying BLE Server...');
      success = await bleServerService.sendDataToClients(samples);
    }
    
    // BLE server çalışmıyorsa, normal Bluetooth kullan (Memo 777 - iPad paired)
    if (!success && bluetoothService.isConnected) {
      debugPrint('🔵 Trying normal Bluetooth...');
      success = await bluetoothService.sendSignalData(
        _selectedSignalType,
        _parameters,
        samples,
      );
    }

    setState(() {
      _isTransmitting = false;
    });

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Signal sent'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            bleServerService.isAdvertising
                ? '❌ iPad not connected - Try pairing first'
                : '❌ No connection - Start BLE server or connect via Bluetooth'
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
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
                child: isLandscape ? _buildLandscapeLayout() : _buildPortraitLayout(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(8), // Reduced from 16
      child: Column(
        children: [
          _buildWaveformSection(),
          const SizedBox(height: 8), // Reduced from 12
          
          SignalTypeSelector(
            selectedType: _selectedSignalType,
            onChanged: (type) {
              setState(() {
                _selectedSignalType = type;
              });
              final audioService = context.read<AudioOutputService>();
              if (audioService.isPlaying) {
                audioService.updateFrequency(
                  type,
                  _parameters.frequency,
                  _parameters.amplitude,
                );
              }
            },
          ),
          const SizedBox(height: 8), // Reduced from 12
          
          _buildParametersSection(),
          const SizedBox(height: 8), // Reduced from 12
          
          _buildTransmitButton(),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildWaveformSection(),
                const SizedBox(height: 16),
                SignalTypeSelector(
                  selectedType: _selectedSignalType,
                  onChanged: (type) {
                    setState(() {
                      _selectedSignalType = type;
                    });
                    final audioService = context.read<AudioOutputService>();
                    if (audioService.isPlaying) {
                      audioService.updateFrequency(
                        type,
                        _parameters.frequency,
                        _parameters.amplitude,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                _buildParametersSection(),
                const SizedBox(height: 20),
                _buildTransmitButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final logoSize = isLandscape ? 40.0 : 50.0;
    final titleFontSize = isLandscape ? 18.0 : 22.0;
    final iconSize = isLandscape ? 22.0 : 28.0;
    
    return Container(
      padding: EdgeInsets.all(isLandscape ? 12 : 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: logoSize,
                height: logoSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.multiColorGlow(),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/logo.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Signal Generator',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontSize: titleFontSize,
                      foreground: Paint()
                        ..shader = AppTheme.neonGradient.createShader(
                          const Rect.fromLTWH(0, 0, 200, 70),
                        ),
                    ),
                  ),
                  SizedBox(height: isLandscape ? 4 : 8),
                  Row(
                    children: [
                      Consumer<BluetoothService>(
                        builder: (context, bluetoothService, child) {
                          return Row(
                            children: [
                              Container(
                                width: isLandscape ? 8 : 10,
                                height: isLandscape ? 8 : 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: bluetoothService.isConnected
                                      ? AppTheme.neonGreen
                                      : Colors.grey,
                                  boxShadow: bluetoothService.isConnected
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.neonGreen.withOpacity(0.8),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : [],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                bluetoothService.isConnected
                                    ? 'BT: Connected'
                                    : 'BT: Off',
                                style: TextStyle(
                                  color: bluetoothService.isConnected
                                      ? AppTheme.neonGreen
                                      : Colors.grey,
                                  fontSize: isLandscape ? 10 : 11,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Consumer<AudioOutputService>(
                        builder: (context, audioService, child) {
                          return Row(
                            children: [
                              Container(
                                width: isLandscape ? 8 : 10,
                                height: isLandscape ? 8 : 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: audioService.isPlaying
                                      ? AppTheme.neonPink
                                      : Colors.grey,
                                  boxShadow: audioService.isPlaying
                                      ? [
                                          BoxShadow(
                                            color: AppTheme.neonPink.withOpacity(0.8),
                                            blurRadius: 8,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : [],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                audioService.isPlaying ? 'Audio: On' : 'Audio: Off',
                                style: TextStyle(
                                  color: audioService.isPlaying
                                      ? AppTheme.neonPink
                                      : Colors.grey,
                                  fontSize: isLandscape ? 10 : 11,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.cardBg,
                  boxShadow: [
                    AppTheme.neonGlow(AppTheme.neonPink, blur: 10),
                  ],
                ),
                child: Consumer<AudioOutputService>(
                  builder: (context, audioService, child) {
                    return IconButton(
                      icon: Icon(
                        audioService.isPlaying ? Icons.volume_up : Icons.volume_mute,
                        color: audioService.isPlaying ? AppTheme.neonPink : Colors.grey,
                      ),
                      iconSize: iconSize - 4,
                      onPressed: () async {
                        if (audioService.isPlaying) {
                          await audioService.stop();
                        } else {
                          await audioService.playTone(
                            _selectedSignalType,
                            _parameters.frequency,
                            _parameters.amplitude,
                          );
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.cardBg,
                  boxShadow: [
                    AppTheme.neonGlow(AppTheme.neonBlue, blur: 10),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.bluetooth, color: AppTheme.neonBlue),
                  iconSize: iconSize,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const BluetoothConnectionScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformSection() {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Waveform',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12, // Reduced from 14
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6), // Reduced from 8
        AnimatedWaveformWidget(
          signalType: _selectedSignalType,
          parameters: _parameters,
          height: isLandscape ? 120 : 140, // Reduced from 150:180
        ),
      ],
    );
  }

  Widget _buildParametersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parameters',
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12, // Reduced from 14
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6), // Reduced from 8
        
        NeonSlider(
          label: 'Frequency',
          value: _parameters.frequency,
          min: 1,
          max: 10000,
          divisions: 9999,
          unit: 'Hz',
          color: AppTheme.neonBlue,
          icon: Icons.waves,
          onChanged: (value) {
            setState(() {
              _parameters = _parameters.copyWith(frequency: value);
            });
            final audioService = context.read<AudioOutputService>();
            if (audioService.isPlaying) {
              audioService.updateFrequency(
                _selectedSignalType,
                value,
                _parameters.amplitude,
              );
            }
          },
        ),
        NeonSlider(
          label: 'Amplitude',
          value: _parameters.amplitude,
          min: 0.1,
          max: 10.0,
          divisions: 99,
          unit: 'V',
          color: AppTheme.neonPurple,
          icon: Icons.show_chart,
          onChanged: (value) {
            setState(() {
              _parameters = _parameters.copyWith(amplitude: value);
            });
            final audioService = context.read<AudioOutputService>();
            if (audioService.isPlaying) {
              audioService.updateFrequency(
                _selectedSignalType,
                _parameters.frequency,
                value,
              );
            }
          },
        ),
        NeonSlider(
          label: 'Phase',
          value: _parameters.phase,
          min: 0,
          max: 360,
          divisions: 360,
          unit: '°',
          color: AppTheme.neonGreen,
          icon: Icons.rotate_right,
          onChanged: (value) {
            setState(() {
              _parameters = _parameters.copyWith(phase: value);
            });
          },
        ),
        NeonSlider(
          label: 'DC Offset',
          value: _parameters.offset,
          min: -5.0,
          max: 5.0,
          divisions: 100,
          unit: 'V',
          color: AppTheme.neonYellow,
          icon: Icons.vertical_align_center,
          onChanged: (value) {
            setState(() {
              _parameters = _parameters.copyWith(offset: value);
            });
          },
        ),
      ],
    );
  }

  Widget _buildTransmitButton() {
    return Consumer2<BluetoothService, BLEServerService>(
      builder: (context, bluetoothService, bleServerService, child) {
        return Column(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: bleServerService.isAdvertising
                      ? [Colors.green.withOpacity(0.3), Colors.green.withOpacity(0.1)]
                      : [AppTheme.neonPurple.withOpacity(0.3), AppTheme.neonBlue.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: bleServerService.isAdvertising ? Colors.green : AppTheme.neonBlue,
                  width: 2,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () async {
                    if (bleServerService.isAdvertising) {
                      await bleServerService.stopAdvertising();
                    } else {
                      await bleServerService.startAdvertising();
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          bleServerService.isAdvertising ? Icons.stop_circle : Icons.broadcast_on_personal,
                          color: bleServerService.isAdvertising ? Colors.green : AppTheme.neonBlue,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          bleServerService.isAdvertising ? 'Stop BLE Server' : 'Start BLE Server',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            if (bleServerService.isAdvertising) ...[
              const SizedBox(height: 8),
              Text(
                bleServerService.status,
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _isTransmitting ? null : _sendSignal,
              style: ElevatedButton.styleFrom(
                backgroundColor: _getSignalColor(),
                foregroundColor: AppTheme.darkBg,
                minimumSize: const Size(double.infinity, 64),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: _isTransmitting
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: AppTheme.darkBg,
                            strokeWidth: 3,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Sending...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.send,
                          size: 24,
                          color: AppTheme.darkBg,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Send Signal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
