//
//  DetailsView.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/21/25.
//

import SwiftUI

struct DetailsView: View {
    
    @Binding var detailsClicked: Bool
    
    var body: some View {
        VStack{
            HStack {
                Text("There is a Limit to the Number of Widgets You Can Add, Change Your Notch Max Width")
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .foregroundColor(.primary)
                Spacer()
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .onTapGesture {
                        detailsClicked = false
                    }
            }
            .padding()
            
            Divider()
                .padding(.bottom, 8)
            
            VStack {
                HStack {
                    Text(" 'Less Than' Or '<' Notch Max Width")
                    Spacer()
                    Text("Widget Limits")
                }
                .padding()
                
                Divider()
                    .gridCellColumns(2)
                    .padding(.vertical, 4)
                
                HStack {
                    Text("500px")
                    Spacer()
                    Text("1 Widgets")
                }
                .padding()
                
                
                HStack {
                    Text("600px")
                    Spacer()
                    Text("2 Widgets")
                }
                .padding()
                
                HStack {
                    Text("750px")
                    Spacer()
                    Text("3 Widgets")
                }
                .padding()
                
                HStack {
                    Text("> 750px")
                    Spacer()
                    Text("4 Widgets")
                }
                .padding()
            }
            
        }
    }
}
