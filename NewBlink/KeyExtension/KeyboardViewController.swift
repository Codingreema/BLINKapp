import UIKit
import SwiftUI

class KeyboardViewController: UIInputViewController {
    @State private var inputText: String = ""
    var currentBoard: Board? // تأكد من وجود كائن Board هنا

    override func viewDidLoad() {
        super.viewDidLoad()

        // إعداد MultimediaKeyboardView مع Binding
        let multimediaView = MultimediaKeyboardView(text: $inputText, currentBoard: currentBoard)

        // إعدادات العرض
        let hostingController = UIHostingController(rootView: multimediaView)
        hostingController.view.frame = self.view.bounds
        self.view.addSubview(hostingController.view)

        // Make sure the hosting controller's view is added to the input view
        self.inputView?.addSubview(hostingController.view)

        // Use translatesAutoresizingMaskIntoConstraints for automatic layout
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false

        // Add constraints to make the SwiftUI view fill the keyboard input view
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: self.inputView!.topAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: self.inputView!.bottomAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: self.inputView!.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: self.inputView!.trailingAnchor)
        ])

        // Make sure to set the keyboard size
        setKeyboardHeight()
    }

    private func setKeyboardHeight() {
        let keyboardHeight: CGFloat = 216
        let inputViewHeightConstraint = NSLayoutConstraint(item: self.inputView!,
                                                           attribute: .height,
                                                           relatedBy: .equal,
                                                           toItem: nil,
                                                           attribute: .notAnAttribute,
                                                           multiplier: 1.0,
                                                           constant: keyboardHeight)
        inputViewHeightConstraint.priority = UILayoutPriority(999)
        self.inputView?.addConstraint(inputViewHeightConstraint)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        for subview in view.subviews where subview is UIButton {
            subview.isHidden = !self.needsInputModeSwitchKey
        }
    }

    override func textWillChange(_ textInput: UITextInput?) {}

    override func textDidChange(_ textInput: UITextInput?) {}
}
