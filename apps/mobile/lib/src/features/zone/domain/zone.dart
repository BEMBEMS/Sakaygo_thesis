class TodaOption {
  const TodaOption({
    required this.todaId,
    required this.code,
    required this.name,
    required this.serviceAreaName,
    this.zoneCode,
  });

  final String todaId;
  final String code;
  final String name;
  final String serviceAreaName;
  final String? zoneCode;

  factory TodaOption.fromJson(Map<String, dynamic> json) {
    return TodaOption(
      todaId: json['todaId'] as String? ?? json['toda_id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      serviceAreaName: json['serviceAreaName'] as String? ??
          json['service_area_name'] as String? ??
          '',
      zoneCode: json['zoneCode'] as String? ?? json['zone_code'] as String?,
    );
  }

  String get displayName => '$code · $name';
}

class ZoneSummary {
  const ZoneSummary({
    required this.zoneId,
    required this.code,
    required this.name,
    required this.zoneStatus,
    required this.coverageDescription,
    required this.geojsonSource,
    required this.hasBoundary,
    required this.allowCrossZone,
    this.todaOrgId,
  });

  final String zoneId;
  final String code;
  final String name;
  final String zoneStatus;
  final String coverageDescription;
  final String geojsonSource;
  final bool hasBoundary;
  final bool allowCrossZone;
  final String? todaOrgId;

  bool get isActive => zoneStatus == 'active';

  factory ZoneSummary.fromJson(Map<String, dynamic> json) {
    return ZoneSummary(
      zoneId: json['zoneId'] as String? ?? json['zone_id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      zoneStatus: json['zoneStatus'] as String? ?? json['zone_status'] as String? ?? 'inactive',
      coverageDescription: json['coverageDescription'] as String? ??
          json['coverage_description'] as String? ??
          '',
      geojsonSource: json['geojsonSource'] as String? ??
          json['geojson_source'] as String? ??
          '',
      hasBoundary: json['hasBoundary'] as bool? ?? json['has_boundary'] as bool? ?? false,
      allowCrossZone: json['allowCrossZone'] as bool? ??
          json['allow_cross_zone'] as bool? ??
          false,
      todaOrgId:
          json['todaOrgId'] as String? ?? json['toda_org_id'] as String?,
    );
  }
}
