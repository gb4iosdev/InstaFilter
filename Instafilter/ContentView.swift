//
//  ContentView.swift
//  Instafilter
//
//  Created by Gavin Butler on 19-08-2020.
//  Copyright © 2020 Gavin Butler. All rights reserved.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    @State private var image: Image?
    @State private var filterIntensity = 0.5
    @State private var filterRadius = 0.5
    @State private var filterScale = 0.5
    
    @State private var showingIntensitySlider = true
    @State private var showingRadiusSlider = false
    @State private var showingScaleSlider = false
    
    @State private var showingFilterSheet = false
    
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    @State private var processedImage: UIImage?
    
    @State var currentFilter: CIFilter = CIFilter.sepiaTone()
    let context = CIContext()
    
    @State private var showingNoImageToSaveAlert = false
    
    @State private var filterButtonTitle: String = "Change Filter"
    
    var body: some View {
        let intensity = Binding<Double>(
            get: {
                self.filterIntensity
            },
            set: {
                self.filterIntensity = $0
                self.applyProcessing()
            }
        )
        let radius = Binding<Double>(
            get: {
                self.filterRadius
            },
            set: {
                self.filterRadius = $0
                self.applyProcessing()
            }
        )
        let scale = Binding<Double>(
            get: {
                self.filterScale
            },
            set: {
                self.filterScale = $0
                self.applyProcessing()
            }
        )
        
        return NavigationView {
            VStack {
                ZStack {
                    Rectangle()
                    .fill(Color.secondary)
                    
                    if image != nil {
                        image?
                        .resizable()
                        .scaledToFit()
                    } else {
                        Text("Tap to select a picture")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                }
                .onTapGesture {
                    self.showingImagePicker = true
                }
                VStack {
                    HStack {
                        Text("Intensity")
                        .foregroundColor(showingIntensitySlider ? Color.black : Color.gray)
                        Slider(value: intensity)
                        .disabled(!showingIntensitySlider)
                    }
                    .padding(.vertical)
                    HStack {
                        Text("Radius")
                        .foregroundColor(showingRadiusSlider ? Color.black : Color.gray)
                        Slider(value: radius)
                        .disabled(!showingRadiusSlider)
                    }
                    .padding(.vertical)
                    HStack {
                        Text("Scale")
                        .foregroundColor(showingScaleSlider ? Color.black : Color.gray)
                        Slider(value: scale)
                        .disabled(!showingScaleSlider)
                    }
                    .padding(.vertical)
                }
                
                HStack {
                    Button(filterButtonTitle) {
                        self.showingFilterSheet = true
                        self.showingIntensitySlider = false
                        self.showingRadiusSlider = false
                        self.showingScaleSlider = false
                    }
                    Spacer()
                    Button("Save") {
                        guard let processedImage = self.processedImage else {
                            self.showingNoImageToSaveAlert = true
                            return
                        }
                        
                        let imageSaver = ImageSaver()
                        imageSaver.successHandler = { print("Success") }
                        imageSaver.errorHandler = { print("Oops: \($0.localizedDescription)") }
                        imageSaver.writeToPhotoAlbum(image: processedImage)
                    }
                    
                }
            }
            .padding([.horizontal, .bottom])
            .navigationBarTitle("Instafilter")
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: self.$inputImage)
            }
            .alert(isPresented: $showingNoImageToSaveAlert) {
                Alert(title: Text("No Photo to Save"), message: Text("Please select a photo and apply a filter before saving"), dismissButton: .default(Text("OK")))
            }
            .actionSheet(isPresented: $showingFilterSheet) {
                ActionSheet(title: Text("Select a filter"), buttons: [
                    .default(Text("Crystalize")) {
                        self.setFilter(CIFilter.crystallize())
                        self.filterButtonTitle = "Crystalize"
                    },
                    .default(Text("Edges")) {
                        self.setFilter(CIFilter.edges())
                        self.filterButtonTitle = "Edges"
                    },
                    .default(Text("Gaussian Blur")) {
                        self.setFilter(CIFilter.gaussianBlur())
                        self.filterButtonTitle = "Gaussian Blur"
                    },
                    .default(Text("Pixellate")) {
                        self.setFilter(CIFilter.pixellate())
                        self.filterButtonTitle = "Pixellate"
                    },
                    .default(Text("Sepia Tone")) {
                        self.setFilter(CIFilter.sepiaTone())
                        self.filterButtonTitle = "Sepia Tone"
                    },
                    .default(Text("Unsharp Mask")) {
                        self.setFilter(CIFilter.unsharpMask())
                        self.filterButtonTitle = "Unsharp Mask"
                    },
                    .default(Text("Vignette")) {
                        self.setFilter(CIFilter.vignette())
                        self.filterButtonTitle = "Vignette"
                    },
                    .cancel()
                ])
            }
        }
    }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        
        let beginImage = CIImage(image: inputImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        applyProcessing()
    }
    
    func applyProcessing() {
        let inputKeys = currentFilter.inputKeys
        if inputKeys.contains(kCIInputIntensityKey) {
            currentFilter.setValue(filterIntensity, forKey: kCIInputIntensityKey)
            self.showingIntensitySlider = true
        }
        if inputKeys.contains(kCIInputRadiusKey) {
            currentFilter.setValue(filterRadius * 200, forKey: kCIInputRadiusKey)
            self.showingRadiusSlider = true
        }
        if inputKeys.contains(kCIInputScaleKey) {
            currentFilter.setValue(filterIntensity * 10, forKey: kCIInputScaleKey)
            self.showingScaleSlider = true
        }
        
        guard let outputImage = currentFilter.outputImage else { return }
        
        if let cgImg = context.createCGImage(outputImage, from: outputImage.extent) {
            let uiImage = UIImage(cgImage: cgImg)
            image = Image(uiImage: uiImage)
            processedImage = uiImage
        }
    }
    
    func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

//Using coordinators to manage SwiftUI view controllers & saving images to the user's photo library:
/*class ImageSaver: NSObject {
    func writeToPhotoAlbum(image: UIImage) {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(saveError), nil)
    }
    
    @objc func saveError(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        print("Save Finished!")
    }
}

struct ContentView: View {
    @State private var image: Image?
    @State private var showingImagePicker = false
    @State private var inputImage: UIImage?
    
    var body: some View {
        VStack {
            image?
            .resizable()
            .scaledToFit()
            
            Button("Select Image") {
                self.showingImagePicker = true
            }
        }
        .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
            ImagePicker(image: self.$inputImage)
        }
    }
    
    func loadImage() {
        guard let inputImage = inputImage else { return }
        image = Image(uiImage: inputImage)
        let imageSaver = ImageSaver()
        imageSaver.writeToPhotoAlbum(image: inputImage)
    }
}
 struct ImagePicker: UIViewControllerRepresentable {
     class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
         var parent: ImagePicker
         
         init(_ parent: ImagePicker) {
             self.parent = parent
         }
         
         func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
             if let uiImage = info[.originalImage] as? UIImage {
                 parent.image = uiImage
             }
             parent.presentationMode.wrappedValue.dismiss()
         }
     }
     
     @Binding var image: UIImage?
     @Environment(\.presentationMode) var presentationMode
     
     func makeCoordinator() -> Coordinator {
         Coordinator(self)
     }
     
     func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {
         let picker = UIImagePickerController()
         picker.delegate = context.coordinator
         return picker
     }
     
     func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {
         
     }
 }*/

//Wrapping a UIViewController in a SwiftUI view
/*struct ContentView: View {
    @State private var image: Image?
    @State private var showingImagePicker = false
    
    var body: some View {
        VStack {
            image?
            .resizable()
            .scaledToFit()
            
            Button("Select Image") {
                self.showingImagePicker = true
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker()
        }
    }
}
 struct ImagePicker: UIViewControllerRepresentable {
     func makeUIViewController(context: Context) -> UIImagePickerController {
         let picker = UIImagePickerController()
         return picker
     }
     
     func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
         
     }
 }*/

//Complex Image filters:
/*struct ContentView: View {
    @State private var image: Image?
    
    var body: some View {
        VStack {
            image?
                .resizable()
                .scaledToFit()
        }
        .onAppear(perform: loadImage)
    }
    
    func loadImage() {
        guard let inputImage = UIImage(named: "mort") else { return }
        
        let beginImage = CIImage(image: inputImage)
        
        let context = CIContext()
        /*let currentFilter = CIFilter.sepiaTone()
        currentFilter.intensity = 1
        currentFilter.inputImage = beginImage*/
        
        /*let currentFilter = CIFilter.pixellate()
        currentFilter.scale = 5
        currentFilter.inputImage = beginImage*/
        
        guard let currentFilter = CIFilter(name: "CITwirlDistortion") else { return }
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        currentFilter.setValue(100, forKey: kCIInputRadiusKey)
        currentFilter.setValue(CIVector(x: inputImage.size.width / 2, y: inputImage.size.height / 2), forKey: kCIInputCenterKey)
        
        
        guard let outputImage = currentFilter.outputImage else { return }
        
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            let uiImage = UIImage(cgImage: cgimg)
            image = Image(uiImage: uiImage)
        }
    }
}*/

//Simple code to be able to load image with code intervention (can do anything in the loadImage function)
/*struct ContentView: View {
    @State private var image: Image?
    
    var body: some View {
        VStack {
            image?
                .resizable()
                .scaledToFit()
        }
        .onAppear(perform: loadImage)
    }
    
    func loadImage() {
        image = Image("mort")
    }
}*/

//ActionSheet:
/*struct ContentView: View {
    @State private var showingActionSheet = false
    @State private var backgroundColour = Color.white
    
    var body: some View {
        Text("Hello Folks!")
            .frame(width: 300, height: 300)
            .background(backgroundColour)
            .onTapGesture {
                self.showingActionSheet = true
            }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(title: Text("Change background"), message: Text("Select a new colour"), buttons: [
                .default(Text("Red")) { self.backgroundColour = .red },
                .default(Text("Green")) { self.backgroundColour = .green },
                .default(Text("Blue")) { self.backgroundColour = .blue },
                .cancel()
                ])
        }
        .animation(.easeInOut(duration: 0.5))
    }
}*/

//Custom Bindings: allow us to execute other code within the closures when the value changes (such as printing it's value).  Note that $blurAmount is no longer used in the slider.
/*struct ContentView: View {
    @State private var blurAmount: CGFloat = 0
    
    var body: some View {
        
        let blur = Binding<CGFloat>(
            get: {
                self.blurAmount
            },
            set: {
                self.blurAmount = $0
                print("New value is \(self.blurAmount)")
            }
        )
        
        return VStack {
            Text("Hello, World!")
            .blur(radius: blurAmount)
            
            Slider(value: blur, in: 0...3)
        }
    }
}*/
