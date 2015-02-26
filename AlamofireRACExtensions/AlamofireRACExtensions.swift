//
//  AlamofireRACExtensions.swift
//  AlamofireRACExtensions
//
//  Created by Indragie on 2/25/15.
//  Copyright (c) 2015 Indragie Karunaratne. All rights reserved.
//

import Alamofire
import ReactiveCocoa
import LlamaKit

struct URLRequest: URLRequestConvertible {
    let method: Alamofire.Method
    let URL: URLStringConvertible
    let parameters: [String: AnyObject]?
    let encoding: ParameterEncoding = .URL
}

extension URLRequest: URLRequestConvertible {
    var URLRequest: NSURLRequest {
        let mutableURLRequest = NSMutableURLRequest(URL: NSURL(string: URL.URLString)!)
        mutableURLRequest.HTTPMethod = method.rawValue
        return encoding.encode(mutableURLRequest, parameters: parameters).0
    }
}

extension Alamofire.Manager {
    func rac_request(request: URLRequestConvertible, serializer: Alamofire.Request.Serializer) -> SignalProducer<(AnyObject, NSHTTPURLResponse), NSError> {
        return SignalProducer { observer, disposable in
            let request = self.request(request)
                .validate()
                .response { (request, response, responseObject, error) in
                    if let error = error {
                        sendError(observer, error)
                    } else if let response = response {
                        if let responseObject: AnyObject = responseObject {
                            sendNext(observer, (responseObject, response))
                        } else {
                            fatalError("Received no response object for successful response \(response) from request \(request)")
                        }
                    } else {
                        fatalError("Invalid response -- no HTTP response or error")
                    }
            }
            request.resume()
            disposable.addDisposable {
                request.cancel()
            }
        }
    }
    
    func rac_dataWithRequest(request: URLRequestConvertible) -> SignalProducer<(NSData, NSHTTPURLResponse), NSError> {
        return rac_request(request, serializer: Alamofire.Request.responseDataSerializer()).lift(map { (object, response) in
            if let data = object as? NSData {
                return (data, response)
            } else {
                fatalError("Response object \(object) is not of type NSData")
            }
        })
    }
    
    func rac_JSONWithRequest(request: URLRequestConvertible, options: NSJSONReadingOptions = .allZeros) -> SignalProducer<(AnyObject, NSHTTPURLResponse), NSError> {
        return rac_request(request, serializer: Alamofire.Request.JSONResponseSerializer(options: options))
    }
    
    func rac_propertyListWithRequest(request: URLRequestConvertible, options: NSPropertyListReadOptions = .allZeros) -> SignalProducer<(AnyObject, NSHTTPURLResponse), NSError> {
        return rac_request(request, serializer: Alamofire.Request.propertyListResponseSerializer(options: options))
    }
}
