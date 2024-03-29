// Created 9/7/23
// swift-tools-version:5.0

import Foundation

#if canImport(UIKit)
import UIKit

/// With SwiftUI, the `UIApplication.shared.delegate` returns nil but the delegate can still be set
/// and still requires using the method
/// `application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?)`
/// to set up orientation properly. Overriding `supportedInterfaceOrientations` in the UIViewController is not enough.
///
/// syoung 09/28/2021
public class AppOrientationLockUtility {
    
    public static let willChange: Notification.Name = .init(rawValue: "AppOrientationLockUtilityWillChange")
    public static let didChange: Notification.Name = .init(rawValue: "AppOrientationLockUtilityDidChange")
    
    /// The current supported interface orientations.
    static public var currentOrientationLock: UIInterfaceOrientationMask {
        orientationLock ?? defaultOrientationLock
    }
    
    /// By default, should the device rotate using forced device rotation when setting the orientation lock?
    /// For apps that use a Storyboard and view controllers, this shouldn't be necessary b/c the view controllers will
    /// honor the `UIViewController.supportedInterfaceOrientations` property and the
    /// `UIViewController.shouldAutorotate`.
    ///
    /// As of this writing (syoung 09/30/2021) SwiftUI does not honor that property even when showing a
    /// view controller. Or more specfically, some OS versions and devices do and some do not. Therefore,
    /// if using SwiftUI as the main entry to the app, this must be set == `true` to force rotation changes.
    ///
    public static var shouldAutorotate: Bool = false
    
    /// The default orientation lock if not overridden by setting the `orientationLock` property.
    ///
    /// An application that requires the *default* to be either portrait or landscape, while still
    /// setting the app allowed orientations to allow some view controllers to rotate, must set
    /// this property to return those orientations only.
    ///
    static public var defaultOrientationLock: UIInterfaceOrientationMask = .portrait
    
    /// The `orientationLock` property is used to override the default allowed orientations.
    ///
    /// - seealso: `defaultOrientationLock`
    static public private(set) var orientationLock: UIInterfaceOrientationMask?
    
    static public func reset() {
        setOrientationLock(nil)
    }
    
    /// Set the orientation lock.
    static public func setOrientationLock(_ newValue: UIInterfaceOrientationMask?, rotateIfNeeded: Bool = shouldAutorotate) {
        guard newValue != orientationLock else { return }
        
        NotificationCenter.default.post(name: Self.willChange, object: self)
        
        orientationLock = newValue
       
        if rotateIfNeeded {
            rotate()
        }
        
        NotificationCenter.default.post(name: Self.didChange, object: self)
    }
    
    static func rotate() {
        guard let windowScene = UIApplication.shared.firstWindowScene else {
            return
        }
        
        // iOS 16 will throw a warning if you directly attempt to rotate the device.
        if #available(iOS 16.0, *) {
            windowScene.requestGeometryUpdate(.iOS(interfaceOrientations: currentOrientationLock))
            return
        }
        
        // else fallback to shoehorning in the device rotation.

        // Get initial orientation
        let device = UIDevice.current
        var orientation = UIDeviceOrientation(rawValue: windowScene.interfaceOrientation.rawValue) ?? device.orientation
        
        // Compare current to desired.
        switch currentOrientationLock {
        case .portrait:
            orientation = .portrait
        case .landscapeLeft:
            orientation = .landscapeLeft
        case .landscapeRight:
            orientation = .landscapeRight
        case .portraitUpsideDown:
            orientation = .portraitUpsideDown
        case .landscape:
            if orientation != .landscapeRight && orientation != .landscapeLeft {
                orientation = .landscapeRight
            }
        default:
            break
        }
        
        // Set the device orientation and rotate.
        device.setValue(orientation.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
    }
}

extension UIApplication {
    
    var firstWindowScene: UIWindowScene? {
        connectedScenes.first(where: { ($0.activationState == .foregroundActive) && ($0 is UIWindowScene) }) as? UIWindowScene
    }
}

extension UIInterfaceOrientationMask {
    func names() -> [String] {
        let mapping: [String : UIInterfaceOrientationMask] = [
            "portrait" : .portrait,
            "landscape" : .landscape
        ]
        return mapping.compactMap { self.contains($0.value) ? $0.key : nil }
    }
}

extension UIDeviceOrientation {
    var name: String {
        switch self {
        case .portrait:
            return "portrait"
        case .landscapeRight:
            return "landscapeRight"
        case .landscapeLeft:
            return "landscapeLeft"
        case .portraitUpsideDown:
            return "portraitUpsideDown"
        case .faceUp:
            return "faceUp"
        case .faceDown:
            return "faceDown"

        default:
            return "unknown"
        }
    }
}

#endif
