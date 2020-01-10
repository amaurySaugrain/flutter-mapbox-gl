import Flutter
import UIKit
import Mapbox

public class SwiftMapboxGlFlutterPlugin: NSObject, FlutterPlugin {
    fileprivate static var downloadResult: FlutterResult? = nil
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let instance = MapboxMapFactory(withRegistrar: registrar)
        registrar.register(instance, withId: "plugins.flutter.io/mapbox_gl")

        let channel = FlutterMethodChannel(name: "plugins.flutter.io/mapbox_gl", binaryMessenger: registrar.messenger())
        
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackProgressDidChange), name: NSNotification.Name.MGLOfflinePackProgressChanged, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackDidReceiveError), name: NSNotification.Name.MGLOfflinePackError, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(offlinePackDidReceiveMaximumAllowedMapboxTiles), name: NSNotification.Name.MGLOfflinePackMaximumMapboxTilesReached, object: nil)

        channel.setMethodCallHandler { (methodCall, result) in
            switch(methodCall.method) {
            case "installOfflineMapTiles":
                guard let arguments = methodCall.arguments as? [String: String] else { return }
                let tilesdb = arguments["tilesdb"]
                installOfflineMapTiles(registrar: registrar, tilesdb: tilesdb!)
                result(nil)
            case "downloadOfflineRegion":
                guard let arguments = methodCall.arguments as? [String: AnyObject] else { return }
                
                let metadata = arguments["metadata"]
                let style = arguments["style"] as! String
                let northEastBoundString = arguments["northEastBound"] as! Array<Double>
                let northEastBound = CLLocationCoordinate2DMake(northEastBoundString[0], northEastBoundString[1])
                let southWestBoundString = arguments["southWestBound"] as! Array<Double>
                let southWestBound = CLLocationCoordinate2DMake(southWestBoundString[0], southWestBoundString[1])
                let minZoom = arguments["minZoom"] as! Double
                let maxZoom = arguments["maxZoom"] as! Double
                
                let region = MGLTilePyramidOfflineRegion(styleURL: URL.init(string: style),
                                                         bounds: MGLCoordinateBounds(sw: southWestBound, ne: northEastBound),
                                                         fromZoomLevel: minZoom,
                                                         toZoomLevel: maxZoom)
                
                MGLOfflineStorage.shared.addPack(for: region, withContext: metadata as! Data, completionHandler: {(pack, error) in
                    guard error == nil else {
                        result(error?.localizedDescription)
                        return
                    }
                    
                    downloadResult = result
                    pack!.resume()
                })
            case "listOfflineRegions":
                result(MGLOfflineStorage.shared.packs) // TODO encode
            case "deleteOfflineRegion":
                guard let arguments = methodCall.arguments as? [String: AnyObject] else { return }
                
                let metadata = arguments["metadata"]
                let style = arguments["style"] as! String
                let northEastBoundString = arguments["northEastBound"] as! Array<Double>
                let northEastBound = CLLocationCoordinate2DMake(northEastBoundString[0], northEastBoundString[1])
                let southWestBoundString = arguments["southWestBound"] as! Array<Double>
                let southWestBound = CLLocationCoordinate2DMake(southWestBoundString[0], southWestBoundString[1])
                let minZoom = arguments["minZoom"] as! Double
                let maxZoom = arguments["maxZoom"] as! Double
                
                let region = MGLTilePyramidOfflineRegion(styleURL: URL.init(string: style),
                                                         bounds: MGLCoordinateBounds(sw: southWestBound, ne: northEastBound),
                                                         fromZoomLevel: minZoom,
                                                         toZoomLevel: maxZoom)
                for pack in MGLOfflineStorage.shared.packs! {
                    // TODO if pack matches region
                    MGLOfflineStorage.shared.removePack(pack, withCompletionHandler: {(error) in
                        guard error == nil else {
                            result(error?.localizedDescription)
                            return
                        }
                    
                        result(nil)
                    })
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    @objc static func offlinePackProgressDidChange(notification: NSNotification) {
        if let pack = notification.object as? MGLOfflinePack {
            let progress = pack.progress

            let completedResources = progress.countOfResourcesCompleted
            let expectedResources = progress.countOfResourcesExpected
            
            if completedResources == expectedResources {
                downloadResult!(nil)
            }
        }
    }
    
    @objc static func offlinePackDidReceiveError(notification: NSNotification) {
        if let error = notification.userInfo?[MGLOfflinePackUserInfoKey.error] as? NSError {
            downloadResult!(error.localizedFailureReason)
            downloadResult = nil
        }
    }
    
    @objc static func offlinePackDidReceiveMaximumAllowedMapboxTiles(notification: NSNotification) {
        downloadResult!("Maximum # tiles reached")
        downloadResult = nil
    }

    private static func getTilesUrl() -> URL {
        guard var cachesUrl = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first,
            let bundleId = Bundle.main.object(forInfoDictionaryKey: kCFBundleIdentifierKey as String) as? String else {
                fatalError("Could not get map tiles directory")
        }
        cachesUrl.appendPathComponent(bundleId)
        cachesUrl.appendPathComponent(".mapbox")
        cachesUrl.appendPathComponent("cache.db")
        return cachesUrl
    }

    // Copies the "offline" tiles to where Mapbox expects them
    private static func installOfflineMapTiles(registrar: FlutterPluginRegistrar, tilesdb: String) {
        var tilesUrl = getTilesUrl()
        let bundlePath = getTilesDbPath(registrar: registrar, tilesdb: tilesdb)
        NSLog("Cached tiles not found, copying from bundle... \(String(describing: bundlePath)) ==> \(tilesUrl)")
        do {
            let parentDir = tilesUrl.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: parentDir, withIntermediateDirectories: true, attributes: nil)
            if FileManager.default.fileExists(atPath: tilesUrl.path) {
                try FileManager.default.removeItem(atPath: tilesUrl.path)
            }
            try FileManager.default.copyItem(atPath: bundlePath!, toPath: tilesUrl.path)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try tilesUrl.setResourceValues(resourceValues)
        } catch let error {
            NSLog("Error copying bundled tiles: \(error)")
        }
    }
    
    private static func getTilesDbPath(registrar: FlutterPluginRegistrar, tilesdb: String) -> String? {
        if (tilesdb.starts(with: "/")) {
            return tilesdb;
        } else {
            let key = registrar.lookupKey(forAsset: tilesdb)
            return Bundle.main.path(forResource: key, ofType: nil)
        }
    }
}
