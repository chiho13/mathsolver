//
//  SolutionSheetView.swift
//  videoeditor
//
//  Created by Anthony Ho on 03/09/2025.
//


import SwiftUI

struct SolutionSheetView: View {
    
    @Binding var showSolutionSheet: Bool
    var visionResponse: String
    var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack {
                if !visionResponse.isEmpty {
                    ScrollView {
                        Text(visionResponse)
                            .padding()
                    }
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 12) {
                        Text(errorMessage.contains("No math problems detected") || errorMessage.contains("doesn't appear to contain mathematical content") ? "No math problem detected. Please try again." : errorMessage)
                            .foregroundColor(.red)
                            .padding()
                        
                        if errorMessage.contains("No math problems detected") || errorMessage.contains("doesn't appear to contain mathematical content") {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("📝 Tips for better results:")
                                    .font(.headline)
                                    .foregroundColor(.blue)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack(alignment: .top) {
                                        Text("•")
                                        Text("Make sure the image contains clear mathematical equations, formulas, or word problems")
                                    }
                                    HStack(alignment: .top) {
                                        Text("•")
                                        Text("Ensure text is readable and not blurry")
                                    }
                                    HStack(alignment: .top) {
                                        Text("•")
                                        Text("Include the full problem, not just parts of it")
                                    }
                                    HStack(alignment: .top) {
                                        Text("•")
                                        Text("Good lighting helps with text recognition")
                                    }
                                }
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(10)
                            .padding(.horizontal)
                        }
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
        .presentationDetents([.fraction(0.6), .large])
        .presentationDragIndicator(.visible)
    }
}