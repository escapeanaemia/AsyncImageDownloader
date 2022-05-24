//
//  DataSequence.swift
//  AsyncAwaitTest_2
//
//  Created by sky on 2022/04/19.
//

import Foundation

struct DataSequence: AsyncSequence {
    typealias Element = Data
    
    let urls: [URL]
    
    init(urls: [URL]) {
        self.urls = urls
    }
    
    // Sequence는 makeAsyncIterator를 구현 해 주지 않아도 되나 AsyncSequence는 구현해줘야 함
    func makeAsyncIterator() -> DataIterator {
        return DataIterator(urls: urls)
    }
    
}

struct DataIterator: AsyncIteratorProtocol {
    typealias Element = Data
    
    private var index = 0
    private let urlSession = URLSession.shared

    let urls: [URL]
    
    init(urls: [URL]) {
        self.urls = urls
    }
    
    mutating func next() async throws -> Data? {
        // Check bounds
        guard index < urls.count else {
            return nil
        }
        
        // URL, increment index
        let url = urls[index]
        index += 1
        
        // API Call
        let (data, _) = try await urlSession.data(from: url)
        
        print("index: \(index)")
        
        // Return Data
        return data
    }
}

struct APIDataSequence: AsyncSequence, AsyncIteratorProtocol {
    private var index = 0
    private let urlSession = URLSession.shared

    let urls: [URL]
    
    init(urls: [URL]) {
        self.urls = urls
    }
    
    mutating func next() async throws -> Data? {
        // Check bounds
        guard index < urls.count else {
            return nil
        }
        
        // URL, increment index
        let url = urls[index]
        index += 1
        
        // API Call
        let (data, _) = try await urlSession.data(from: url)
        
        print("index: \(index)")
        
        // Return Data
        return data
    }
    
    func makeAsyncIterator() -> APIDataSequence {
        self
    }
    
    typealias Element = Data
}
