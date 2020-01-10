// Copyright 2018 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of mapbox_gl;

final MethodChannel _globalChannel =
    MethodChannel('plugins.flutter.io/mapbox_gl');

/// Copy tiles db file passed in to the tiles cache directory (sideloaded) to
/// make tiles available offline.
Future<void> installOfflineMapTiles(String tilesDb) async {
  await _globalChannel.invokeMethod(
    'installOfflineMapTiles',
    <String, dynamic>{
      'tilesdb': tilesDb,
    },
  );
}

Future<bool> downloadOfflineRegion(
    OfflineRegionOptions offlineRegionOptions) async {
  return _globalChannel.invokeMethod(
      'downloadOfflineRegion', offlineRegionOptions._toPayload());
}

Future<dynamic> listOfflineRegions() async {
  List<dynamic> returnedPayload =
      await _globalChannel.invokeListMethod('listOfflineRegions');
  List<OfflineRegionOptions> parsedOfflineRegions = [];
  for (dynamic region in returnedPayload) {
    parsedOfflineRegions.add(OfflineRegionOptions._fromPayload(region));
  }
  return parsedOfflineRegions;
}

Future<bool> deleteOfflineRegion(
    OfflineRegionOptions offlineRegionOptions) async {
  return _globalChannel.invokeMethod(
      'deleteOfflineRegion', offlineRegionOptions._toPayload());
}
