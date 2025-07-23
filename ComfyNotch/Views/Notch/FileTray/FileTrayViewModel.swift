//
//  FileTrayViewModel.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/23/25.
//

import SwiftUI

final class FileTrayViewModel: ObservableObject {
    
    
    // MARK: - Show File Thumbnail
    @ViewBuilder
    func showFileThumbnail(fileURL: URL) -> some View {
        AsyncImage(url: fileURL) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .scaledToFit()
            case .failure(_), .empty:
                Image(systemName: "doc.fill") // or "doc.text.fill", "doc.richtext", etc.
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(.gray)
                    .padding(10)
            @unknown default:
                EmptyView()
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .onDrag {
            NSItemProvider(contentsOf: fileURL)!
        }
        .padding(.top, 2)
    }
    
    
    // MARK: - Show File Name
    @ViewBuilder
    func showFileName(fileURL: URL, fileDropManager: FileDropManager) -> some View {
        Text(fileDropManager.getFormattedName(for: fileURL))
            .font(.system(size: 10, weight: .regular))
            .foregroundColor(.white)
            .lineLimit(1)
            .truncationMode(.tail)
            .frame(maxWidth: .infinity, alignment: .leading)
}
}
