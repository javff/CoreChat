//
//  WehpahInputBar.swift
//  CoreChat
//
//  Created by Juan  Vasquez on 2/13/19.
//  Copyright © 2019 com.anincubator. All rights reserved.
//
import UIKit
import MessageInputBar
import AudioToolbox


public protocol WehpahInputBarHooksDelegate: class{
    
    func  messageInputBar(_ inputBar: MessageInputBar, multimediaButtonPressed button: InputBarButtonItem)
    func  messageInputBar(_ inputBar: WehpahMessageBar, recordingButtonLongPressed longPress: UILongPressGestureRecognizer)
}

public class WehpahMessageBar: MessageInputBar {
    
    private let multimediaButton: InputBarButtonItem
    private var recordingButton: InputBarButtonItem
    private var decorationRecordingButton: InputBarButtonItem
    private var slideToCancelButton: InputBarButtonItem
    private var slideToCancelText: RecordingLabelInputItem
    private let labelRecordingText: RecordingLabelInputItem
    private var timer: Timer?{
        didSet{
            if timer == nil{
                labelRecordingText.text = ""
                recordingTime = 0
            }
        }
    }
    private var recordingTime:TimeInterval = 0{
        didSet{
            self.recordingDuration = oldValue
        }
    }
    
    private let closeLeftStackView:CGFloat = 44
    private let openLeftStackView:CGFloat = UIScreen.main.bounds.width - 30
    
    public var recordingDuration:TimeInterval = 0
    
    weak var hooksDelegate:WehpahInputBarHooksDelegate?
    
    override init(frame: CGRect) {
        
        self.multimediaButton = InputBarButtonItem()
        self.recordingButton = InputBarButtonItem()
        self.decorationRecordingButton = InputBarButtonItem()
        self.slideToCancelButton = InputBarButtonItem()
        self.labelRecordingText = RecordingLabelInputItem(frame: .zero)
        self.slideToCancelText = RecordingLabelInputItem(frame: .zero)
        
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure() {
        
        self.inputTextView.autocorrectionType = .yes
        
        // configure left stack //
        self.leftStackView.distribution = .fillProportionally
        self.leftStackView.spacing = 0
        self.leftStackView.alignment = .center
        self.rightStackView.alignment = .center
        
        let bundle = Bundle(for:WehpahMessageBar.self)
        backgroundView.backgroundColor = .white
        
        // configure multiemdia button
        multimediaButton.setSize(CGSize(width: 36, height: 36), animated: false)
        
        let multimediaImage = UIImage(named: "clip",
                                      in: bundle,
                                      compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        
        multimediaButton.setImage(multimediaImage, for: .normal)
        multimediaButton.imageView?.contentMode = .scaleAspectFit
        multimediaButton.tintColor = .black
        
        // configure text buttons //
        
        labelRecordingText.font = UIFont.systemFont(ofSize: 14)
        slideToCancelText.font = UIFont.systemFont(ofSize: 10)
        labelRecordingText.textColor = UIColor.darkGray
        slideToCancelText.textColor = UIColor.darkGray
     
        // configure recording button //
        
        let recordingImage = UIImage(named: "microphone",
                                     in: bundle,
                                     compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        recordingButton.setSize(CGSize(width: 26, height: 30), animated: false)
        recordingButton.setImage(recordingImage, for: .normal)
        recordingButton.imageView?.contentMode = .scaleAspectFit
        recordingButton.tintColor = .black
        
        // configure decoaration recording button
        
        decorationRecordingButton.setSize(CGSize(width: 26, height: 30), animated: false)
        decorationRecordingButton.setImage(recordingImage, for: .normal)
        decorationRecordingButton.imageView?.contentMode = .scaleAspectFit
        decorationRecordingButton.tintColor = .black
        
        // configure slide cancel button //
        
        let arrowLeft = UIImage(named: "icArrowLeft",
                                in: bundle,
                                compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        slideToCancelButton.setSize(CGSize(width: 26, height: 30), animated: false)
        slideToCancelButton.setImage(arrowLeft, for: .normal)
        slideToCancelButton.imageView?.contentMode = .scaleAspectFit
        slideToCancelButton.tintColor = .darkGray
        slideToCancelButton.transform = CGAffineTransform(rotationAngle: CGFloat.pi)
    
        // configure input bar //
        inputTextView.backgroundColor = UIColor(red: 245/255, green: 245/255, blue: 245/255, alpha: 1)
        inputTextView.placeholderTextColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
        inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
        inputTextView.layer.borderColor = UIColor(red: 200/255, green: 200/255, blue: 200/255, alpha: 1).cgColor
        inputTextView.layer.borderWidth = 1.0
        inputTextView.layer.cornerRadius = 16.0
        inputTextView.layer.masksToBounds = true
        inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        setLeftStackViewWidthConstant(to: closeLeftStackView, animated: false)
        setRightStackViewWidthConstant(to: 44, animated: false)
        setStackViewItems([multimediaButton], forStack: .left, animated: false)
        setStackViewItems([recordingButton], forStack: .right, animated: true)
        
        // configure send button //
        sendButton.setSize(CGSize(width: 52, height: 36), animated: false)
        sendButton.setTitle("Send", for: .normal)
        
        
        //MARK: - configure hooks
        multimediaButton.addTarget(self, action: #selector(self.multimediaButtonTapped), for: .touchDown)
        
        let longPressGesture: UILongPressGestureRecognizer = UILongPressGestureRecognizer(target: self,action: #selector(self.recordingButtonLongPress(_:)))
        
        recordingButton.addGestureRecognizer(longPressGesture)

    }
    
    
    public func updateSendButton(){
        
        let button: InputBarButtonItem = self.inputTextView.text.isEmpty ? recordingButton : sendButton
        setStackViewItems([button], forStack: .right, animated: false)
        
    }
    
    public func updateRecordingDuration(){
        
    }
    
    @objc func multimediaButtonTapped(){
        self.hooksDelegate?.messageInputBar(self, multimediaButtonPressed: self.multimediaButton)
    }
    
    
    @objc func recordingButtonLongPress(_ sender: UILongPressGestureRecognizer){
        
        
        if timer == nil{
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (_) in
                self.recordingTime = self.recordingTime + 1
                self.updateRecordingIndicator(with: self.recordingTime)
            }
        }
        
        
        let locationPoint = sender.location(in: self)
        
        if locationPoint.x > UIScreen.main.bounds.width / 3{
            
            self.setLeftStackViewWidthConstant(to: locationPoint.x,
                                               animated: true)
        }else{
            self.stopTimer()
            self.showRecordingIndicator(show: false)
        }
        
        switch sender.state {
            
        case .began:
            
            UIView.animate(withDuration: 0.25) {
                self.recordingButton.tintColor = .red
                self.decorationRecordingButton.tintColor = .red
            }
            
            self.startTimer()
            self.showRecordingIndicator(show: true)

            
        case .cancelled:
            
            UIView.animate(withDuration: 0.25) {
                self.recordingButton.tintColor = .black
                self.decorationRecordingButton.tintColor = .black

            }
            
            self.stopTimer()
            self.showRecordingIndicator(show: false)
            
            
        case .ended:
            
            UIView.animate(withDuration: 0.25) {
                self.recordingButton.tintColor = .black
            }
            
            self.stopTimer()
            self.showRecordingIndicator(show: false)
            
            
        default:
            break
        }
        
        print("long gesture")
        self.hooksDelegate?.messageInputBar(self, recordingButtonLongPressed: sender)
        
    }
    
    
    //MARK: - helpers
    
    private func startTimer(){
        timer?.fire()
        self.recordingTime = 0
    }
    
    private func stopTimer(){
        timer?.invalidate()
        timer = nil
    }
    
    private func showRecordingIndicator(show:Bool){
                
        let widthLeftStack: CGFloat = show ? openLeftStackView : closeLeftStackView
        self.setLeftStackViewWidthConstant(to: widthLeftStack, animated: true)
        let leftStackItems:[InputItem] = show ? [decorationRecordingButton,labelRecordingText,slideToCancelText,slideToCancelButton] : [multimediaButton]
        self.setStackViewItems(leftStackItems, forStack: .left, animated: true)
        if !show { self.labelRecordingText.text = ""}
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        
       // if show{self.slideToCancelText.setupAnimation()}
        
        UIView.animate(withDuration: 0.25) {
            self.inputTextView.alpha = show ? 0 : 1
            self.labelRecordingText.alpha = show ? 1 : 0
        }
    }
    
    private func updateRecordingIndicator(with time: TimeInterval){
        
        labelRecordingText.text = "Duration: \(self.stringFromTimeInterval(interval: time))"
        
        slideToCancelText.text = "slide to cancel"

        let decorationRef = self.decorationRecordingButton
        
        UIView.animate(withDuration: 0.15) {
            decorationRef.alpha = decorationRef.alpha == 0 ? 1 : 0
        }
    }
    
    private func stringFromTimeInterval(interval: TimeInterval) -> NSString {
        
        let ti = NSInteger(interval)
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        return NSString(format: "%0.2d:%0.2d",minutes,seconds)
    }
    
}

//MARK: - IMPLEMENT INPUT ITEMS

class RecordingLabelInputItem: UILabel,InputItem{
    
    var messageInputBar: MessageInputBar?
    
    var parentStackViewPosition: InputStackView.Position?
    
    func textViewDidChangeAction(with textView: InputTextView) {
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func keyboardEditingEndsAction() {
        
    }
    
    func keyboardEditingBeginsAction() {
        
    }
}
