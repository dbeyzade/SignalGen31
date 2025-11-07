enum SignalType {
  sine,
  square,
  triangle,
  sawtooth,
}

extension SignalTypeExtension on SignalType {
  String get name {
    switch (this) {
      case SignalType.sine:
        return 'Sine';
      case SignalType.square:
        return 'Square';
      case SignalType.triangle:
        return 'Triangle';
      case SignalType.sawtooth:
        return 'Sawtooth';
    }
  }

  String get icon {
    switch (this) {
      case SignalType.sine:
        return '〰️';
      case SignalType.square:
        return '⊓';
      case SignalType.triangle:
        return '△';
      case SignalType.sawtooth:
        return '⊿';
    }
  }
}
