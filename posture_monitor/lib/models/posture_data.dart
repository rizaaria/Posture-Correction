class PostureData {
  final DateTime timestamp;
  final int flexValue;
  final int leaningAngle;
  final int postureStatus; // 0: Good, 1: Warning, 2: Bad
  final double mpuAngle;

  PostureData({
    required this.timestamp,
    required this.flexValue,
    required this.leaningAngle,
    required this.postureStatus,
    this.mpuAngle = 0.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'flexValue': flexValue,
      'leaningAngle': leaningAngle,
      'postureStatus': postureStatus,
      'mpuAngle': mpuAngle,
    };
  }

  factory PostureData.fromJson(Map<String, dynamic> json) {
    return PostureData(
      timestamp: DateTime.parse(json['timestamp']),
      flexValue: json['flexValue'],
      leaningAngle: json['leaningAngle'],
      postureStatus: json['postureStatus'],
      mpuAngle: json['mpuAngle'] ?? 0.0,
    );
  }
}
