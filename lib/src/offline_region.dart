part of mapbox_gl;

class OfflineRegionOptions {
  final String style;
  final LatLng northEastBound;
  final LatLng southWestBound;
  final double minZoom;
  final double maxZoom;
  final Map<String, String> metadata;

  const OfflineRegionOptions(
      this.style,
      this.northEastBound,
      this.southWestBound,
      this.minZoom,
      this.maxZoom,
      this.metadata
  );

  dynamic _toPayload() {
    final Map<String, dynamic> json = <String, dynamic>{};

    json['style'] = style;
    json['northEastBound'] = northEastBound._toJson();
    json['southWestBound'] = southWestBound._toJson();
    json['minZoom'] = minZoom;
    json['maxZoom'] = maxZoom;
    json['metadata'] = jsonEncode(metadata);

    return json;
  }

  static OfflineRegionOptions _fromPayload(Map<String, dynamic> payload) {
    return OfflineRegionOptions(
        payload['style'],
        LatLng(payload['northEastBound'][0], payload['northEastBound'][1]),
        LatLng(payload['southWestBound'][0], payload['southWestBound'][1]),
        payload['minZoom'],
        payload['maxZoom'],
        jsonDecode(payload['metadata'])
    );
  }
}