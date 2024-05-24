//
//  ViewController.swift
//  Instafilter
//
//  Created by Rodrigo Cavalcanti on 21/05/24.
//

import UIKit
import CoreImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var changeFilterButton: UIButton!
    var imageView: UIImageView!
    var vStack: UIStackView!
    var currentImage: UIImage!
    
    var context: CIContext! // Core Image component that handles rendering. Creating a context is computationally expensive so we don't want to keep doing it.
    var currentFilter: CIFilter! {
        didSet {
            updateChangeFilterTitle()
        }
    } // Whatever filter the user has activated.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Instafilter"
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(importPicture))
        
        setupLayout()
        context = CIContext()
        currentFilter = CIFilter(name: "CISepiaTone")
    }
    
    @objc func importPicture() {
        let picker = UIImagePickerController()
        picker.allowsEditing = true
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        dismiss(animated: true)
        currentImage = image
        
        generateBeginImage()
    }

    @objc func changeFilter(_ sender: Any) {
        let ac = UIAlertController(title: "Choose filter", message: nil, preferredStyle: .actionSheet)
        ac.addAction(UIAlertAction(title: "CIBumpDistortion", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "CIGaussianBlur", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "CIPixellate", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "CISepiaTone", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "CITwirlDistortion", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "CIUnsharpMask", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "CIVignette", style: .default, handler: setFilter))
        ac.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(ac, animated: true)
    }
    
    func setFilter(action: UIAlertAction) {
        guard let currentImage, let actionTitle = action.title else { return }
        
        currentFilter = CIFilter(name: actionTitle)
        generateBeginImage()
    }
    
    func generateBeginImage() {
        let beginImage = CIImage(image: currentImage) //  Core Image equivalent of UIImage.
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey) // set our currentImage property as the input image for the currentFilter.
        updateSliders()
        applyProcessing()
    }
    
    func updateSliders() {
        for slider in vStack.arrangedSubviews {
            slider.removeFromSuperview()
        }
        
        let inputKeys = currentFilter.inputKeys
        
        for sliderKey in SliderKey.allCases {
            if inputKeys.contains(sliderKey.keyName) {
                let stack = UIStackView()
                stack.axis = .horizontal
                
                let label = UILabel()
                label.text = sliderKey.name
                label.translatesAutoresizingMaskIntoConstraints = false
                label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
                label.widthAnchor.constraint(equalToConstant: 75).isActive = true
                
                let newSlider = UISlider()
                newSlider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
                newSlider.tag = sliderKey.rawValue
                newSlider.minimumValue = 0.1
                newSlider.maximumValue = sliderKey.maxValue
                newSlider.value = sliderKey.maxValue
                
                stack.addArrangedSubview(label)
                stack.addArrangedSubview(newSlider)
                
                vStack.addArrangedSubview(stack)
            }
        }
    }
    
    @objc func save(_ sender: Any) {
        guard let image = imageView.image else {
            let ac = UIAlertController(title: "No image selected", message: nil, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
            return
        }
        UIImageWriteToSavedPhotosAlbum(
            image,
            self,
            #selector(image(_:didFinishSavingWithError:contextInfo:)),
            nil
        )
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error {
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    @objc func sliderValueChanged(_ sender: Any) {
        guard let sender = sender as? UISlider else { return }
        let key = SliderKey(rawValue: sender.tag)
        let value = sender.value
        applyProcessing(key: key, value: value)
    }
    
    func applyProcessing(key: SliderKey? = nil, value: Float? = nil) {
        guard let image = currentFilter.outputImage else { return }
        let inputKeys  = currentFilter.inputKeys
        
        if let key {
            currentFilter.setValue(value, forKey: key.keyName)
        } else {
            if inputKeys.contains(kCIInputIntensityKey) { // Not all filters support changing intensity.
                currentFilter.setValue(1, forKey: kCIInputIntensityKey) // uses the value of intensity slider to set the kCIInputIntensityKey value of our current Core Image filter. 0 means "no effect", 1 means "fully sepia."
            }
            
            if inputKeys.contains(kCIInputRadiusKey) {
                currentFilter.setValue(1 * 200, forKey: kCIInputRadiusKey)
            }
            
            if inputKeys.contains(kCIInputScaleKey) {
                currentFilter.setValue(1 * 10, forKey: kCIInputScaleKey)
            }
        }
        
        if inputKeys.contains(kCIInputCenterKey) {
            currentFilter.setValue(CIVector(x: currentImage.size.width / 2, y: currentImage.size.height / 2), forKey: kCIInputCenterKey)
        }
        
        if let cgImage = context.createCGImage(image, from: image.extent) { //  Creates a new data type called CGImage from the output image of the current filter. By using image.extent, specify that you want to render all of it.
            let processedImage = UIImage(cgImage: cgImage) // creates a new UIImage from the CGImage,
            imageView.image = processedImage
        }
    }
    
    func updateChangeFilterTitle() {
        let attributedText = NSMutableAttributedString(string: "Selected Filter\n", attributes: [NSAttributedString.Key.foregroundColor : UIColor.tintColor])
        attributedText.append(NSAttributedString(string: currentFilter.name, attributes: [NSAttributedString.Key.foregroundColor : UIColor.secondaryLabel]))
        
        changeFilterButton.setAttributedTitle(attributedText, for: .normal)
    }
    
    func setupLayout() {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.sizeToFit()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        view.addSubview(imageView)
        self.imageView = imageView
        
        let vStack = UIStackView()
        vStack.axis = .vertical
        vStack.spacing = 15
        vStack.sizeToFit()
        vStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(vStack)
        self.vStack = vStack
        
        let changeFilterButton = UIButton()
        changeFilterButton.addTarget(self, action: #selector(changeFilter), for: .touchUpInside)
        changeFilterButton.sizeToFit()
        changeFilterButton.titleLabel?.numberOfLines = 2
        changeFilterButton.titleLabel?.textAlignment = .center
        changeFilterButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(changeFilterButton)
        self.changeFilterButton = changeFilterButton
        
        let saveButton = UIButton()
        saveButton.setTitle("Save", for: .normal)
        saveButton.setTitleColor(.tintColor, for: .normal)
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        saveButton.sizeToFit()
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(saveButton)
        
        let horizontalPadding: CGFloat = 15
        let negateHorizontalPadding: CGFloat = -15
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: horizontalPadding),
            imageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: negateHorizontalPadding),
            imageView.heightAnchor.constraint(greaterThanOrEqualTo: view.heightAnchor, multiplier: 0.5),
            
            vStack.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            vStack.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: horizontalPadding),
            vStack.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: negateHorizontalPadding),
            vStack.heightAnchor.constraint(lessThanOrEqualTo: view.heightAnchor, multiplier: 0.3),
            vStack.heightAnchor.constraint(greaterThanOrEqualToConstant: 20),
            
            changeFilterButton.topAnchor.constraint(equalTo: vStack.bottomAnchor, constant: 20),
            changeFilterButton.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: horizontalPadding),
            changeFilterButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            changeFilterButton.heightAnchor.constraint(equalToConstant: 70),
            
            saveButton.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: negateHorizontalPadding),
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            saveButton.centerYAnchor.constraint(equalTo: changeFilterButton.centerYAnchor),
            saveButton.heightAnchor.constraint(equalToConstant: 70),
        ])
    }
}
