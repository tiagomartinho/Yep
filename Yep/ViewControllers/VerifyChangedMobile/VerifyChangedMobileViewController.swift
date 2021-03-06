//
//  VerifyChangedMobileViewController.swift
//  Yep
//
//  Created by NIX on 16/5/4.
//  Copyright © 2016年 Catch Inc. All rights reserved.
//

import UIKit
import Ruler

class VerifyChangedMobileViewController: UIViewController {

    var mobile: String!
    var areaCode: String!

    @IBOutlet private weak var verifyMobileNumberPromptLabel: UILabel!
    @IBOutlet private weak var verifyMobileNumberPromptLabelTopConstraint: NSLayoutConstraint!

    @IBOutlet private weak var phoneNumberLabel: UILabel!

    @IBOutlet private weak var verifyCodeTextField: BorderTextField!
    @IBOutlet private weak var verifyCodeTextFieldTopConstraint: NSLayoutConstraint!

    @IBOutlet private weak var callMePromptLabel: UILabel!
    @IBOutlet private weak var callMeButton: UIButton!
    @IBOutlet private weak var callMeButtonTopConstraint: NSLayoutConstraint!

    private lazy var nextButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: NSLocalizedString("Submit", comment: ""), style: .Plain, target: self, action: #selector(VerifyChangedMobileViewController.submit(_:)))
        return button
    }()

    private lazy var callMeTimer: NSTimer = {
        let timer = NSTimer.scheduledTimerWithTimeInterval(1.0, target: self, selector: #selector(VerifyChangedMobileViewController.tryCallMe(_:)), userInfo: nil, repeats: true)
        return timer
    }()

    private var haveAppropriateInput = false {
        willSet {
            nextButton.enabled = newValue

            if newValue {
                confirmNewMobile()
            }
        }
    }

    private var callMeInSeconds = YepConfig.callMeInSeconds()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.yepViewBackgroundColor()

        navigationItem.titleView = NavigationTitleLabel(title: NSLocalizedString("Change Mobile", comment: ""))

        navigationItem.rightBarButtonItem = nextButton

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(VerifyChangedMobileViewController.activeAgain(_:)), name: AppDelegate.Notification.applicationDidBecomeActive, object: nil)

        verifyMobileNumberPromptLabel.text = NSLocalizedString("Input verification code sent to", comment: "")
        phoneNumberLabel.text = "+" + areaCode + " " + mobile

        verifyCodeTextField.placeholder = " "
        verifyCodeTextField.backgroundColor = UIColor.whiteColor()
        verifyCodeTextField.textColor = UIColor.yepInputTextColor()
        verifyCodeTextField.addTarget(self, action: #selector(VerifyChangedMobileViewController.textFieldDidChange(_:)), forControlEvents: .EditingChanged)

        callMePromptLabel.text = NSLocalizedString("Didn't get it?", comment: "")
        callMeButton.setTitle(NSLocalizedString("Call me", comment: ""), forState: .Normal)

        verifyMobileNumberPromptLabelTopConstraint.constant = Ruler.iPhoneVertical(30, 50, 60, 60).value
        verifyCodeTextFieldTopConstraint.constant = Ruler.iPhoneVertical(30, 40, 50, 50).value
        callMeButtonTopConstraint.constant = Ruler.iPhoneVertical(10, 20, 40, 40).value
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        nextButton.enabled = false
        callMeButton.enabled = false
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        verifyCodeTextField.becomeFirstResponder()

        callMeTimer.fire()
    }

    // MARK: Actions

    @objc private func activeAgain(notification: NSNotification) {
        verifyCodeTextField.becomeFirstResponder()
    }

    @objc private func tryCallMe(timer: NSTimer) {
        if !haveAppropriateInput {
            if callMeInSeconds > 1 {
                let callMeInSecondsString = NSLocalizedString("Call me", comment: "") + " (\(callMeInSeconds))"

                UIView.performWithoutAnimation {
                    self.callMeButton.setTitle(callMeInSecondsString, forState: .Normal)
                    self.callMeButton.layoutIfNeeded()
                }

            } else {
                UIView.performWithoutAnimation {
                    self.callMeButton.setTitle(NSLocalizedString("Call me", comment: ""), forState: .Normal)
                    self.callMeButton.layoutIfNeeded()
                }

                callMeButton.enabled = true
            }
        }

        if (callMeInSeconds > 1) {
            callMeInSeconds -= 1
        }
    }

    @IBAction private func callMe(sender: UIButton) {

        callMeTimer.invalidate()

        UIView.performWithoutAnimation {
            self.callMeButton.setTitle(NSLocalizedString("Calling", comment: ""), forState: .Normal)
            self.callMeButton.layoutIfNeeded()
        }

        delay(5) {
            UIView.performWithoutAnimation {
                self.callMeButton.setTitle(NSLocalizedString("Call me", comment: ""), forState: .Normal)
                self.callMeButton.layoutIfNeeded()
            }
        }

        sendVerifyCodeOfNewMobile(mobile, withAreaCode: areaCode, useMethod: .Call, failureHandler: { [weak self] reason, errorMessage in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            let errorMessage = errorMessage ?? "Error: call for verify code"

            YepAlert.alertSorry(message: errorMessage, inViewController: self)

            dispatch_async(dispatch_get_main_queue()) {
                UIView.performWithoutAnimation {
                    self?.callMeButton.setTitle(NSLocalizedString("Call me", comment: ""), forState: .Normal)
                    self?.callMeButton.layoutIfNeeded()
                }
            }

        }, completion: { success in
            println("sendVerifyCodeOfNewMobile .Call \(success)")
        })
    }

    @objc private func textFieldDidChange(textField: UITextField) {
        guard let text = textField.text else {
            return
        }

        haveAppropriateInput = (text.characters.count == YepConfig.verifyCodeLength())
    }
    
    @objc private func submit(sender: UIBarButtonItem) {
        confirmNewMobile()
    }

    private func confirmNewMobile() {

        view.endEditing(true)

        guard let verifyCode = verifyCodeTextField.text else {
            return
        }

        YepHUD.showActivityIndicator()

        comfirmNewMobile(mobile, withAreaCode: areaCode, verifyCode: verifyCode, failureHandler: { [weak self] (reason, errorMessage) in
            defaultFailureHandler(reason: reason, errorMessage: errorMessage)

            YepHUD.hideActivityIndicator()

            dispatch_async(dispatch_get_main_queue()) {
                self?.nextButton.enabled = false
            }

            let errorMessage = errorMessage ?? ""

            YepAlert.alertSorry(message: errorMessage, inViewController: self, withDismissAction: {
                dispatch_async(dispatch_get_main_queue()) {
                    self?.verifyCodeTextField.becomeFirstResponder()
                }
            })

        }, completion: { [weak self] in

            YepHUD.hideActivityIndicator()

            dispatch_async(dispatch_get_main_queue()) {
                if let strongSelf = self {
                    YepUserDefaults.areaCode.value = strongSelf.areaCode
                    YepUserDefaults.mobile.value = strongSelf.mobile
                }
            }

            YepAlert.alert(title: NSLocalizedString("Success", comment: ""), message: NSLocalizedString("You have successfully updated your mobile for Yep! For now on, using the new number to login.", comment: ""), dismissTitle: NSLocalizedString("OK", comment: ""), inViewController: self, withDismissAction: { [weak self] in

                self?.performSegueWithIdentifier("unwindToEditProfile", sender: nil)
            })
        })
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
