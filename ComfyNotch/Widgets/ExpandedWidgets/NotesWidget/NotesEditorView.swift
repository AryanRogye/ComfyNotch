//
//  NotesEditorView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/22/25.
//

import SwiftUI

struct NotesEditorView: View {
    
    @EnvironmentObject var model: NotesWidgetModel
    
    var note: Note
    @Binding var currentView: NotesWidgetViewState
    
    var body: some View {
        VStack() {
            notesView
        }
    }
    
    private var notesView: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                topRow
            }
            .padding(.horizontal)
            .padding(.top, 4)
            
            Divider().padding(.top, 4).frame(alignment: .top)
            
            TextEditor(text: $model.text)
                .font(.system(size: model.currentFontSize))
                .foregroundColor(.white)
                .background(Color.black)
                .cornerRadius(8)
                .padding(.horizontal, 8)
                .padding(.top, 4)
        }
        .onAppear {
            model.selectedNoteID = note.id
            model.text = note.content
        }
        .onDisappear {
            saveNote()
        }
    }
    
    
    // MARK: - Top Row
    private var topRow: some View {
        HStack(alignment: .center) {
            Text("\(note.name)")
                .foregroundColor(.white)
            
            Spacer()
            
            Button(action: saveNote) {
                Image(systemName: "xmark")
                    .resizable()
                    .frame(width: 12, height: 12)
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
    }
    
    private func saveNote() {
        /// Save the note
        model.updateContent(for: note.id, newContent: model.text)
        model.text = ""
        // Close the editor and go back to the list
        currentView = .viewList
    }
}
