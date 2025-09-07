//
//  SolutionSheetView.swift
//  videoeditor
//
//  Created by Anthony Ho on 03/09/2025.
//


import SwiftUI
import SwiftMath

struct SolutionSheetView: View {
    
    @Binding var showSolutionSheet: Bool
    var visionResponse: String
    var errorMessage: String?
    @Binding var selectedDetent: PresentationDetent
    @Binding var dragOffset: CGFloat
    
    var body: some View {
        NavigationView {
            VStack {
                if !visionResponse.isEmpty {
                    ScrollView {
                        FormattedText(text: visionResponse)
                            .padding(.horizontal, 25)
                            .padding(.vertical)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .scrollIndicators(.visible)
                    .contentMargins(.horizontal, 0)
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 12) {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                    }
                } else {
                    // Loading view
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.5)
                        Text("Getting your solution...")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.top, 10)
                    }
                }
                Spacer()
            }
            .navigationTitle("Solution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        showSolutionSheet = false
                    }
                }
            }
        }
        .presentationDetents([.fraction(0.6), .large], selection: $selectedDetent)
        .presentationDragIndicator(.visible)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if selectedDetent == .large {
                        // Only track downward drags when sheet is fully expanded
                        if value.translation.height > 0 {
                            dragOffset = value.translation.height
                        }
                    }
                }
                .onEnded { _ in
                    // Reset drag offset when gesture ends
                    withAnimation(.spring()) {
                        dragOffset = 0
                    }
                }
        )
    }
}