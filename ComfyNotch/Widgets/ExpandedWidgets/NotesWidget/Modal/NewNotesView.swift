//
//  NewNotesView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/22/25.
//

import SwiftUI

struct NewNotesView: View {
    
    @EnvironmentObject var model: NotesWidgetModel
    @Binding var addNewNoteOverlayIsPresented: Bool
    @State private var newNoteName: String = ""
    
    var body: some View {
        VStack(spacing: 0) {
            topRow
                .padding([.horizontal])
                .padding(.top, 4)
            
            Divider()
                .padding(.top, 4)
            
            Spacer()
            
            addNameButton
                .padding([.horizontal])
                .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Add Button
    private var addNameButton: some View {
        HStack {
            VStack(alignment: .leading) {
                TextField("Select A Name",text: $newNoteName)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        submit()
                    }
            }
            .padding(.trailing)
            
            
            VStack(alignment: .trailing) {
                Button(action: submit) {
                    Text("Add")
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .font(.system(size: 20, weight: .semibold, design: .default))
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(newNoteName.trimmingCharacters(in: .whitespaces).isEmpty)
                .controlSize(.mini)
            }
            
        }
    }
    
    // MARK: - Submit Action
    private func submit() {
        model.addNote(title: newNoteName)
        addNewNoteOverlayIsPresented = false
        newNoteName = ""
        /// add new note to the list cuz it wont update
    }
    
    
    // MARK: - Top Row (name/exit)
    private var topRow: some View {
        HStack(alignment: .center) {
            
            VStack(alignment: .leading) {
                Text("Create a New Note")
                    .font(.headline)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Button(action: {
                    addNewNoteOverlayIsPresented = false
                    newNoteName = ""
                }) {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 12, height: 12)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
