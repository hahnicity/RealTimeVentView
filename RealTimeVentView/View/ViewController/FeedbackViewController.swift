//
//  FeedbackViewController.swift
//  RealTimeVentView
//
//  Created by user149673 on 3/3/19.
//  Copyright © 2019 CCIL. All rights reserved.
//

import UIKit
import Charts
import CorePlot

enum Classification {
    case dta, bsa, tvv, norm, none
}

class FeedbackViewController: UIViewController {
    
    @IBOutlet weak var chartView: LineChartView!
    @IBOutlet weak var hostView: CPTGraphHostingView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var submitButton: UIBarButtonItem!
    
    var marker: CPTPlotSpaceAnnotation? = nil
    var patient = PatientModel()
    var pinchGestureRecognizer = UIPinchGestureRecognizer()
    var startTime = Date()
    var endTime = Date()
    var classification: [Classification] = [Classification](repeating: .none, count: Storage.numFeedbackBreaths)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.collectionView.delegate = self
        self.collectionView.dataSource = self
        

        initPlot()
        // Do any additional setup after loading the view.
    }
    
    func initPlot() {
        let spinner = showSpinner()
        pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(ChartViewController.handlePinchGesture))
        hostView.addGestureRecognizer(pinchGestureRecognizer)
        let graph = CPTXYGraph(frame: hostView.bounds)
        hostView.hostedGraph = graph
        hostView.isUserInteractionEnabled = false
        hostView.allowPinchScaling = false
        graph.paddingLeft = 5.0
        graph.paddingTop = 0.0
        graph.paddingRight = 0.0
        graph.paddingBottom = 0.0
        
        graph.plotAreaFrame?.paddingLeft = 45.0
        graph.plotAreaFrame?.paddingRight = 0.0
        graph.plotAreaFrame?.paddingTop = 10.0
        graph.plotAreaFrame?.paddingBottom = 35.0
        
        let plotSpace = graph.defaultPlotSpace as! CPTXYPlotSpace
        plotSpace.allowsUserInteraction = true
        plotSpace.yRange = CPTPlotRange(location: -100.0, length: 200.0)
        plotSpace.globalYRange = CPTPlotRange(location: -200.0, length: 400.0)
        //plotSpace.allowsMomentumX = true
        plotSpace.delegate = self
        
        
        let axisSet = graph.axisSet as! CPTXYAxisSet
        
        // Define the style for the gridlines
        let minorGridStyle = CPTMutableLineStyle()
        minorGridStyle.lineColor = CPTColor.lightGray()
        
        let majorGridStyle = CPTLineStyle()
        
        
        if let x = axisSet.xAxis, let y = axisSet.yAxis {
            x.majorIntervalLength   = Int(truncating: plotSpace.xRange.length) / 4 as NSNumber
            x.minorTicksPerInterval = 4
            x.axisConstraints = CPTConstraints(lowerOffset: 0.0)
            x.majorGridLineStyle = majorGridStyle
            x.minorGridLineStyle = minorGridStyle
            
            y.majorGridLineStyle = majorGridStyle
            y.minorGridLineStyle = minorGridStyle
            y.majorIntervalLength   = 50.0
            y.minorTicksPerInterval = 4
            y.axisConstraints = CPTConstraints(lowerOffset: 0.0)
            
            axisSet.axes = [x, y]
        }
        
        let flowChart = CPTScatterPlot()
        flowChart.delegate = self
        flowChart.dataSource = self
        flowChart.identifier = NSString(string: "flow")
        flowChart.showLabels = false
        
        let flowLine = CPTMutableLineStyle()
        flowLine.lineWidth = 1.0
        flowLine.lineColor = .blue()
        flowChart.dataLineStyle = flowLine
        
        let pressureChart = CPTScatterPlot()
        pressureChart.delegate = self
        pressureChart.dataSource = self
        pressureChart.identifier = NSString(string: "pressure")
        pressureChart.showLabels = false
        
        let pressureLine = CPTMutableLineStyle()
        pressureLine.lineWidth = 1.0
        pressureLine.lineColor = .red()
        pressureChart.dataLineStyle = pressureLine
        
        let asyncChart = CPTScatterPlot()
        asyncChart.delegate = self
        asyncChart.dataSource = self
        asyncChart.identifier = NSString(string: "async")
        asyncChart.dataLineStyle = nil
        
        graph.add(flowChart)
        graph.add(pressureChart)
        graph.add(asyncChart)
        
        graph.legend = CPTLegend(plots: [flowChart, pressureChart])
        graph.legendDisplacement = CGPoint(x: 0.0, y: -10.0)
        
        let markerTextStyle = CPTMutableTextStyle()
        markerTextStyle.color = .white()
        markerTextStyle.fontName = "Helvetica"
        markerTextStyle.fontSize = 14.0
        
        let markerTextLayer = CPTTextLayer(text: "", style: markerTextStyle)
        markerTextLayer.fill = CPTFill(color: .gray())
        markerTextLayer.cornerRadius = 10.0
        markerTextLayer.paddingTop = 5.0
        markerTextLayer.paddingBottom = 5.0
        markerTextLayer.paddingLeft = 5.0
        markerTextLayer.paddingRight = 5.0
        markerTextLayer.isHidden = true
        
        let marker = CPTPlotSpaceAnnotation(plotSpace: plotSpace, anchorPlotPoint: [0, 0])
        marker.contentLayer = markerTextLayer
        graph.addAnnotation(marker)
        self.marker = marker
        
        
        patient.loadBreaths(between: startTime, and: endTime) { (_, _, off, error) in
            if let error = error {
                self.removeSpinner(spinner)
                DispatchQueue.main.async {
                    self.hostView.isUserInteractionEnabled = true
                }
                self.showAlert(withTitle: "Chart Load Error", message: error.localizedDescription)
                return
            }
            if off.count == 0 {
                self.removeSpinner(spinner)
                DispatchQueue.main.async {
                    self.hostView.isUserInteractionEnabled = true
                }
                return
            }
            if let x = axisSet.xAxis {
                print("Format x")
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "HH:mm:ss"
                let timeFormatter = CPTTimeFormatter(dateFormatter: dateFormatter)
                timeFormatter.referenceDate = self.patient.refDate
                x.labelFormatter = timeFormatter
                x.relabel()
            }
            print("Adding graphs")
            
            plotSpace.globalXRange = CPTPlotRange(location: NSNumber(value: self.patient.offsets[0]), length: NSNumber(value: self.patient.offsets[self.patient.offsets.count - 1] - self.patient.offsets[0]))
            plotSpace.xRange = CPTPlotRange(location: NSNumber(value: self.patient.offsets[self.patient.offsets.count - 1] - 30.0), length: NSNumber(value: 30.0))
            graph.reloadData()
            DispatchQueue.main.async {
                self.hostView.isUserInteractionEnabled = true
                self.removeSpinner(spinner)
                axisSet.xAxis?.relabel()
                axisSet.yAxis?.relabel()
            }
        }
        
    }
    
    @IBAction func submitPressed(_ sender: UIBarButtonItem) {
        let id = patient.getBreathID()
        let breaths = zip(id, classification).map { (id, classification) -> [Any] in
            var val: [Any] = []
            val.append(id)
            switch classification {
            case .dta: val.append("dta")
            case .bsa: val.append("bsa")
            case .tvv: val.append("tvv")
            case .norm: val.append("norm")
            default: ()
            }
            return val
        }
        print(["patient": patient.name, "breaths": breaths])
        ServerModel.shared.feedback(with: ["patient": patient.name, "breaths": breaths]) { (data, error) in
            switch((data, error)) {
            case(.some(let data), .none):
                DispatchQueue.main.async {
                    self.navigationController?.popViewController(animated: true)
                }
            case(.none, .some(let error)):
                self.showAlert(withTitle: "Feedback Error", message: error.localizedDescription)
            default: ()
            }
        }
    }
    
    func checkAllClassified() {
        for breath in classification {
            if breath == .none {
                return
            }
        }
        submitButton.isEnabled = true
    }
    
    @objc func handlePinchGesture() {
        print("is being called")
        if pinchGestureRecognizer.numberOfTouches < 2 {
            return
        }
        var interactionPoint = pinchGestureRecognizer.location(in: hostView)
        var touchPoint1 = pinchGestureRecognizer.location(ofTouch: 0, in: hostView)
        var touchPoint2 = pinchGestureRecognizer.location(ofTouch: 1, in: hostView)
        let scale = pinchGestureRecognizer.scale
        let dY = abs(touchPoint1.y - touchPoint2.y)
        let dX = abs(touchPoint1.x - touchPoint2.x)
        let scaleX = 1.0 + (scale - 1.0) * dX / (dX + dY)
        let scaleY = 1.0 + (scale - 1.0) * dY / (dX + dY)
        guard let hostedGraph = hostView.hostedGraph else {
            return
        }
        
        hostedGraph.frame = hostView.bounds
        hostedGraph.layoutIfNeeded()
        
        if hostView.collapsesLayers {
            interactionPoint.y = hostView.frame.size.height - interactionPoint.y
            touchPoint1.y = hostView.frame.size.height - touchPoint1.y
            touchPoint2.y = hostView.frame.size.height - touchPoint2.y
        }
        else {
            interactionPoint = hostView.layer.convert(interactionPoint, to: hostedGraph)
            touchPoint1 = hostView.layer.convert(touchPoint1, to: hostedGraph)
            touchPoint2 = hostView.layer.convert(touchPoint2, to: hostedGraph)
        }
        
        let pointInPlotArea = hostedGraph.convert(interactionPoint, to: hostedGraph.plotAreaFrame?.plotArea)
        
        for space in hostedGraph.allPlotSpaces() {
            if space.allowsUserInteraction {
                scalePlotSpace(byX: scaleX, Y: scaleY, aboutPoint: pointInPlotArea, in: space)
            }
        }
        
        pinchGestureRecognizer.scale = 1.0;
    }
    
    func scalePlotSpace(byX scaleX: CGFloat, Y scaleY: CGFloat, aboutPoint interactionPoint: CGPoint, in space: CPTPlotSpace) {
        guard let plotArea = space.graph?.plotAreaFrame?.plotArea,
            let space = space as? CPTXYPlotSpace,
            scaleX > CGFloat(Float("1e-6")!),
            scaleY > CGFloat(Float("1e-6")!),
            plotArea.contains(interactionPoint) else {
                return
        }
        let decimalXScale = CPTDecimalFromCGFloat(scaleX)
        let decimalYScale = CPTDecimalFromCGFloat(scaleY)
        let plotInteractionPoint = UnsafeMutablePointer<Decimal>.allocate(capacity: 2)
        space.plotPoint(plotInteractionPoint, numberOfCoordinates: 2, forPlotAreaViewPoint: interactionPoint)
        
        let oldRangeX = space.xRange
        let oldRangeY = space.yRange
        
        let newLengthX = CPTDecimalDivide(oldRangeX.lengthDecimal, decimalXScale)
        let newLengthY = CPTDecimalDivide(oldRangeY.lengthDecimal, decimalYScale)
        
        var newLocationX = Decimal()
        if CPTDecimalGreaterThanOrEqualTo(oldRangeX.lengthDecimal, CPTDecimalFromInteger(0)) {
            let oldFirstLengthX = CPTDecimalSubtract(plotInteractionPoint[CPTCoordinate.X.rawValue], oldRangeX.minLimitDecimal)
            let newFirstLengthX = CPTDecimalDivide(oldFirstLengthX, decimalXScale)
            newLocationX = CPTDecimalSubtract(plotInteractionPoint[CPTCoordinate.X.rawValue], newFirstLengthX)
        }
        else {
            let oldSecondLengthX = CPTDecimalSubtract(oldRangeX.maxLimitDecimal, plotInteractionPoint[0])
            let newSecondLengthX = CPTDecimalDivide(oldSecondLengthX, decimalXScale)
            newLocationX = CPTDecimalAdd(plotInteractionPoint[CPTCoordinate.X.rawValue], newSecondLengthX)
        }
        
        var newLocationY = Decimal()
        if CPTDecimalGreaterThanOrEqualTo(oldRangeY.lengthDecimal, CPTDecimalFromInteger(0)) {
            let oldFirstLengthY = CPTDecimalSubtract(plotInteractionPoint[CPTCoordinate.Y.rawValue], oldRangeY.minLimitDecimal)
            let newFirstLengthY = CPTDecimalDivide(oldFirstLengthY, decimalYScale)
            newLocationY = CPTDecimalSubtract(plotInteractionPoint[CPTCoordinate.Y.rawValue], newFirstLengthY)
        }
        else {
            let oldSecondLengthY = CPTDecimalSubtract(oldRangeY.maxLimitDecimal, plotInteractionPoint[1])
            let newSecondLengthY = CPTDecimalDivide(oldSecondLengthY, decimalYScale)
            newLocationY = CPTDecimalAdd(plotInteractionPoint[CPTCoordinate.Y.rawValue], newSecondLengthY)
        }
        
        let newRangeX = CPTPlotRange(locationDecimal: newLocationX, lengthDecimal: newLengthX)
        let newRangeY = CPTPlotRange(locationDecimal: newLocationY, lengthDecimal: newLengthY)
        
        var oldMomentum = space.allowsMomentumX
        space.allowsMomentumX = false
        space.xRange = newRangeX
        space.allowsMomentumX = oldMomentum
        
        oldMomentum = space.allowsMomentumY
        space.allowsMomentumY = false
        space.yRange = newRangeY
        space.allowsMomentumY = oldMomentum
    }
    
    func showSpinner() -> UIView {
        let spinner = UIView.init(frame: self.view.bounds)
        DispatchQueue.main.async {
            spinner.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue:0.5, alpha: 0.5)
            let activity = UIActivityIndicatorView.init(style: .whiteLarge)
            activity.startAnimating()
            activity.center = spinner.center
            spinner.addSubview(activity)
            self.view.addSubview(spinner)
            print("showing spinner...")
        }
        return spinner
    }
    
    func removeSpinner(_ spinner: UIView) {
        DispatchQueue.main.async {
            spinner.removeFromSuperview()
            print("removing spinner...")
        }
    }
    
    
    func showClassificationActions(for index: Int) {
        let alert = UIAlertController(title: "Breath #\(index + 1)", message: "Choose a classification for breath #\(index + 1)", preferredStyle: .actionSheet)
        let dta = UIAlertAction(title: "DTA", style: .default) { (action) in
            self.classification[index] = .dta
            self.collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
            self.marker?.contentLayer?.isHidden = true
            self.checkAllClassified()
        }
        let bsa = UIAlertAction(title: "BSA", style: .default) { (action) in
            self.classification[index] = .bsa
            self.collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
            self.marker?.contentLayer?.isHidden = true
            self.checkAllClassified()
        }
        let tvv = UIAlertAction(title: "TVV", style: .default) { (action) in
            self.classification[index] = .tvv
            self.collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
            self.marker?.contentLayer?.isHidden = true
            self.checkAllClassified()
        }
        let norm = UIAlertAction(title: "Normal", style: .default) { (action) in
            self.classification[index] = .norm
            self.collectionView.reloadItems(at: [IndexPath(row: index, section: 0)])
            self.marker?.contentLayer?.isHidden = true
            self.checkAllClassified()
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
            
        }
        alert.addAction(dta)
        alert.addAction(bsa)
        alert.addAction(tvv)
        alert.addAction(norm)
        alert.addAction(cancel)
        
        self.present(alert, animated: true)
    }
    
    func showAlert(withTitle title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "Confirm", style: .cancel) { (alertAction) in
            
        }
        alert.addAction(action)
        self.present(alert, animated: true)
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension FeedbackViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return Storage.numFeedbackBreaths
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "feedbackCell", for: indexPath) as! FeedbackCollectionViewCell
        cell.title.text = "#\(indexPath.row + 1)"
        switch classification[indexPath.row] {
        case .dta:
            cell.classification.text = "DTA"
        case .bsa:
            cell.classification.text = "BSA"
        case .tvv:
            cell.classification.text = "TVV"
        case .norm:
            cell.classification.text = "Normal"
        case .none:
            cell.classification.text = "Not Classified"
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        self.showClassificationActions(for: indexPath.row)
    }
}

extension FeedbackViewController: CPTScatterPlotDelegate, CPTScatterPlotDataSource {
    
    func numberOfRecords(for plot: CPTPlot) -> UInt {
        let plotID = plot.identifier as! String
        switch plotID {
        case "flow": return UInt(patient.flow.count)
        case "pressure": return UInt(patient.pressure.count)
        case "async": return UInt(patient.asynchrony.count)
        default: ()
        }
        return 0
    }
    
    func number(for plot: CPTPlot, field fieldEnum: UInt, record idx: UInt) -> Any? {
        let plotField = CPTScatterPlotField(rawValue: Int(fieldEnum))
        let plotID = plot.identifier as! String
        
        switch (plotID, plotField!) {
        case("async", .X): return patient.offsets[patient.asynchronyIndex[Int(idx)]]
        case("async", .Y): return patient.pressure[patient.asynchronyIndex[Int(idx)]]
        case(_, .X): return patient.offsets[Int(idx)]
        case ("flow", .Y): return patient.flow[Int(idx)]
        case ("pressure", .Y): return patient.pressure[Int(idx)]
        default: ()
        }
        return nil
    }
    
    func scatterPlot(_ plot: CPTScatterPlot, plotSymbolWasSelectedAtRecord idx: UInt) {
        guard let graph = hostView.hostedGraph, let plotSpace = graph.defaultPlotSpace as? CPTXYPlotSpace, let marker = self.marker, let textLayer = marker.contentLayer as? CPTTextLayer, let id = plot.identifier as? String else {
            print("Point selection error")
            return
        }
        
        guard let temp = patient.json[patient.breathIndex[Int(idx)]][PACKET_METADATA] as? [String: Any], let etime = temp[PACKET_E_TIME] as? Double, let itime = temp[PACKET_I_TIME] as? Double, let peep = temp[PACKET_PEEP] as? Double, let rr = temp[PACKET_RR], let tvei = temp[PACKET_TVE_TVI_RATIO] as? Double, let tve = temp[PACKET_TVE] as? Double, let tvi = temp["tvi"] as? Double, let c = patient.json[patient.breathIndex[Int(idx)]][PACKET_CLASSIFICATION] as? [String: Int], let bsa = c[PACKET_BSA], let dta = c[PACKET_DTA], let tvv = c[PACKET_TVV] else {
            print("Error parsing json while displaying marker")
            return
        }
        
        if plotSpace.xRange.contains(patient.offsets[Int(idx)]) {
            textLayer.text = """
            Flow: \(patient.flow[Int(idx)])
            Pressure: \(patient.pressure[Int(idx)])
            
            E-time: \(etime)
            I-time: \(itime)
            RR: \(rr)
            Peep: \(peep)
            TVe/TVi: \(tvei)
            TVe: \(tve)
            TVi: \(tvi)
            """
            textLayer.isHidden = false
            marker.anchorPlotPoint = [patient.offsets[Int(idx)] as NSNumber, (id == "flow" ? patient.flow[Int(idx)] : patient.pressure[Int(idx)]) as NSNumber]
            self.showClassificationActions(for: self.patient.breathIndex[Int(idx)])
        }
        else {
            textLayer.isHidden = true
        }
        
        
    }
    
    func dataLabel(for plot: CPTPlot, record idx: UInt) -> CPTLayer? {
        if plot.identifier as? String == "async" {
            let t = CPTTextLayer(text: patient.asynchrony[Int(idx)])
            if let space = plot.plotSpace, let y = space.plotRange(for: .Y)?.minLimitDouble {
                t.anchorPoint = CGPoint(x: patient.offsets[patient.asynchronyIndex[Int(idx)]], y: y + 10)
            }
            return t
            //return CPTTextLayer(text: patient.asynchrony[Int(idx)])
        }
        return nil
    }
    
    func symbol(for plot: CPTScatterPlot, record idx: UInt) -> CPTPlotSymbol? {
        return CPTPlotSymbol()
    }
    
    /*
     func didFinishDrawing(_ plot: CPTPlot) {
     print("Done Drawing \(plot.identifier)")
     if plotsToDraw > 0 {
     DispatchQueue.main.async {
     self.plotsToDraw -= 1
     if self.plotsToDraw == 0 {
     print("All done")
     self.removeSpinner(self.spinner)
     self.hostView.isUserInteractionEnabled = true
     }
     }
     }
     }
     */
    
}

extension FeedbackViewController: CPTPlotSpaceDelegate {
    func plotSpace(_ space: CPTPlotSpace, didChangePlotRangeFor coordinate: CPTCoordinate) {
        if let xAxis = (hostView.hostedGraph?.axisSet as? CPTXYAxisSet)?.xAxis {
            xAxis.majorIntervalLength = Int(truncating: (space as! CPTXYPlotSpace).xRange.length) / 4 as NSNumber
        }
        
        if marker?.contentLayer?.isHidden == false, let anchor = marker?.anchorPlotPoint, (space as? CPTXYPlotSpace)?.plotRange(for: coordinate)?.contains(anchor[coordinate.rawValue]) == false {
            marker?.contentLayer?.isHidden = true
        }
        
        if coordinate == CPTCoordinate.X {
            
        }
    }
    
    func plotSpace(_ space: CPTPlotSpace, shouldHandlePointingDeviceDownEvent event: UIEvent, at point: CGPoint) -> Bool {
        if let textLayer = self.marker?.contentLayer {
            textLayer.isHidden = true
        }
        return true
    }
    
    func plotSpace(_ space: CPTPlotSpace, shouldScaleBy interactionScale: CGFloat, aboutPoint interactionPoint: CGPoint) -> Bool {
        return true
    }
}

