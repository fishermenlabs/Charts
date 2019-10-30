//
//  PieRadarChartView.swift
//  Charts
//
//  Created by Kevin Weber on 4/10/17.
//
//

import Foundation
import CoreGraphics

#if !os(OSX)
    import UIKit
#endif

/// View that represents a pie radar chart. Draws cake like slices of different radii.
open class PieRadarChartView: PieRadarChartViewBase
{
    /// rect object that represents the bounds of the piechart, needed for drawing the circle
    fileprivate var _circleBox = CGRect()
    
    /// flag indicating if entry labels should be drawn or not
    fileprivate var _drawEntryLabelsEnabled = true
    
    /// array that holds the width of each pie-slice in degrees
    fileprivate var _drawAngles = [CGFloat]()

    /// array that holds the radii of each pie-slice
    fileprivate var _drawRadii = [CGFloat]()
    
    /// array that holds the absolute angle in degrees of each slice
    fileprivate var _absoluteAngles = [CGFloat]()
    
    /// Sets the color the entry labels are drawn with.
    fileprivate var _entryLabelColor: NSUIColor? = NSUIColor.white
    
    /// Sets the font the entry labels are drawn with.
    fileprivate var _entryLabelFont: NSUIFont? = NSUIFont(name: "HelveticaNeue", size: 13.0)
    
    /// if true, the values inside the piechart are drawn as percent values
    fileprivate var _usePercentValuesEnabled = false
    
    /// maximum angle for this pie
    fileprivate var _maxAngle: CGFloat = 360.0
    
    open var range: Double = 100.0
    
    /// width of the web lines that come from the center.
    open var webLineWidth = CGFloat(1.5)
    
    /// color for the web lines that come from the center
    open var webColor = NSUIColor(red: 122/255.0, green: 122/255.0, blue: 122.0/255.0, alpha: 1.0)
    
    /// transparency the grid is drawn with (0.0 - 1.0)
    open var webAlpha: CGFloat = 150.0 / 255.0
    
    /// number of web elipses
    open var webLineAmount = 5
    
    /// width of the web slice between data slices
    open var webSliceSpace: CGFloat = 5.0
    
    /// flag indicating if the web lines should be drawn or not
    open var drawWeb = true
    
    /// flag indicating if the background slices should be drawn
    open var drawBackgroundSlices = true
    
    public override init(frame: CGRect)
    {
        super.init(frame: frame)
    }
    
    public required init?(coder aDecoder: NSCoder)
    {
        super.init(coder: aDecoder)
    }
    
    internal override func initialize()
    {
        super.initialize()
        
        renderer = PieRadarChartRenderer(chart: self, animator: _animator, viewPortHandler: _viewPortHandler)
        _xAxis = nil
        
        self.highlighter = PieHighlighter(chart: self)
    }
    
    open override func draw(_ rect: CGRect)
    {
        super.draw(rect)
        
        if _data === nil
        {
            return
        }
        
        let optionalContext = NSUIGraphicsGetCurrentContext()
        guard let context = optionalContext else { return }
        
        if drawWeb
        {
            renderer!.drawExtras(context: context)
        }
        
        renderer!.drawData(context: context)
        
        if (valuesToHighlight())
        {
            renderer!.drawHighlighted(context: context, indices: _indicesToHighlight)
        }
        
        renderer!.drawValues(context: context)
        
        _legendRenderer.renderLegend(context: context)
        
        drawDescription(context: context)
        
        drawMarkers(context: context)
    }
    
    internal override func calculateOffsets()
    {
        super.calculateOffsets()
        
        // prevent nullpointer when no data set
        if _data === nil
        {
            return
        }
        
        let radius = diameter / 2.0
        
        let c = self.centerOffsets
        
        let shift = (data as? PieChartData)?.dataSet?.selectionShift ?? 0.0
        
        // create the circle box that will contain the pie-chart (the bounds of the pie-chart)
        _circleBox.origin.x = (c.x - radius) + shift
        _circleBox.origin.y = (c.y - radius) + shift
        _circleBox.size.width = diameter - shift * 2.0
        _circleBox.size.height = diameter - shift * 2.0
    }
    
    override func calcMinMax() {
        calcRadii()
        calcAngles()
    }
    
    fileprivate func calcRadii() {
        
        _drawRadii = [CGFloat]()
        
        guard let data = _data else { return }
        
        let entryCount = data.entryCount

        _drawRadii.reserveCapacity(entryCount)

        let dataSets = data.dataSets

        for i in 0 ..< data.dataSetCount
        {
            let set = dataSets[i]
            let entryCount = set.entryCount
            
            for j in 0 ..< entryCount
            {
                guard let e = set.entryForIndex(j) as? PieChartDataEntry else { continue }
                
                _drawRadii.append(CGFloat(e.value))
            }
        }
    }
    
    fileprivate func calcAngles() {
        
        _drawAngles = [CGFloat]()
        _absoluteAngles = [CGFloat]()
        
        guard let data = _data else { return }
        
        let entryCount = data.entryCount
        
        _drawAngles.reserveCapacity(entryCount)
        _absoluteAngles.reserveCapacity(entryCount)
        
        let dataSets = data.dataSets
        
        var cnt = 0
        
        for i in 0 ..< data.dataSetCount
        {
            let set = dataSets[i]
            let entryCount = set.entryCount
            
            for j in 0 ..< entryCount
            {
                guard let _ = set.entryForIndex(j) else { continue }
                
                _drawAngles.append(calcAngle(value: Double(entryCount), range: range))
                
                if cnt == 0
                {
                    _absoluteAngles.append(_drawAngles[cnt])
                }
                else
                {
                    _absoluteAngles.append(_absoluteAngles[cnt - 1] + _drawAngles[cnt])
                }
                
                cnt += 1
            }
        }
    }
    
    open override func getMarkerPosition(highlight: Highlight) -> CGPoint
    {
        let center = self.centerCircleBox
        var r = self.radius
        
        let off = r / 10.0 * 3.6
        
        r -= off // offset to keep things inside the chart
        
        let rotationAngle = self.rotationAngle
        
        let entryIndex = Int(highlight.x)
        
        // offset needed to center the drawn text in the slice
        let offset = drawAngles[entryIndex] / 2.0
        
        // calculate the text position
        let x: CGFloat = (r * cos(((rotationAngle + absoluteAngles[entryIndex] - offset) * CGFloat(_animator.phaseY)).DEG2RAD) + center.x)
        let y: CGFloat = (r * sin(((rotationAngle + absoluteAngles[entryIndex] - offset) * CGFloat(_animator.phaseY)).DEG2RAD) + center.y)
        
        return CGPoint(x: x, y: y)
    }
    
    /// Checks if the given index is set to be highlighted.
    open func needsHighlight(index: Int) -> Bool
    {
        // no highlight
        if !valuesToHighlight()
        {
            return false
        }
        
        for i in 0 ..< _indicesToHighlight.count
        {
            // check if the xvalue for the given dataset needs highlight
            if Int(_indicesToHighlight[i].x) == index
            {
                return true
            }
        }
        
        return false
    }
    
    /// calculates the needed angle for a given value
    fileprivate func calcAngle(value: Double, range: Double) -> CGFloat
    {
        return CGFloat(range / value) / CGFloat(range) * _maxAngle
    }
    
    /// This will throw an exception, PieChart has no XAxis object.
    open override var xAxis: XAxis
    {
        fatalError("PieChart has no XAxis")
    }
    
    open override func indexForAngle(_ angle: CGFloat) -> Int
    {
        // take the current angle of the chart into consideration
        let a = (angle - self.rotationAngle).normalizedAngle
        for i in 0 ..< _absoluteAngles.count
        {
            if _absoluteAngles[i] > a
            {
                return i
            }
        }
        
        return -1 // return -1 if no index found
    }
    
    /// - returns: The index of the DataSet this x-index belongs to.
    open func dataSetIndexForIndex(_ xValue: Double) -> Int
    {
        let dataSets = _data?.dataSets ?? []
        
        for i in 0 ..< dataSets.count
        {
            if (dataSets[i].entryForXValue(xValue, closestToY: Double.nan) !== nil)
            {
                return i
            }
        }
        
        return -1
    }
    
    /// - returns: An integer array of all the different angles the chart slices
    /// have the angles in the returned array determine how much space (of 360°)
    /// each slice takes
    open var drawAngles: [CGFloat]
    {
        return _drawAngles
    }
    
    /// - returns: An array of all different radii for the chart slices
    open var drawRadii: [CGFloat]
    {
        return _drawRadii
    }
    
    /// - returns: The absolute angles of the different chart slices (where the
    /// slices end)
    open var absoluteAngles: [CGFloat]
    {
        return _absoluteAngles
    }
    
    internal override var requiredLegendOffset: CGFloat
    {
        return _legend.font.pointSize * 2.0
    }
    
    internal override var requiredBaseOffset: CGFloat
    {
        return 0.0
    }
    
    open override var radius: CGFloat
    {
        return _circleBox.width / 2.0
    }
    
    /// - returns: The circlebox, the boundingbox of the pie-chart slices
    open var circleBox: CGRect
    {
        return _circleBox
    }
    
    /// - returns: The center of the circlebox
    open var centerCircleBox: CGPoint
    {
        return CGPoint(x: _circleBox.midX, y: _circleBox.midY)
    }
    
    /// The color the entry labels are drawn with.
    open var entryLabelColor: NSUIColor?
        {
        get { return _entryLabelColor }
        set
        {
            _entryLabelColor = newValue
            setNeedsDisplay()
        }
    }
    
    /// The font the entry labels are drawn with.
    open var entryLabelFont: NSUIFont?
        {
        get { return _entryLabelFont }
        set
        {
            _entryLabelFont = newValue
            setNeedsDisplay()
        }
    }
    
    /// Set this to true to draw the enrty labels into the pie slices
    open var drawEntryLabelsEnabled: Bool
        {
        get
        {
            return _drawEntryLabelsEnabled
        }
        set
        {
            _drawEntryLabelsEnabled = newValue
            setNeedsDisplay()
        }
    }
    
    /// - returns: `true` if drawing entry labels is enabled, `false` ifnot
    open var isDrawEntryLabelsEnabled: Bool
        {
        get
        {
            return drawEntryLabelsEnabled
        }
    }
    
    /// If this is enabled, values inside the PieChart are drawn in percent and not with their original value. Values provided for the ValueFormatter to format are then provided in percent.
    open var usePercentValuesEnabled: Bool
        {
        get
        {
            return _usePercentValuesEnabled
        }
        set
        {
            _usePercentValuesEnabled = newValue
            setNeedsDisplay()
        }
    }
    
    /// - returns: `true` if drawing x-values is enabled, `false` ifnot
    open var isUsePercentValuesEnabled: Bool
        {
        get
        {
            return usePercentValuesEnabled
        }
    }
    
    /// The max angle that is used for calculating the pie-circle.
    /// 360 means it's a full pie-chart, 180 results in a half-pie-chart.
    /// **default**: 360.0
    open var maxAngle: CGFloat
        {
        get
        {
            return _maxAngle
        }
        set
        {
            _maxAngle = newValue
            
            if _maxAngle > 360.0
            {
                _maxAngle = 360.0
            }
            
            if _maxAngle < 90.0
            {
                _maxAngle = 90.0
            }
        }
    }
}
