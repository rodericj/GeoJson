//
//  ContentView.swift
//  GeoJson
//
//  Created by Roderic Campbell on 9/23/20.
//

import SwiftUI
import MapKit
import Foundation

struct ContentView: View {
    let mapView = GeoJsonMapView()

    var body: some View {
        mapView.onAppear {
            mapView.fetch(pasteString: UIPasteboard.general.string)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct GeoJsonMapView: UIViewRepresentable {
    let decoder = MKGeoJSONDecoder()
    let mapView = MKMapView()

    func makeUIView(context: Context) -> MKMapView {
        mapView.delegate = context.coordinator
        return mapView
    }
    func updateUIView(_ mapView: MKMapView, context _: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func fetch(pasteString: String?) {
        let url: URL
        if let urlString = pasteString, !urlString.isEmpty, let pastedURL = URL(string: urlString), pastedURL.scheme != nil, pastedURL.host != nil {
            print("pasted url from \(pastedURL)")
            url = pastedURL
        } else if let oregon = URL(string: "https://raw.githubusercontent.com/UCDavisLibrary/ava/master/avas_by_state/OR_avas.geojson") {
            url = oregon
        } else if let france = URL(string: "https://raw.githubusercontent.com/ouwxmaniac/BordeauxWineRegions/master/Bordeaux-AOP_Bordeaux_France.geojson") {
            url = france
        } else {
            print("no url")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let shapes = try decoder.decode(data)
            print(shapes.count)
            shapes
                .map { $0 as? MKGeoJSONFeature }
                .compactMap { $0 }
                .forEach { feature in
                    feature.geometry
                        .map { $0 as? MKMultiPolygon  }
                        .compactMap { $0 }
                        .forEach { multiPolygon in
                            multiPolygon.polygons.forEach { mapView.addOverlay($0) }
                        }
                }
            var zoomRect:MKMapRect = .null

            mapView.overlays.forEach { overlay in
                zoomRect = zoomRect.union(overlay.boundingMapRect)
            }
            mapView.setVisibleMapRect(zoomRect, animated: true)
        } catch {
            print("There was an error \(error)")
        }
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: GeoJsonMapView
        init(_ parent: GeoJsonMapView) {
            self.parent = parent
        }

        func mapView(_: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if overlay is MKCircle {
                let renderer = MKCircleRenderer(overlay: overlay)
                renderer.fillColor = UIColor.black.withAlphaComponent(0.5)
                renderer.strokeColor = UIColor.blue
                renderer.lineWidth = 2
                return renderer

            } else if overlay is MKPolyline {
                let renderer = MKPolylineRenderer(overlay: overlay)
                renderer.strokeColor = UIColor.orange
                renderer.lineWidth = 3
                return renderer

            } else if overlay is MKPolygon {
                let renderer = MKPolygonRenderer(polygon: overlay as! MKPolygon)
                renderer.fillColor = UIColor.purple.withAlphaComponent(0.5)
                renderer.strokeColor = UIColor.red
                renderer.lineWidth = 1
                return renderer
            } else if let multiPolygon  = overlay as? MKMultiPolygon {
                let renderer = MKPolygonRenderer(overlay: multiPolygon)
                renderer.fillColor = UIColor.purple.withAlphaComponent(0.5)
                renderer.strokeColor = UIColor.blue
                renderer.lineWidth = 3
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}

