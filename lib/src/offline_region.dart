part of mapbox_gl;

class OfflineRegion {
  final String _id;
  final OfflineRegionOptions _offlineRegionOptions;

  const OfflineRegion(this._id, this._offlineRegionOptions);

  String get id => _id;
  OfflineRegionOptions get offlineRegionOptions => _offlineRegionOptions;
}

class OfflineRegionOptions {
  final String style;
  final LatLng northEastBound;
  final LatLng southWestBound;
  final double minZoom;
  final double maxZoom;
  final Map<String, dynamic> metadata;

  const OfflineRegionOptions(
      this.style,
      this.northEastBound,
      this.southWestBound,
      this.minZoom,
      this.maxZoom,
      this.metadata
  );

  dynamic _toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    json['style'] = style;
    json['northEastBound'] = northEastBound._toJson();
    json['southWestBound'] = southWestBound._toJson();
    json['minZoom'] = minZoom;
    json['maxZoom'] = maxZoom;
    json['metadata'] = metadata;

    return json;
  }
}