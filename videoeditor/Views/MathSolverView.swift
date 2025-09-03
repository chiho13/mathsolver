import SwiftUI
import PhotosUI

struct MathSolverView: View {
    @StateObject private var viewModel = VisionViewModel()
    // Add a @State property to hold the PhotosPickerItem
    @State private var selectedItem: PhotosPickerItem? = nil

    var body: some View {
        NavigationView {
            VStack {
                if let image = viewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(10)
                        .padding()
                } else {
                    VStack {
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.largeTitle)
                            .padding(.bottom)
                        Text("Select a photo of a math problem")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)
                    .padding()
                }
                
                // Use the new selectedItem @State property here
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    Label("Select Photo", systemImage: "photo")
                }
                .buttonStyle(.borderedProminent)
                .padding(.bottom)
                // Use .onChange to update the viewModel when selectedItem changes
               

                if viewModel.selectedImage != nil {
                    Button(action: {
                        Task {
                            await viewModel.solveMathProblem()
                        }
                    }) {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .frame(height: 20)
                        } else {
                            Text("Solve")
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoading)
                    .padding(.bottom)
                }

                if viewModel.isLoading {
                    ProgressView("Solving...")
                        .padding()
                }

                if !viewModel.visionResponse.isEmpty {
                    ScrollView {
                        Text(viewModel.visionResponse)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(10)
                    }
                    .padding()
                }

                if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 12) {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .padding()
                        
                        // Show helpful tips for no math content errors
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
            .navigationTitle("Math Solver")
        }
    }
}
