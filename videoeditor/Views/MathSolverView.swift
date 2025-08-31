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
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            if let uiImage = UIImage(data: data) {
                                viewModel.selectedImage = uiImage
                            }
                        }
                    }
                }

                if viewModel.selectedImage != nil {
                    Button(action: {
                        // Assuming your viewModel has a `solveMathProblem` method
                        
                        Task {
                               await viewModel.performVisionRequest()
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
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding()
                }

                Spacer()
            }
            .navigationTitle("Math Solver")
        }
    }
}
