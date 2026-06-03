import AdSupport
import AppTrackingTransparency
import UIKit

enum IDFAManager {
    private static let requestDelay: TimeInterval = 3
    
    static var currentIDFA: String {
        ASIdentifierManager.shared().advertisingIdentifier.uuidString
    }
    
    static func requestIfNeeded(delay: Bool, completion: ((String) -> Void)?) {
        if #available(iOS 14, *) {
            let status = ATTrackingManager.trackingAuthorizationStatus
            if status == .notDetermined {
                let request = {
                    ATTrackingManager.requestTrackingAuthorization { _ in
                        DispatchQueue.main.async {
                            completion?(currentIDFA)
                        }
                    }
                }
                if delay {
                    DispatchQueue.main.asyncAfter(deadline: .now() + requestDelay, execute: request)
                } else {
                    request()
                }
            } else {
                completion?(currentIDFA)
            }
        } else {
            completion?(currentIDFA)
        }
    }
}
