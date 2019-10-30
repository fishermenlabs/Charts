//
//  RadarChartViewController.swift
//  ChartsDemo-iOS
//
//  Created by Jacob Christie on 2017-07-09.
//  Copyright © 2017 jc. All rights reserved.
//

#if canImport(UIKit)
    import UIKit
#endif
import Charts

class PieRadarChartViewController: DemoBaseViewController {

    @IBOutlet var chartView: PieRadarChartView!
    
    let activities = ["Burger", "Steak", "Salad", "Pasta", "Pizza"]
    var originalBarBgColor: UIColor!
    var originalBarTintColor: UIColor!
    var originalBarStyle: UIBarStyle!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.title = "Radar Chart"
        self.options = [.toggleValues,
                        .toggleHighlight,
                        .toggleHighlightCircle,
                        .toggleXLabels,
                        .toggleYLabels,
                        .toggleRotate,
                        .toggleFilled,
                        .animateX,
                        .animateY,
                        .animateXY,
                        .spin,
                        .saveToGallery,
                        .toggleData]
        
        chartView.delegate = self

        chartView.highlightPerTapEnabled = false
        chartView.chartDescription?.enabled = false
        chartView.rotationAngle = 90.0
        chartView.rotationEnabled = true
        chartView.webLineAmount = 6
        chartView.legend.enabled = false

        self.updateChartData()
        
        chartView.animate(xAxisDuration: 1.4, yAxisDuration: 1.4, easingOption: .easeOutBack)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        UIView.animate(withDuration: 0.15) {
            let navBar = self.navigationController!.navigationBar
            self.originalBarBgColor = navBar.barTintColor
            self.originalBarTintColor = navBar.tintColor
            self.originalBarStyle = navBar.barStyle

            navBar.barTintColor = self.view.backgroundColor
            navBar.tintColor = .white
            navBar.barStyle = .black
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        UIView.animate(withDuration: 0.15) {
            let navBar = self.navigationController!.navigationBar
            navBar.barTintColor = self.originalBarBgColor
            navBar.tintColor = self.originalBarTintColor
            navBar.barStyle = self.originalBarStyle
        }
    }
    
    override func updateChartData() {
        if self.shouldHideData {
            chartView.data = nil
            return
        }
        
        self.setChartData()
    }
    
    func setChartData() {
        
        chartView.range = 100.0;
        chartView.webLineAmount = 6
               
        var values = [PieChartDataEntry]()
        values.append(contentsOf: [PieChartDataEntry(value: Double(1), label: "one"), PieChartDataEntry(value: Double(2), label: "two"), PieChartDataEntry(value: Double(3), label: "three"), PieChartDataEntry(value: Double(4), label: "four")])
 
        let dataSet = PieChartDataSet(entries: values, label: "")
        dataSet.xValuePosition = .outsideSlice
        dataSet.yValuePosition = .outsideSlice
        dataSet.drawValuesEnabled = false
        dataSet.valueLinePart2Length = 0
        dataSet.valueLineWidth = 0
        dataSet.drawIconsEnabled = false
        dataSet.sliceSpace = 0
        dataSet.setColors([.orange, .purple, .red, .yellow, .green, .blue], alpha: 0.6)
               
        let data = PieChartData(dataSet: dataSet)
               
        chartView.data = data
        chartView.highlightValues(nil)
        chartView.data?.notifyDataChanged()
        chartView.notifyDataSetChanged()
    }
    
    override func optionTapped(_ option: Option) {
        switch option {
        case .toggleXLabels:
            chartView.xAxis.drawLabelsEnabled = !chartView.xAxis.drawLabelsEnabled
            chartView.data?.notifyDataChanged()
            chartView.notifyDataSetChanged()
            chartView.setNeedsDisplay()

        case .toggleRotate:
            chartView.rotationEnabled = !chartView.rotationEnabled
            
        case .toggleFilled:
            for set in chartView.data!.dataSets as! [RadarChartDataSet] {
                set.drawFilledEnabled = !set.drawFilledEnabled
            }
            
            chartView.setNeedsDisplay()
            
        case .toggleHighlightCircle:
            for set in chartView.data!.dataSets as! [RadarChartDataSet] {
                set.drawHighlightCircleEnabled = !set.drawHighlightCircleEnabled
            }
            chartView.setNeedsDisplay()

        case .animateX:
            chartView.animate(xAxisDuration: 1.4)
            
        case .animateY:
            chartView.animate(yAxisDuration: 1.4)
            
        case .animateXY:
            chartView.animate(xAxisDuration: 1.4, yAxisDuration: 1.4)
            
        case .spin:
            chartView.spin(duration: 2, fromAngle: chartView.rotationAngle, toAngle: chartView.rotationAngle + 360, easingOption: .easeInCubic)
            
        default:
            super.handleOption(option, forChartView: chartView)
        }
    }
}

extension PieRadarChartViewController: IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return activities[Int(value) % activities.count]
    }
}
