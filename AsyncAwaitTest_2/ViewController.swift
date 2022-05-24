//
//  ViewController.swift
//  AsyncAwaitTest_2
//
//  Created by sky on 2022/04/18.
//

import UIKit

enum TestError: Error {
    case defaultError
}

class ViewController: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    
    @IBOutlet weak var progressView: UIProgressView!
    
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    @IBOutlet weak var imageView4: UIImageView!
    @IBOutlet weak var imageView5: UIImageView!
    @IBOutlet weak var imageView6: UIImageView!
    
    @IBOutlet weak var progressView1: UIProgressView!
    @IBOutlet weak var progressView2: UIProgressView!
    @IBOutlet weak var progressView3: UIProgressView!
    @IBOutlet weak var progressView4: UIProgressView!
    @IBOutlet weak var progressView5: UIProgressView!
    @IBOutlet weak var progressView6: UIProgressView!
    
    var imageViews: [UIImageView] = []
    var progressViews: [UIProgressView] = []
    let imageAddresses: [URL] = [
        URL(string:"https://picsum.photos/seed/picsum/5000/5000")!, // big
        URL(string:"https://picsum.photos/seed/picsum/3000/3000")!,
        URL(string:"https://picsum.photos/seed/picsum/1000/1000")!,
        URL(string:"https://picsum.photos/seed/picsum/500/500")!, // big
        URL(string:"https://picsum.photos/seed/picsum/100/100")!,
        URL(string:"https://picsum.photos/seed/picsum/10/10")!,
    ]
    
    // images from https://picsum.photos/
    let strImageUrls:[String] = [
        "https://picsum.photos/seed/picsum/5000/5000",
        "https://picsum.photos/seed/picsum/5000/5000",
        "https://picsum.photos/seed/picsum/5000/5000",
        "https://picsum.photos/seed/picsum/5000/5000?grayscale",
        "https://picsum.photos/seed/picsum/5000/5000?grayscale",
//        "https://picsum.photos/seed/picsum/5000/5000?grayscale",
        "error-url",
//        "https://picsum.photos/seed/picsum/3000/3000",
//        "https://picsum.photos/seed/picsum/1000/1000",
//        "https://picsum.photos/seed/picsum/500/500",
//        "https://picsum.photos/seed/picsum/100/100",
//        "https://picsum.photos/seed/picsum/10/10",
    ]
    override func viewDidLoad() {
        super.viewDidLoad()
        
        imageViews = [imageView1, imageView2, imageView3, imageView4, imageView5, imageView6]
        progressViews = [progressView1, progressView2, progressView3, progressView4, progressView5, progressView6]
        
        Task {
            try await fetchImages(from: strImageUrls)
        }
    }
    
    enum FetchError: Error {
        case invalidURL
    }
    
    func fetchImages(from urls: [String]) async throws { //throws -> [UIImage] {
        
//        try await withTaskGroup(of: UIImage?.self) { group in
//
//        }
        do {
        try await withThrowingTaskGroup(of: UIImage?.self, body: { group in
            for urlStr in urls {
                
                var priority : TaskPriority = .low
                if urlStr == "https://picsum.photos/seed/picsum/5000/5000" {
                    priority = .high
                }
                
                
                group.addTask(priority: priority) {
                    guard let url = URL(string: urlStr) else {
                        return nil }
                    return try await self.fetchOneImage(url: url)
                }
                
                if urlStr == "error-url" {
                    
                    group.cancelAll()
                    throw  FetchError.invalidURL
                }
            }
            
            var index = 0
            for try await image in group {
                index += 1
                await updateImage(image: image, index: index)
            }
            /*
             for 문을 사용해도 되고 아니면 아래 처럼 해도 됩니다.
             
             if let image = try await group.next() {
                await updateImage(image: image, index:index)
             } else {
                더이상 child task가 존재하지 않는 상태엔 nil을 반환
             }
             */
        })
        } catch {
            print("@@@ error catched")
        }
        
    }
    
    func fetchOneImage(url: URL) async throws -> UIImage? {
        print("@@@ fetch image start with url - \(url.absoluteString)")
        let (imageData, _) = try await URLSession.shared.data(from: url)
        
        return UIImage(data: imageData)
        
    }
    
    // MARK: - AsyncSequence + Parallel
    func requestImageParallel() async {
        async let image1 = requestImageInProgressWithUrl(1, url: imageAddresses[0])
        async let image2 = requestImageInProgressWithUrl(2, url: imageAddresses[1])
        async let image3 = requestImageInProgressWithUrl(3, url: imageAddresses[2])
        async let image4 = requestImageInProgressWithUrl(4, url: imageAddresses[3])
        async let image5 = requestImageInProgressWithUrl(5, url: imageAddresses[4])
        async let image6 = requestImageInProgressWithUrl(6, url: imageAddresses[5])
        
        
        let imageDatum = try await [image1, image2, image3, image4, image5, image6]
        
        for (index, imageData) in imageDatum.enumerated() {
            await updateImage(image: imageData, index: index + 1)
        }
    }
    
    func requestImageInProgressWithUrl(_ index: Int, url: URL) async -> UIImage? {
        do {
            let (asyncBytes, urlResponse) = try await URLSession.shared.bytes(from: url)
            let length = (urlResponse.expectedContentLength)
            var data = Data()
            data.reserveCapacity(Int(length))

            for try await byte in asyncBytes {
                data.append(byte)
                let progress = Double(data.count) / Double(length)
                await progressUpdate(progress: Float(progress), index: index)
            }
            print("\(index)번 이미지 다운완료")
            return UIImage(data: data)
        } catch {
            return nil
        }
    }
    
    @MainActor func progressUpdate(progress: Float) async {
        self.progressView.progress = progress
    }
    
    @MainActor func progressUpdate(progress: Float, index: Int) async {
        progressViews[index - 1].progress = progress
    }
    
    @MainActor func updateImage(image: UIImage?, index: Int) async {
        print("@@@ update image index at \(index)")
        imageViews[index - 1].image = image
    }
}
