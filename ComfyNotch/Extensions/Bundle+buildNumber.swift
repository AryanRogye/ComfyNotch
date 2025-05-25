//
//  Bundle+buildNumber.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 5/24/25.
//

extension Bundle {
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as! String
    }
    var versionNumber: String {
        return infoDictionary?["CFBundleShortVersionString"] as! String
    }
}
