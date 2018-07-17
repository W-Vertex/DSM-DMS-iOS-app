//
//  MyPageVC.swift
//  DSMapp
//
//  Created by 이병찬 on 2017. 11. 8..
//  Copyright © 2017년 이병찬. All rights reserved.
//

import UIKit
import RxSwift

class MyPageVC: UIViewController {

    @IBOutlet weak var stayStateLabel: UILabel!
    @IBOutlet weak var studyStateLabel: UILabel!
    @IBOutlet weak var positiveCountLabel: UILabel!
    @IBOutlet weak var negativeCountLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    private let token = Token.instance
    
    override func viewDidLoad() {
        setInit()
    }
    
    override func viewWillAppear(_ animated: Bool){
        loadData()
        tableView.reloadRows(at: [IndexPath(row: 1, section: 0)], with: .none)
    }

}

extension MyPageVC {
    
    private func setInit(){
        tableView.delegate = self
        tableView.dataSource = self
        studyStateLabel.numberOfLines = 2
    }
    
    private func loadData(){
        if !loginCheck() { return }
        loadUserData()
        loadApplyData()
    }
    
    private func loadUserData(){
        _ = Connector.instance
            .getRequest(InfoAPI.getMypageInfo, method: .get)
            .decodeData(MyPageModel.self, vc: self)
            .subscribe(onNext: { [weak self] code, data in
                if let data = data{
                    self?.bindUserPointData(good: data.goodPoint, bad: data.badPoint)
                    self?.showToast(msg: "\(data.name)님 반갑습니다.")
                }
                else{ self?.showError(code) }
            })
    }
    
    private func loadApplyData(){
        _ = Connector.instance
            .getRequest(InfoAPI.getApplyInfo, method: .get)
            .decodeData(ApplyModel.self, vc: self)
            .subscribe(onNext: { [weak self] code, data in
                if let data = data{
                    self?.bindUserApplyData(study: data.getStudyState(), stay: data.getStayState())
                }else{ self?.showError(code) }
            })
    }
    
    private func bindUserPointData(good: Int = 0, bad: Int = 0){
        positiveCountLabel.text = good.description
        negativeCountLabel.text = bad.description
    }
    
    private func bindUserApplyData(study: String = "연장상태", stay: String = "잔류상태"){
        studyStateLabel.text = study
        stayStateLabel.text = stay
    }
    
    private func bindInitData(){
        bindUserApplyData()
        bindUserPointData()
    }
    
    private func uploadBug(_ textField: UITextField){
        _ = Connector.instance
            .getRequest(ReportAPI.reportBug, method: .post, params: ["platform" : 3, "content" : textField.text!])
            .emptyData(vc: self)
            .subscribe(onNext: { [weak self] code in
                if code == 201 { self?.showToast(msg: "버그 신청 성공") }
                else{ self?.showError(code) }
            })
    }
    
}

extension MyPageVC: UITableViewDataSource, UITableViewDelegate{
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 7
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 1:
            if token.get() == nil { goNextViewWithStoryboard(storyId: "Auth", id: "SignInView") }
            else{ token.remove(); tableView.reloadData(); bindInitData() }
        case 2:
            if token.get() == nil { showToast(msg: "로그인이 필요합니다") }
            else{ goNextViewWithStoryboard(storyId: "Auth", id: "ChangePasswordView") }
        case 3:
            if loginCheck() { goNextViewController("PointListView") }
        case 5:
            if !loginCheck() { return }
            let alert = UIAlertController(title: "버그신고", message: nil, preferredStyle: .alert)
            alert.addTextField()
            alert.addAction(UIAlertAction(title: "전송", style: .default){ [weak self] _ in self?.uploadBug(alert.textFields![0]) } )
            alert.addAction(UIAlertAction.init(title: "취소", style: .cancel))
            present(alert, animated: true, completion: nil)
        case 6: goNextViewController("IntroDeveloperListView")
        default: return
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let titleStrArr = ["", "", "비밀번호 변경","상벌점 내역 조회", "", "버그 신고", "개발자 소개"]
        switch indexPath.row {
        case 0, 4:
            return tableView.dequeueReusableCell(withIdentifier: "EmptyCell", for: indexPath)
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ContentCell", for: indexPath) as! ContentCell
            if indexPath.row == 1{ cell.titleLabel.text = token.get() == nil ? "로그인" : "로그아웃" }
            else { cell.titleLabel.text = titleStrArr[indexPath.row] }
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.row {
        case 0, 4:
            return 20
        default:
            return 60
        }
    }
    
}

class ContentCell: UITableViewCell{
    
    @IBOutlet weak var titleLabel: UILabel!
    
}
