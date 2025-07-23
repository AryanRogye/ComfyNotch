//
//  DeleteNoteView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/22/25.
//

import SwiftUI

public struct DeleteNoteView: View {
    
    @EnvironmentObject var model: NotesWidgetModel
    
    @Binding public var deleteNoteTriggered: Bool
    @Binding var deletingNote: Note?
    
    
    //    model.deleteNote(note)
    
    public var body: some View {
        VStack(spacing: 0) {
            topRow
                .padding([.horizontal])
                .padding(.top, 4)
            Divider()
                .padding(.top, 4)

            Spacer()
            
            deleteNote
                .padding([.horizontal])
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var deleteNote: some View {
        HStack {
            if let note = deletingNote {
                
                Text("Are you sure you want to delete this note?")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    model.deleteNote(note)
                    deletingNote = nil
                    deleteNoteTriggered = false
                }) {
                    Text("Yes")
                }
            }
        }
    }
    
    private var topRow: some View {
        HStack {
            HStack {
                if let note = deletingNote {
                    VStack(alignment: .leading) {
                        Text(note.name)
                            .font(.headline)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    deletingNote = nil
                    deleteNoteTriggered = false
                }) {
                    Image(systemName: "xmark")
                        .resizable()
                        .frame(width: 12, height: 12)
                }
                .buttonStyle(.plain)
            }
        }
    }
}
