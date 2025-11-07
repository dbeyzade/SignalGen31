class SignalParameters {
  final double frequency; // Hz
  final double amplitude; // Volts (0.0 - 5.0)
  final double phase; // Degrees (0 - 360)
  final double offset; // DC offset (-5.0 to 5.0)
  
  SignalParameters({
    this.frequency = 1000.0,
    this.amplitude = 3.3,
    this.phase = 0.0,
    this.offset = 0.0,
  });

  SignalParameters copyWith({
    double? frequency,
    double? amplitude,
    double? phase,
    double? offset,
  }) {
    return SignalParameters(
      frequency: frequency ?? this.frequency,
      amplitude: amplitude ?? this.amplitude,
      phase: phase ?? this.phase,
      offset: offset ?? this.offset,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'frequency': frequency,
      'amplitude': amplitude,
      'phase': phase,
      'offset': offset,
    };
  }
}
