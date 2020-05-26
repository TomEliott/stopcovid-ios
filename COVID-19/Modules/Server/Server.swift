// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//
//  Server.swift
//  STOP-COVID
//
//  Created by Lunabee Studio / Date - 23/04/2020 - for the STOP-COVID project.
//

import Foundation
import RobertSDK

final class Server: NSObject, RBServer {
    
    enum Method: String {
        case get = "GET"
        case post = "POST"
    }
    
    typealias ProcessRequestCompletion = (_ result: Result<Data, Error>) -> ()
    
    private lazy var session: URLSession = {
        let backgroundConfiguration: URLSessionConfiguration = URLSessionConfiguration.background(withIdentifier: "StopCovid")
        return URLSession(configuration: backgroundConfiguration, delegate: self, delegateQueue: .main)
    }()
    private var receivedData: [String: Data] = [:]
    private var completions: [String: ProcessRequestCompletion] = [:]
    
    func status(ebid: String, time: String, mac: String, completion: @escaping (_ result: Result<RBStatusResponse, Error>) -> ()) {
        let body: RBServerStatusBody = RBServerStatusBody(ebid: ebid, time: time, mac: mac)
        processRequest(url: ServerConstant.Url.status, method: .post, body: body) { result in
            switch result {
            case let .success(data):
                do {
                    let response: RBServerStatusResponse = try JSONDecoder().decode(RBServerStatusResponse.self, from: data)
                    let epochs: [RBEpoch] = response.idsForEpochs.map {
                        RBEpoch(id: $0.epochId, ebid: $0.key.ebid, ecc: $0.key.ecc)
                    }
                    let transformedResponse: RBStatusResponse = RBStatusResponse(atRisk: response.atRisk,
                                                                                 lastExposureTimeFrame: response.lastExposureTimeframe,
                                                                                 epochs: epochs)
                    completion(.success(transformedResponse))
                } catch {
                    completion(.failure(error))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    func report(code: String, helloMessages: [RBLocalProximity], completion: @escaping (_ error: Error?) -> ()) {
        let contacts: [RBServerContact] = prepareContactsReport(from: helloMessages)
        let body: RBServerReportBody = RBServerReportBody(code: code, contacts: contacts)
        processRequest(url: ServerConstant.Url.report, method: .post, body: body) { result in
            switch result {
            case let .success(data):
                do {
                    let response: RBServerStandardResponse = try JSONDecoder().decode(RBServerStandardResponse.self, from: data)
                    if response.success != false {
                        completion(nil)
                    } else {
                        completion(NSError.localizedError(message: response.message ?? "An unknown error occurred", code: 0))
                    }
                } catch {
                    completion(error)
                }
            case let .failure(error):
                completion(error)
            }
        }
    }
    
    func register(token: String, completion: @escaping (_ result: Result<RBRegisterResponse, Error>) -> ()) {
        let body: RBServerRegisterBody = RBServerRegisterBody(captcha: token)
        processRequest(url: ServerConstant.Url.register, method: .post, body: body) { result in
            switch result {
            case let .success(data):
                do {
                    let response: RBServerRegisterResponse = try JSONDecoder().decode(RBServerRegisterResponse.self, from: data)
                    let epochs: [RBEpoch] = response.idsForEpochs.map {
                        RBEpoch(id: $0.epochId, ebid: $0.key.ebid, ecc: $0.key.ecc)
                    }
                    
                    let rootJson: [String: Any] = (try? JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any] ?? [:]
                    let filteringAlgoConfig: [[String: Any]] = rootJson["filteringAlgoConfig"] as? [[String: Any]] ?? []
                    
                    let transformedResponse: RBRegisterResponse = RBRegisterResponse(key: response.key,
                                                                                     epochs: epochs,
                                                                                     timeStart: response.timeStart,
                                                                                     filteringAlgoConfig: filteringAlgoConfig)
                    completion(.success(transformedResponse))
                } catch {
                    completion(.failure(error))
                }
            case let .failure(error):
                completion(.failure(error))
            }
        }
    }
    
    func unregister(ebid: String, time: String, mac: String, completion: @escaping (_ error: Error?) -> ()) {
        let body: RBServerUnregisterBody = RBServerUnregisterBody(ebid: ebid, time: time, mac: mac)
        processRequest(url: ServerConstant.Url.unregister, method: .post, body: body) { result in
            switch result {
            case let .success(data):
                do {
                    let response: RBServerStandardResponse = try JSONDecoder().decode(RBServerStandardResponse.self, from: data)
                    if response.success != false {
                        completion(nil)
                    } else {
                        completion(NSError.localizedError(message: response.message ?? "An unknown error occurred", code: 0))
                    }
                } catch {
                    completion(error)
                }
            case let .failure(error):
                completion(error)
            }
        }
    }
    
    func deleteExposureHistory(ebid: String, time: String, mac: String, completion: @escaping (_ error: Error?) -> ()) {
        let body: RBServerDeleteExposureBody = RBServerDeleteExposureBody(ebid: ebid, time: time, mac: mac)
        processRequest(url: ServerConstant.Url.deleteExposureHistory, method: .post, body: body) { result in
            switch result {
            case let .success(data):
                do {
                    let response: RBServerStandardResponse = try JSONDecoder().decode(RBServerStandardResponse.self, from: data)
                    if response.success != false {
                        completion(nil)
                    } else {
                        completion(NSError.localizedError(message: response.message ?? "An unknown error occurred", code: 0))
                    }
                } catch {
                    completion(error)
                }
            case let .failure(error):
                completion(error)
            }
        }
    }
    
}

extension Server {
    
    private func prepareContactsReport(from helloMessages: [RBLocalProximity]) -> [RBServerContact] {
        var dict: [String: [RBLocalProximity]] = [:]
        helloMessages.forEach {
            var helloMessages: [RBLocalProximity] = dict[$0.ebid] ?? []
            helloMessages.append($0)
            dict[$0.ebid] = helloMessages
        }
        return dict.keys.compactMap {
            guard let helloMessages: [RBLocalProximity] = dict[$0] else { return nil }
            guard let ecc = helloMessages.first?.ecc else { return nil }
            let contactIds: [RBServerContactId] = helloMessages.map {
                RBServerContactId(timeCollectedOnDevice: $0.timeCollectedOnDevice,
                                  timeFromHelloMessage: $0.timeFromHelloMessage,
                                  mac: $0.mac,
                                  rssiRaw: $0.rssiRaw,
                                  rssiCalibrated: $0.rssiCalibrated)
            }
            return RBServerContact(ebid: $0, ecc: ecc, ids: contactIds)
        }
    }
    
}

extension Server {
    
    private func processRequest(url: URL, method: Method, body: RBServerBody, completion: @escaping (_ result: Result<Data, Error>) -> ()) {
        do {
            let bodyData: Data = try body.toData()
            let requestId: String = UUID().uuidString
            completions[requestId] = completion
            var request: URLRequest = URLRequest(url: url)
            request.httpMethod = method.rawValue
            request.setValue("application/json", forHTTPHeaderField: "Content-type")
            request.httpBody = bodyData
            let task: URLSessionDataTask = session.dataTask(with: request)
            task.taskDescription = requestId
            task.resume()
        } catch {
            completion(.failure(error))
        }
    }
    
}

extension Server: URLSessionDelegate, URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        let requestId: String = dataTask.taskDescription ?? ""
        guard let completion = completions[requestId] else { return }
        DispatchQueue.main.async {
            if let statusCode = (dataTask.response as? HTTPURLResponse)?.statusCode, "\(statusCode)".first != "2" {
                let message: String? = data.isEmpty ? "No logs received from the server" : String(data: data, encoding: .utf8)
                completion(.failure(NSError.localizedError(message: "Uknown error (\(statusCode)). (\(message ?? "N/A"))", code: statusCode)))
                self.completions[dataTask.taskDescription ?? ""] = nil
            } else {
                var receivedData: Data = self.receivedData[requestId] ?? Data()
                receivedData.append(data)
                self.receivedData[requestId] = receivedData
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let requestId: String = task.taskDescription ?? ""
        guard let completion = completions[requestId] else { return }
        DispatchQueue.main.async {
            if let error = error {
                completion(.failure(error))
            } else {
                let receivedData: Data = self.receivedData[requestId] ?? Data()
                completion(.success(receivedData))
            }
            self.completions[task.taskDescription ?? ""] = nil
        }
    }
    
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        Certificate.certificate.validateChallenge(challenge) { validated, credential in
            validated ? completionHandler(.useCredential, credential) : completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
}
