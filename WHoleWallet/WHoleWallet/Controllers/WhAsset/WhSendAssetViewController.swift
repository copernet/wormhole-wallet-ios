//
/*******************************************************************************

        WhSendAssetViewController.swift
        WHoleWallet
   
        Created by ffy on 2018/12/1
        Copyright © 2018年 wormhole. All rights reserved.

********************************************************************************/
    

import UIKit
import Toast_Swift

class WhSendAssetViewController: UIViewController {

    var assetInfo: Dictionary<String,Any>
    private var scrollView = UIScrollView(frame: CGRect.zero)
    
    var toTF: UITextField!
    var feeTF: UITextField!
    var feeRateView: WhFeeRateView!
    
    init(assetInfo:Dictionary<String,Any>) {
        self.assetInfo = assetInfo
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func fetchFeeRate()  {
        WhHTTPRequestHandler.getFeeRate { (dictionary,fees) in
            if dictionary.count > 0 {
                DispatchQueue.main.async {
                    self.feeRateView.feeRates = fees
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Send"
        view.backgroundColor = UIColor.white
        if scrollView.superview == nil {
            view.addSubview(scrollView)
        }
        configView()
        
        fetchFeeRate()
    }
    
    func configView() {
        scrollView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        
        let container = UIView()
        scrollView.addSubview(container)
        container.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        let addressView = WhAddressView(address: (WhWalletManager.shared.whWallet?.cashAddr)!)
        container.addSubview(addressView)
        addressView.snp.makeConstraints { (make) in
            make.left.top.equalTo(20)
            make.centerX.equalToSuperview()
        }
        
        
        let receiveAddrL = WhCommonInputRow(icon: "main_icon_input_address", title: "Receive Address", "Please Input Receive Address")
        self.toTF = receiveAddrL.tf
        container.addSubview(receiveAddrL)
        receiveAddrL.snp.makeConstraints { (make) in
            make.left.equalTo(addressView.snp.left)
            make.top.equalTo(addressView.snp.bottom)
            make.centerX.equalToSuperview()
            make.height.equalTo(WhCommonInputRow.defaultH).priority(500)
        }
        
        let transferAmount = WhCommonInputRow(icon: "assert_icon_number", title: "Transer Amount", "Please Input The Number Your Want To Send")
        container.addSubview(transferAmount)
        transferAmount.snp.makeConstraints { (make) in
            make.left.equalTo(receiveAddrL.snp.left)
            make.right.equalTo(receiveAddrL.snp.right)
            make.top.equalTo(receiveAddrL.snp.bottom).offset(15)
            make.height.equalTo(receiveAddrL.snp.height)
        }
        
        let noteRow = WhCommonInputRow(icon: "assert__icon_remark", title: "Note", "Please Input Note")
        container.addSubview(noteRow)
        noteRow.snp.makeConstraints { (make) in
            make.left.equalTo(transferAmount.snp.left)
            make.right.equalTo(transferAmount.snp.right)
            make.top.equalTo(transferAmount.snp.bottom).offset(15)
            make.height.equalTo(transferAmount.snp.height)
        }
        
        
        let feeRate = WhCommonInputRow(icon: "assert_icon_minerfee", title: "Fee Rate (BCH/KB)", "0")
        self.feeTF = feeRate.tf
        container.addSubview(feeRate)
        feeRate.snp.makeConstraints { (make) in
            make.left.equalTo(noteRow.snp.left)
            make.right.equalTo(noteRow.snp.right)
            make.top.equalTo(noteRow.snp.bottom).offset(15)
            make.height.equalTo(noteRow.snp.height)
        }
        
        let feeSelect = WhFeeRateView(textField: feeRate.tf, feeRates: nil)
        container.addSubview(feeSelect)
        feeSelect.snp.makeConstraints { (make) in
            make.left.equalTo(feeRate.snp.left)
            make.right.equalTo(feeRate.snp.right)
            make.top.equalTo(feeRate.snp.bottom).offset(10)
            make.height.equalTo(24)
        }
        feeRateView = feeSelect
        
        
        let promptIcon = UIImageView(image: UIImage(named: "wallet_create_reminder_icon"))
        container.addSubview(promptIcon)
        promptIcon.snp.makeConstraints { (make) in
            make.width.height.equalTo(16)
            make.top.equalTo(feeSelect.snp.bottom).offset(20)
            make.left.equalTo(20)
        }
        let promptTag = UILabel()
        promptTag.text = "Will Send Token, And Cannot Revoke"
        promptTag.textColor = UIColor(hex: 0x445571)
        promptTag.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        container.addSubview(promptTag)
        promptTag.snp.makeConstraints { (make) in
            make.left.equalTo(promptIcon.snp.right).offset(10)
            make.centerY.equalTo(promptIcon.snp.centerY)
        }
        
        
        
        let sure = UIButton.commonSure(title: "Confirm")
        container.addSubview(sure)
        sure.snp.makeConstraints { (make) in
            make.left.equalTo(80)
            make.top.equalTo(promptTag.snp.bottom).offset(80)
            make.centerX.equalToSuperview()
            make.height.equalTo(45)
            make.bottom.equalToSuperview().offset(-60)
        }
        sure.addTarget(self, action: #selector(sureAction), for: .touchUpInside)
        
        
    }
    
    @objc func sureAction()  {
        let wallet = WhWalletManager.shared.whWallet!
        guard let fee = feeTF.text, let to = toTF.text, let pID = resPonsedString(dictionary: assetInfo, key: "propertyid") else {
            self.view!.makeToast("please enter required information !")
            return
        }
        
        if !to.isValidCashAddress(network: WhWalletManager.shared.network) {
            self.view!.makeToast("please enter valid address !")
        }
       
        let parameters = ["transaction_version": "0", "fee":fee, "transaction_from": wallet.cashAddr, "transaction_to    ": to, "currency_identifier": pID]
        WhHTTPRequestHandler.unsignedOperate(reqCode: 0, parameters: parameters) { (result) in
            if result.count > 0 {
                WormHoleSignUnSignedTxFlow.handleResult(result: result, complete: {
                    DispatchQueue.main.async {
                        [weak self] in
                        if let weakSelf = self {
                            weakSelf.view!.makeToast("transaction success !", duration: 2.0, title: nil, image: nil) { didTap in
                                weakSelf.navigationController?.popToRootViewController(animated: true)
                            }
                        }
                        
                    }
                }, failure: {
                    [weak self] in
                    if let weakSelf = self {
                        weakSelf.view!.makeToast("transaction failed !")
                    }
                })
            }
            
            //do somthing
            DispatchQueue.main.async {
                [weak self] in
                if let weakSelf = self {
                    weakSelf.view!.makeToast("transaction failed !")
                }
            }
            return

        }

    }
    

}
