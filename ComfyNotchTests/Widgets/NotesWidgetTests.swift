//
//  NotesWidgetTests.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/22/25.
//

import XCTest
@testable import ComfyNotch

final class NotesWidgetTests: XCTestCase {
    
    var testDefaults: UserDefaults!
    
    var settings: SettingsModel!
    var model: NotesWidgetModel!
    
    override func setUp() {
        super.setUp()
        
        testDefaults = UserDefaults(suiteName: "com.aryan.test.settings")
        resetDefaults()

        settings = SettingsModel(userDefaults: testDefaults)
        model = NotesWidgetModel(userDefaults: testDefaults)
    }
    
    
    func testAddNote() {
        model.addNote(title: "Test Note")
        XCTAssertEqual(model.notes.count, 1)
        XCTAssertEqual(model.notes.first?.name, "Test Note")
        XCTAssertEqual(model.selectedNoteID, model.notes.first?.id)
    }
    
    func testUpdateNoteContent() {
        model.addNote(title: "Editable")
        guard let id = model.notes.first?.id else {
            XCTFail("No note to update")
            return
        }
        
        model.updateContent(for: id, newContent: "Updated!")
        XCTAssertEqual(model.notes.first?.content, "Updated!")
    }
    
    func testDeleteNote() {
        model.addNote(title: "To Delete")
        let note = model.notes.first!
        model.deleteNote(note)
        XCTAssertTrue(model.notes.isEmpty)
    }
    
    func testPersistenceBetweenLoads() {
        model.addNote(title: "Persistent Note")
        let savedID = model.selectedNoteID
        
        // Simulate reloading model
        model = NotesWidgetModel(userDefaults: testDefaults)
        
        XCTAssertEqual(model.notes.count, 1)
        XCTAssertEqual(model.notes.first?.name, "Persistent Note")
        XCTAssertEqual(model.selectedNoteID, savedID)
    }
    
    
    
    
    
    
    override func tearDown() {
        resetDefaults()
        model = nil
        super.tearDown()
        
        testDefaults.removePersistentDomain(forName: "com.aryan.test.settings")
        testDefaults = nil
        settings = nil
        super.tearDown()
    }
    
    private func resetDefaults() {
        testDefaults.removePersistentDomain(forName: "com.aryan.test.settings")
    }
}
