//
//  ComfyNotchSpaceManager.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 8/8/25.
//

import Foundation
import AppKit

final class CGSBridge {
    typealias Connection = UInt
    typealias Space = UInt64
    
    private let conn: Connection
    
    private let createSpace: @convention(c) (Connection, Int32, CFDictionary?) -> Space
    private let destroySpace: @convention(c) (Connection, Space) -> Void
    private let setLevel: @convention(c) (Connection, Space, Int32) -> Void
    private let addWindows: @convention(c) (Connection, CFArray, CFArray) -> Void
    private let removeWindows: @convention(c) (Connection, CFArray, CFArray) -> Void
    private let showSpaces: @convention(c) (Connection, CFArray) -> Void
    private let hideSpaces: @convention(c) (Connection, CFArray) -> Void
    
    init?() {
        guard
            let h = dlopen("/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics", RTLD_NOW),
            let getConn = unsafeBitCast(dlsym(h, "_CGSDefaultConnection"), to: (@convention(c) () -> Connection)?.self),
            let create = unsafeBitCast(dlsym(h, "CGSSpaceCreate"), to: (@convention(c) (Connection, Int32, CFDictionary?) -> Space)?.self),
            let destroy = unsafeBitCast(dlsym(h, "CGSSpaceDestroy"), to: (@convention(c) (Connection, Space) -> Void)?.self),
            let setLvl = unsafeBitCast(dlsym(h, "CGSSpaceSetAbsoluteLevel"), to: (@convention(c) (Connection, Space, Int32) -> Void)?.self),
            let addWin = unsafeBitCast(dlsym(h, "CGSAddWindowsToSpaces"), to: (@convention(c) (Connection, CFArray, CFArray) -> Void)?.self),
            let rmWin = unsafeBitCast(dlsym(h, "CGSRemoveWindowsFromSpaces"), to: (@convention(c) (Connection, CFArray, CFArray) -> Void)?.self),
            let show = unsafeBitCast(dlsym(h, "CGSShowSpaces"), to: (@convention(c) (Connection, CFArray) -> Void)?.self),
            let hide = unsafeBitCast(dlsym(h, "CGSHideSpaces"), to: (@convention(c) (Connection, CFArray) -> Void)?.self)
        else { return nil }
        
        self.conn = getConn()
        self.createSpace = create
        self.destroySpace = destroy
        self.setLevel = setLvl
        self.addWindows = addWin
        self.removeWindows = rmWin
        self.showSpaces = show
        self.hideSpaces = hide
    }
    
    func newSpace(level: Int32) -> Space {
        let s = createSpace(conn, 1, nil)
        setLevel(conn, s, level)
        showSpaces(conn, [s] as CFArray)
        return s
    }
    
    func destroy(_ space: Space) {
        hideSpaces(conn, [space] as CFArray)
        destroySpace(conn, space)
    }
    
    func add(_ window: NSWindow, to space: Space) {
        addWindows(conn, [window.windowNumber] as CFArray, [space] as CFArray)
    }
    
    func remove(_ window: NSWindow, from space: Space) {
        removeWindows(conn, [window.windowNumber] as CFArray, [space] as CFArray)
    }
}

class ComfyNotchSpaceManager {
    private var cgs: CGSBridge
    private var space: CGSBridge.Space
    
    init?() {
        guard let bridge = CGSBridge() else { return nil }
        self.cgs = bridge
        self.space = bridge.newSpace(level: Int32.max)
    }
    
    deinit {
        cgs.destroy(space)
    }
    
    func putPanelInSpace(_ panel: NSPanel) {
        DispatchQueue.main.async {
            if panel.windowNumber == 0 { panel.orderFrontRegardless() }
            self.cgs.add(panel, to: self.space)
        }
    }
    
    func resetSpace(attaching panel: NSPanel) {
        DispatchQueue.main.async {
            self.cgs.destroy(self.space)
            self.space = self.cgs.newSpace(level: Int32.max)
            if panel.windowNumber == 0 { panel.orderFrontRegardless() }
            self.cgs.add(panel, to: self.space)
        }
    }
}
