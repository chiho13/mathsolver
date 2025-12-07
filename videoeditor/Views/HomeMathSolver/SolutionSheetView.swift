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
    @State private var showCopyAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                if !visionResponse.isEmpty {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            // Enhanced solution header
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                
                                Text("Solution")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                            
                            // Solution content with better styling
                            FormattedText(text: visionResponse)
                                .padding(.horizontal, 16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }.padding(.horizontal, 16)
                    }
                    .scrollIndicators(.visible)
                    
                    // Action buttons
                    VStack(spacing: 12) {
                        Divider()
                            .padding(.horizontal, 16)
                        
                        HStack(spacing: 16) {
                            // Copy button
                            Button(action: {
                                UIPasteboard.general.string = visionResponse
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                showCopyAlert = true
                            }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Copy")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.accentColor)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.accentColor.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .accessibilityLabel("Copy solution to clipboard")
                            
                            // Share button
                            ShareLink(item: visionResponse) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Share")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .frame(height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.primary.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                                        )
                                )
                            }
                            .accessibilityLabel("Share solution")
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 16)
                    }
                    
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                            .padding(.top, 40)
                        
                        Text("Something went wrong")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text(errorMessage)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                        
                        Spacer()
                    }
                } else {
                    // Enhanced loading view using our new component
                    VStack {
                        Spacer()
                        MathSolvingLoadingView()
                        Spacer()
                    }
                }
            }
            .navigationTitle("Math Solution")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                        impactFeedback.impactOccurred()
                        showSolutionSheet = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .alert("Copied!", isPresented: $showCopyAlert) {
            Button("OK") { }
        } message: {
            Text("Solution copied to clipboard")
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