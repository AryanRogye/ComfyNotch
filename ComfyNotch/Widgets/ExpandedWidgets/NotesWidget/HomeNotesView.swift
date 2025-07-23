//
//  HomeNotesView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/22/25.
//

import SwiftUI

struct HomeNotesView: View {
    
    @EnvironmentObject var model: NotesWidgetModel
    
    @Binding var addNewNoteOverlayIsPrented: Bool
    @Binding var currentView: NotesWidgetViewState
    
    @Binding var deletingNote: Note?
    @Binding var deleteNoteTriggered: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            topRow
                .padding(.horizontal)
                .padding(.top, 8)
            
            Divider()
                .padding(.vertical, 4)
            
            /// Default 3 notes
            ScrollView(.vertical, showsIndicators: true) {
                notesView()
            }
            .padding(.horizontal)
            .padding(.top, 4)
            .padding(.bottom, 8)
        }
    }
    
    private var topRow: some View {
        HStack {
            /// We wanna cool search bar here
            Spacer()
            Button(action: { addNewNoteOverlayIsPrented = true } ) {
                Image(systemName: "plus")
                    .resizable()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(.primary.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
    }
    
    @ViewBuilder
    func notesView() -> some View {
        ForEach(model.notes) { note in
            HStack(spacing: 8) {
                Text(note.name)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    deleteNoteTriggered = true
                    deletingNote = note
                }) {
                    Image(systemName: "trash")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 13, height: 13)
                        .foregroundColor(.red.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            // makes full row tappable
            .contentShape(Rectangle())
            .onTapGesture {
                currentView = .editor(note)
            }
        }
        
    }
}
