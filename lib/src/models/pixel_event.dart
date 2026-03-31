/// Pixel event from listener
class PixelEvent {
  final String type;
  final String timestamp;
  final String? error;

  PixelEvent(this.type, this.timestamp, [this.error]);

  factory PixelEvent.fromMap(Map<String, dynamic> map) {
    return PixelEvent(
      map['type'],
      map['timestamp'],
      map['error'],
    );
  }

  bool get isAppearance => type == 'appearance';
  bool get isDisappearance => type == 'disappearance';
  bool get isRefresh => type == 'refresh';
  bool get isError => type == 'error';

}
