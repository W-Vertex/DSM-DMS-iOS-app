//
//  TodayViewController.swift
//  MealExtension
//
//  Created by 이병찬 on 2017. 11. 14..
//  Copyright © 2017년 이병찬. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
        
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var dataTextView: UITextView!
    @IBOutlet weak var dateLabel: UILabel!
    
    private let formatter = DateFormatter()
    
    private var date: Date!
    private let aDay = TimeInterval(86400)
    
    private var data = [String]()
    
    private var currentTime = 0
    
    override func viewDidLoad() {
        date = Date()
        setInit()
    }
    
    @IBAction func before(_ sender: Any) {
        currentTime -= 1
        setData()
    }
    
    @IBAction func after(_ sender: Any) {
        currentTime += 1
        setData()
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        completionHandler(NCUpdateResult.newData)
    }
    
}

extension TodayViewController{
    
    private func setInit(){
        formatter.dateFormat = "H"
        guard let curIntTime = Int(formatter.string(from: date)) else{ return }
        switch curIntTime {
        case 0...8:
            currentTime = 0
        case 9...12:
            currentTime = 1
        case 13...17:
            currentTime = 2
        default:
            date! += aDay
            currentTime = 0
        }
        connect()
    }
    
    private func setData(){
        switch currentTime {
        case -1:
            date! -= aDay
            currentTime = 2
            connect()
        case 3:
            date! += aDay
            currentTime = 0
            connect()
        default:
            bind()
        }
    }
    
    private func connect(){
        formatter.dateFormat = "YYYY-MM-dd"
        let dateStr = formatter.string(from: date)
        URLSession.shared.dataTask(with: URL(string: "http://dsm2015.cafe24.com/v2/" + InfoAPI.getMealInfo(date: dateStr).getPath())!){
            [weak self] data, res, err in
            guard let strongSelf = self else { return }
            if let err = err { print(err.localizedDescription); return }
            switch (res as! HTTPURLResponse).statusCode{
            case 200: strongSelf.data = try! JSONDecoder().decode(MealModel.self, from: data!).getDataForExtension()
            case 204: strongSelf.data = ["급식이 없습니다", "급식이 없습니다", "급식이 없습니다"]
            case let code: strongSelf.data = ["오류 : \(code)", "오류 : \(code)", "오류 : \(code)"]
            }
            DispatchQueue.main.async { strongSelf.bind() }
        }.resume()
    }
    
    func bind(){
        formatter.dateFormat = "YYYY-MM-dd"
        let dateStr = formatter.string(from: date)
        dateLabel.text = dateStr
        timeLabel.text = ["아침", "점심", "저녁"][currentTime]
        dataTextView.text = data[currentTime]
    }
    
}
