//
//  MainMapView.swift
//  geospatial-notepad
//
//  Created by Alex Yang on 11/25/21.
//

import UIKit
import ArcGIS
import CoreLocation

class MainMapView: UIViewController, SelectedSymbolDelegate, AGSGeoViewTouchDelegate, CLLocationManagerDelegate {
    
    // map location variables
    private let locationManager = CLLocationManager()
    private var userLatLng: CLLocationCoordinate2D?; // user coords
    
    // current grid type
    private var currentGridType: GridType? = nil;
    
    // map symbol variables
    private var isSymbolMode = false
    private var currentMarkersList: [AGSGraphic] = [];
    private var currentMarkersIndex = -1;
    private var currentMarkersCapacity = 0;
    private var currentSymbolImage: UIImage?;
    
    // map sketch editor variables
    private let sketchEditor = AGSSketchEditor()
    private var graphicsOverlay = AGSGraphicsOverlay()
    private var isSketchMode = false
    
    // all buttons
    @IBOutlet weak var UndoButton: UIButton!
    @IBOutlet weak var RedoButton: UIButton!
    @IBOutlet weak var CurrentSymbol: UIImageView!
    @IBOutlet weak var MapStatus: UILabel!
    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var BaseLayerButton: UIButton!
    @IBOutlet weak var SketchButton: UIButton!
    
    // list of sketch modes
    private let creationModes: KeyValuePairs = [
        "Arrow": AGSSketchCreationMode.arrow,
        "Ellipse": .ellipse,
        "FreehandPolygon": .freehandPolygon,
        "FreehandPolyline": .freehandPolyline,
        "Polygon": .polygon,
        "Polyline": .polyline,
        "Rectangle": .rectangle,
        "Triangle": .triangle
    ]
    
    // different map layer types
    private let basemapInfoArray: [(basemap: AGSBasemap, label: String)] = [
        (.init(style: .arcGISDarkGrayBase), "Dark Gray Canvas"),
        (.init(style: .arcGISImageryStandard), "Imagery"),
        (.init(style: .arcGISImagery), "Imagery w/ Labels"),
        (.init(style: .arcGISLightGrayBase), "Light Gray Canvas"),
        (.init(style: .arcGISNavigation), "Navigation"),
        (.init(style: .arcGISNavigationNight), "Navigation Night"),
        (.init(style: .osmStreets), "OpenStreetMap"),
        (.init(style: .arcGISStreetsNight), "Streets Night"),
        (.init(style: .osmStreetsRelief), "Streets w/ Relief"),
        (.init(style: .arcGISTerrain), "Terrain w/ Labels"),
        (.init(style: .arcGISTopographic), "Topographic"),
        (.init(style: .arcGISHillshadeLight), "Hillshade Light"),
        (.init(style: .arcGISHillshadeDark), "Hillshade Dark"),
        (.init(style: .arcGISNova), "Nova")
    ]
    
    // init grid stuff
    private enum GridType: Int, CaseIterable {
        case latLong, mgrs, usng

        init?(grid: AGSGrid) {
            switch grid {
                case is AGSLatitudeLongitudeGrid: self = .latLong
                case is AGSMGRSGrid: self = .mgrs
                case is AGSUSNGGrid: self = .usng
                default: return nil
            }
        }
        var label: String {
            switch self {
                case .latLong: return "LatLong"
                case .mgrs: return "MGRS"
                case .usng: return "USNG"
            }
        }
    }
    
    // center map on user position
    @IBAction func centerOnUserLoc(_ sender: Any) {
        centerOnUserLocation()
    }
    
    // screenshot map to photos
    @IBAction func ScreenshotAction(_ sender: Any) {
        self.mapView.exportImage { [weak self] (image: UIImage?, error: Error?) in
            // handle error case
            if error != nil {
                let alert = UIAlertController(title: "ScreenShot Failed", message: "Error Saving Map to Photos", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
            // handle nonerror case
            if let nonNilImage = image {
                UIImageWriteToSavedPhotosAlbum(nonNilImage, nil, nil, nil)
                let alert = UIAlertController(title: "Success", message: "Map Saved to Photos", preferredStyle: UIAlertController.Style.alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
                self?.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    // clear all icons/sketches off the map
    @IBAction func ClearMap(_ sender: Any) {
        self.mapView.graphicsOverlays.remove(self.graphicsOverlay)
        self.graphicsOverlay = AGSGraphicsOverlay()
        self.mapView.graphicsOverlays.add(graphicsOverlay)
    }
    
    // bring up sketch menu
    @IBAction func startSketch(_ sender: Any) {
        let alert = UIAlertController(
            title: "Select Sketch Mode",
            message: nil,
            preferredStyle: .actionSheet
        )
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = SketchButton
            presenter.sourceRect = SketchButton.bounds
        }
        
        for item in creationModes {
            alert.addAction(
                .init(title: item.key, style: .default) { _ in
                    self.sketchEditor.start(with: nil, creationMode: item.value)
                    self.isSketchMode = true
                    self.MapStatus.text = "Entered Sketch Mode"
                    if (self.isSymbolMode) {
                        self.exitSymbol()
                    }
                    self.RedoButton.isEnabled = true
                    self.UndoButton.isEnabled = true
                }
            )
        }
        present(alert, animated: true);
    }
    
    // change base map layer
    @IBAction func ChangeMapBase(_ sender: Any) {
        let alert = UIAlertController(
            title: "Select Layer",
            message: nil,
            preferredStyle: .actionSheet
        )
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = BaseLayerButton
            presenter.sourceRect = BaseLayerButton.bounds
        }
        
        for item in basemapInfoArray {
            alert.addAction(
                .init(title: item.label, style: .default) { _ in
                    self.mapView?.map?.basemap = item.basemap
                }
            )
        }
        present(alert, animated: true);
    }
    
    // undo symbol / sketch
    @IBAction func undoSymbol(_ sender: Any) {
        if (isSymbolMode) {
            undoSymbolHelper();
        } else if (isSketchMode) {
            guard sketchEditor.undoManager.canUndo else { return }
            sketchEditor.undoManager.undo()
        }
    }
    
    // redo symbol / sketch
    @IBAction func redoSymbol(_ sender: Any) {
        if (isSymbolMode) {
            redoSymbolHelper();
        } else if (isSketchMode) {
            guard sketchEditor.undoManager.canRedo else { return }
            sketchEditor.undoManager.redo()
        }
    }
    
    // exit symbol/sketch mode
    @IBAction func ExitMode(_ sender: Any) {
        if (isSymbolMode) {
            exitSymbol()
        } else if (isSketchMode) {
            exitSketch()
        }
    }
    
    // change map grid type
    @IBAction func GridButton(_ sender: Any) {
        let alert = UIAlertController(
            title: "Select Layer",
            message: nil,
            preferredStyle: .actionSheet
        )
        if let presenter = alert.popoverPresentationController {
            presenter.sourceView = BaseLayerButton
            presenter.sourceRect = BaseLayerButton.bounds
        }
        let gridTypes = GridType.allCases.map { (type) -> GridType in
            return type
        }
        
        // add no grid option
        alert.addAction(
            .init(title: "No Grid", style: .default) { _ in
                self.currentGridType = nil
                self.resetGrid()
            }
        )
        for gridType in gridTypes {
            alert.addAction(
                .init(title: gridType.label, style: .default) { _ in
                    print(gridType)
                    self.currentGridType = gridType
                    self.resetGrid()
                }
            )
        }
        present(alert, animated: true);
    }
    
    // center on user loc
    private func centerOnUserLocation() {
        if (userLatLng == nil) {
            return
        }
        self.mapView.setViewpoint(
            AGSViewpoint(
                latitude: userLatLng!.latitude,
                longitude: userLatLng!.longitude,
                scale: 72_000
            )
        )
    }
    
    // standard location manager boilerplate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else {
            return
        }
        userLatLng = locValue
    }

    
    // set symbol on map
    func setSymbol(_ symbol: UIImage) {
        if (isSketchMode) {
            exitSketch()
        }
        self.currentSymbolImage = symbol
        CurrentSymbol.image = symbol
        isSymbolMode = true
        UndoButton.isEnabled = true
        RedoButton.isEnabled = true
        self.MapStatus.text = "Entered Symbol Mode"
        
    }

    // func to create a grid
    private func makeGrid(type: GridType) -> AGSGrid {
        switch type {
            case .latLong: return AGSLatitudeLongitudeGrid()
            case .mgrs: return AGSMGRSGrid()
            case .usng: return AGSUSNGGrid()
        }
    }
    
    // standard arcgis code from tutorial to scale grid to zoom level
    private func resetGrid() {
        if (self.currentGridType == nil) {
            self.mapView.grid?.isVisible = false
        } else {
            let newGrid = makeGrid(type: self.currentGridType ?? .mgrs)
            mapView?.grid = newGrid
            self.mapView.grid?.isVisible = true
            for gridLevel in 0..<newGrid.levelCount {
                let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: .black, width: CGFloat(gridLevel + 1))
                newGrid.setLineSymbol(lineSymbol, forLevel: gridLevel)
             }
        }
    }
    
    // get out of symbol mode
    private func exitSymbol() {
        self.isSymbolMode = false
        self.CurrentSymbol.image = nil
        UndoButton.isEnabled = false
        RedoButton.isEnabled = false
        self.MapStatus.text = "Free Scroll Mode"
    }
    
    // get out of sketch mode
    private func exitSketch() {
        self.isSketchMode = false
        UndoButton.isEnabled = false
        RedoButton.isEnabled = false
        self.MapStatus.text = "Free Scroll Mode"
        sketchEditor.stop()
        let geo = sketchEditor.geometry!
        let lineSymbol = AGSSimpleLineSymbol(style: .solid, color: .red, width: 3)
        self.graphicsOverlay.graphics.add(AGSGraphic(geometry: geo, symbol: lineSymbol, attributes: nil))
    }
    
    // add symbol to map on tap
    internal func geoView(_ geoView: AGSGeoView, didTapAtScreenPoint screenPoint: CGPoint, mapPoint: AGSPoint) {
        // create pin symbol using the image
        if (self.currentSymbolImage == nil || !isSymbolMode) {
            return
        }
        let pinSymbol = AGSPictureMarkerSymbol(image: self.currentSymbolImage!)
        // location for pin
        let pinPoint = AGSPoint(x: mapPoint.x, y: mapPoint.y, spatialReference: .webMercator())

        // graphic for pin
        let graphic = AGSGraphic(geometry: pinPoint, symbol: pinSymbol, attributes: nil)

        // add the graphic to the queue for redo/undo
        if self.currentMarkersList.count == currentMarkersIndex + 1 {
            currentMarkersList.append(graphic);
            self.currentMarkersIndex += 1;
            self.currentMarkersCapacity = currentMarkersIndex + 1;
            self.graphicsOverlay.graphics.add(graphic)
        } else {
            self.currentMarkersIndex += 1;
            self.currentMarkersCapacity = currentMarkersIndex + 1;
            self.currentMarkersList[currentMarkersIndex] = graphic
            self.graphicsOverlay.graphics.add(graphic)
        }
    }
    
    // undo symbol helper
    private func undoSymbolHelper() {
        if currentMarkersIndex < 0 || !isSymbolMode {
            return
        }
        self.graphicsOverlay.graphics.remove(currentMarkersList[self.currentMarkersIndex]);
        self.currentMarkersIndex -= 1;
    }
    
    // redo symbol helper
    private func redoSymbolHelper() {
        if (currentMarkersIndex >= currentMarkersCapacity - 1 || currentMarkersIndex >= currentMarkersList.capacity - 1 || !isSymbolMode) {
            return
        } else {
            currentMarkersIndex += 1
            self.graphicsOverlay.graphics.add(currentMarkersList[self.currentMarkersIndex]);
        }
    }
    
    // set up initial map
    private func setupMap() {
        let map = AGSMap(
            basemapStyle: .arcGISDarkGray
        )
        mapView.map = map
        mapView.setViewpoint(
            AGSViewpoint(
                latitude: 34.02700,
                longitude: -118.80500,
                scale: 72_000
            )
        )

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // do the location stuff
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
        
        self.mapView.touchDelegate = self
        self.mapView.graphicsOverlays.add(graphicsOverlay)
        UndoButton.setTitleColor(UIColor.gray, for: .disabled)
        RedoButton.setTitleColor(UIColor.gray, for: .disabled)
        UndoButton.isEnabled = false
        RedoButton.isEnabled = false
        mapView.sketchEditor = sketchEditor
        self.MapStatus.text = "Free Scroll Mode"
        setupMap()
    }
    
    // segue code
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToNatoSelector" {
            let destNVC = segue.destination as! UINavigationController
            let destVC = destNVC.topViewController as! NatoPicker
            destVC.delegate = self
        }
    }

}

