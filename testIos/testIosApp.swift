//
//  testIosApp.swift
//  testIos
//
//  Created by Peter Karoly Szokol on 2024. 10. 13..
//

import SwiftUI
import UIKit
import PhotosUI

@main
struct testIosApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(model: Model())
        }
    }
}

struct ImagePickerView: UIViewControllerRepresentable {
    
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> ViewController {
        let viewController = ViewController()
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
    }
    
    typealias UIViewControllerType = ViewController
}

class ViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupButtons()
    }
    
    func setupButtons() {
        let pickImageButton = UIButton(type: .system)
        pickImageButton.setTitle("Pick Image", for: .normal)
        pickImageButton.addTarget(self, action: #selector(pickImage), for: .touchUpInside)
        pickImageButton.frame = CGRect(x: 20, y: 100, width: 200, height: 50)
        view.addSubview(pickImageButton)
        
        let takePhotoButton = UIButton(type: .system)
        takePhotoButton.setTitle("Take Photo", for: .normal)
        takePhotoButton.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
        takePhotoButton.frame = CGRect(x: 20, y: 200, width: 200, height: 50)
        view.addSubview(takePhotoButton)
        
        let button3 = UIButton(type: .system)
        button3.setTitle("doc picker", for: .normal)
        button3.addTarget(self, action: #selector(openDocumentPicker), for: .touchUpInside)
        button3.frame = CGRect(x: 20, y: 300, width: 200, height: 50)
        view.addSubview(button3)
    }
    
    @objc func openDocumentPicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .jpeg, .png, .plainText])
        documentPicker.delegate = self
        documentPicker.allowsMultipleSelection = false
        present(documentPicker, animated: true)
    }
    
    @objc func pickImage() {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = 1
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = self
        present(picker, animated: true)
    }
    
    @objc func takePhoto() {
        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraAuthorizationStatus {
        case .authorized:
            openImagePicker()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.openImagePicker()
                    } else {
                        self.showCameraAccessDeniedAlert()
                    }
                }
            }
            
        case .restricted, .denied:
            showCameraAccessDeniedAlert()
            
        @unknown default:
            print("Unknown camera authorization status")
        }
    }
    
    private func openImagePicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            print("Camera not available")
            return
        }
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }
    
    private func showCameraAccessDeniedAlert() {
        let alert = UIAlertController(title: "Camera Access Denied", message: "Please enable camera access in settings.", preferredStyle: .alert)
        let goToSettings = UIAlertAction(title: "Settings", style: .default) { _ in
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl)
            }
        }
        let cancel = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(goToSettings)
        alert.addAction(cancel)
        present(alert, animated: true)
    }
    
    func uploadImage(image: UIImage, fileName: String) {
        guard let resourceURL = saveImageToTemp(image: image, fileName: fileName) else {
            return
        }
        
        do {
            let fileSize = try FileManager.default.attributesOfItem(atPath: resourceURL.path)[.size] as? Int64
            print("upload url: \(resourceURL), fileName: \(fileName).jpg size: \(fileSize ?? 0) bytes")
            showImageFromTempURL(resourceURL)
        }
        catch {
            
        }
    }
    
    @MainActor
    func showImageFromTempURL(_ url: URL) {
        // Create the image from the file path
        if let image = UIImage(contentsOfFile: url.path) {
            DispatchQueue.main.async { [weak self] in
                // Setup a basic view controller to show the image
                let imageViewController = UIViewController()
                imageViewController.view.backgroundColor = .white
                
                // Create an image view to show the image
                let imageView = UIImageView(image: image)
                imageView.contentMode = .scaleAspectFit
                imageView.frame = UIScreen.main.bounds
                
                // Add the image view to the view controller's view
                imageViewController.view.addSubview(imageView)
                
                self?.present(imageViewController, animated: true)
            }
            
            
            // Present the view controller
            /*if let topController = UIApplication.shared.keyWindow?.rootViewController {
                // Making sure the top controller is not already presenting another view controller
                if topController.presentedViewController == nil {
                    topController.present(imageViewController, animated: true, completion: nil)
                }
            }*/
        } else {
            print("Could not load image from the URL: \(url.path)")
        }
    }
    
    func saveImageToTemp(image: UIImage, fileName: String) -> URL? {
        guard let data = image.pngData() else { return nil }
        
        let tempURL = FileManager.default.temporaryDirectory
        let imageURL = tempURL.appendingPathComponent("\(fileName).jpg")
        
        do {
            try data.write(to: imageURL)
            print("Image saved to: \(imageURL)")
            let fileName = imageURL.lastPathComponent
            print("File name: \(fileName)")
            return imageURL
        } catch {
            print("Unable to save image to temporary directory: \(error)")
            return nil
        }
    }
}

extension ViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let itemProvider = results.first?.itemProvider else { return }
        
        if itemProvider.canLoadObject(ofClass: UIImage.self) {
            itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (image, error) in
                guard let image = image as? UIImage else { return }
                self?.fileName(for: itemProvider) { fileName in
                    self?.uploadImage(image: image, fileName: fileName ?? "asdasd")
                }
            }
        }
    }
    
    private func fileName(for itemProvider: NSItemProvider, callback: @escaping (String?) -> Void) {
        itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.image.identifier) { (url, error) in
            do {
                let resourceValues = try url?.resourceValues(forKeys: [.nameKey])
                if let fileNameWithExtension = resourceValues?.name {
                    let fileName = URL(fileURLWithPath: fileNameWithExtension).deletingPathExtension().lastPathComponent
                    callback(fileName)
                }
            } catch {
                print("Error retrieving file info: \(error)")
                callback(nil)
            }
        }
    }
}

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        dismiss(animated: true) {
            self.uploadImage(image: image, fileName: "asdasd")
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension ViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let pickedDocURL = urls.first else {
            print("No document was picked.")
            return
        }
        
        guard pickedDocURL.startAccessingSecurityScopedResource() else {
            print("Could not access the file's security-scoped resource.")
            return
        }
        
        // Use `defer` to stop accessing the resource when the function ends
        defer {
            pickedDocURL.stopAccessingSecurityScopedResource()
        }
        
        // Convert the URL to NSData
        let fileData = try? Data(contentsOf: pickedDocURL)
        let nsData = fileData as? NSData
        
        // Print some debug information
        print("Document picked URL: \(pickedDocURL)")
        print("File size (in bytes): \(String(describing: nsData?.length))")
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("Document picker was cancelled.")
    }
}
