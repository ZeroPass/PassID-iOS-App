//
// MRTDReader.swift
// Modified copy of https://github.com/AndyQ/NFCPassportReader/blob/master/Sources/NFCPassportReader/PassportReader.swift

import UIKit
import CoreNFC




@available(iOS 13, *)
public class MRTDReader: NSObject {
    
    //private var passport : NFCPassportModel = NFCPassportModel()
    private var readerSession: NFCTagReaderSession?
    private var progTitle = ""
    private var elementReadAttempts = 0

    private var filesToRead : [LDSFileTag] = []
    private var ldsFiles: [LDSFileTag : LDSFile] = [:]

    private var tag : MRTDTag?
    private var bacHandler : BAC?
    private var mrzKey : MRZKey!
    
    private var sessionEstablishedCallback: ((MRTDTagError?)->())!

    
    public func endSession(withError error: String? = nil) {
        self.readerSession?.alertMessage = ""
        if error != nil {
            self.readerSession?.invalidate(errorMessage: error!)
        }
        else {
            self.readerSession?.invalidate()
        }
    }
    
    public func startSession(mrzKey : MRZKey, completed: @escaping (MRTDTagError?)->()) {
        self.mrzKey = mrzKey
        sessionEstablishedCallback = completed
        
        guard NFCNDEFReaderSession.readingAvailable else {
            completed(MRTDTagError.NFCNotSupported)
            return
        }
        
        if NFCTagReaderSession.readingAvailable {
            readerSession = NFCTagReaderSession(pollingOption: [.iso14443], delegate: self, queue: nil)
            readerSession?.alertMessage = "Hold your iPhone near NFC enabled passport."
            readerSession?.begin()
        }
    }
    
    func internalAuthenticate(challenge: Data, completion: @escaping (ChallengeSigs?, MRTDTagError?)->()) {
        self.progTitle = "Signing challenge ..."
        self.readerSession?.alertMessage = "Signing challenge ..."
        updateReaderAlertProgress(progressPercentage: 0)
        if challenge.count % 8 != 0 {
            completion(nil, .InvalidChallengeLength)
            return
        }
        
        let cc = stride(from: 0, to: challenge.count, by: 8).map {
            Array(challenge[$0..<min($0 + 8, challenge.count)])
        }
        
        doAuthenticateChallenges(cc, ccSigs: ChallengeSigs(), completion: completion)
    }
    
    private func doAuthenticateChallenges(_ cc: [[UInt8]], ccSigs: ChallengeSigs, completion: @escaping (ChallengeSigs?, MRTDTagError?)->()) {
        let progress = Int(Double(ccSigs.sigs.count) / Double(ccSigs.sigs.count + cc.count) * 100)
        Log.verbose("signing progress: %d", progress)
        updateReaderAlertProgress(progressPercentage: progress)
        
        if cc.count == 0 {
            DispatchQueue.main.async {
                completion(ccSigs, nil)
            }
            return
        }
        
        var cc = cc
        let c = cc[0]
        cc.removeFirst()
        self.tag?.doInternalAuthentication(challenge: c) { [weak self] resp, error in
            if error != nil {
                self?.endSession(withError: error?.value)
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            var ccSigs = ccSigs
            ccSigs.append(Data(resp!.data))
            self?.doAuthenticateChallenges(cc, ccSigs: ccSigs, completion: completion)
        }
    }
    
    func readLDSFiles(tags: [LDSFileTag] = [], completion: @escaping ([LDSFileTag : LDSFile], MRTDTagError?)->()) {
        elementReadAttempts = 0
        self.filesToRead.removeAll()
        self.filesToRead.append(contentsOf: tags)

        // At this point, BAC Has been done and the TagReader has been set up with the SecureMessaging
        // session keys
        self.progTitle = "Reading passport files ...\n"
        self.readerSession?.alertMessage = "Reading passport files ...\n"

        self.readNextFile { [weak self] error in
            if let error = error {
                self?.readerSession?.invalidate(errorMessage: error.value)
                self!.ldsFiles.removeAll()
            }
            if self != nil {
                DispatchQueue.main.async {
                    completion(self!.ldsFiles, error)
                }
            }
        }

    }
}

@available(iOS 13, *)
extension MRTDReader : NFCTagReaderSessionDelegate {
    // MARK: - NFCTagReaderSessionDelegate
    public func tagReaderSessionDidBecomeActive(_ session: NFCTagReaderSession) {
        // If necessary, you may perform additional operations on session start.
        // At this point RF polling is enabled.
        Log.debug("tagReaderSessionDidBecomeActive")
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didInvalidateWithError error: Error) {
        // If necessary, you may handle the error. Note session is no longer valid.
        // You must create a new session to restart RF polling.
        Log.debug("tagReaderSession:didInvalidateWithError - %@", "\(error)")
        self.readerSession = nil
    }
    
    public func tagReaderSession(_ session: NFCTagReaderSession, didDetect tags: [NFCTag]) {
        Log.debug("tagReaderSession:didDetect - %@", "\(tags[0])")
        if tags.count > 1 {
            session.alertMessage = "More than 1 tags was found. Please present only 1 tag."
            return
        }
        
        let tag = tags.first!
        var mrtdTag: NFCISO7816Tag
        switch tags.first! {
            case let .iso7816(tag):
                mrtdTag = tag
            default:
                session.invalidate(errorMessage: "Tag not valid.")
                return
        }
        
        // Connect to tag
        session.connect(to: tag) { [unowned self] (error: Error?) in
            if error != nil {
                session.invalidate(errorMessage: "Connection error. Please try again.")
                return
            }
            
            self.readerSession?.alertMessage = "Authenticating with passport.....\n"

            self.tag = MRTDTag(tag: mrtdTag)
            self.tag!.progress = { [unowned self] (progress) in
                self.updateReaderAlertProgress(progressPercentage: progress)
            }

            self.establishMRTDSession()
        }
    }
    
    private func updateReaderAlertProgress(progressPercentage progress: Int) {
        let p = (progress/20)
        let full = String(repeating: "🔵 ", count: p)
        let empty = String(repeating: "⚪️ ", count: 5 - p)
        self.readerSession?.alertMessage = "\(self.progTitle)\n\(full)\(empty)"
    }
}

@available(iOS 13, *)
extension MRTDReader {
    
    private func establishMRTDSession() {
        // TODO: try establish session via PACE first
        doBAC { [weak self] error in
            if error == nil {
                Log.debug("session established via BAC")
            }
            else {
                Log.error("Failed to establish session via BAC")
                self?.readerSession?.invalidate(errorMessage: "There was a problem reading the passport. Please try again" )
            }
            DispatchQueue.main.async {
                self?.sessionEstablishedCallback(error)
            }
        }
    }
    

    
//    func doActiveAuthenticationIfNeccessary( completed: @escaping ()->() ) {
//        guard self.passport.activeAuthenticationSupported else {
//            completed()
//            return
//        }
//
//        Log.info( "Performing Active Authentication" )
//
//        let challenge = generateRandomUInt8Array(8)
//        self.tagReader?.doInternalAuthentication(challenge: challenge, completed: { (response, err) in
//            if let response = response {
//                self.passport.verifyActiveAuthentication( challenge:challenge, signature:response.data )
//            }
//
//            completed()
//        })
//
//    }
    
    private func doBAC(completed: @escaping (MRTDTagError?)->()) {
        guard let tag = self.tag else {
            completed(MRTDTagError.NoConnectedTag)
            return
        }
        
        Log.debug("Starting Basic Access Control (BAC)")

        self.bacHandler = BAC(mrtdTag: tag)
        bacHandler?.initSession(mrzKey: mrzKey) { error in
            self.bacHandler = nil
            completed(error)
        }
    }
    
    func readNextFile( completedReadingFiles completed: @escaping (MRTDTagError?)->() ) {
        guard let tagReader = self.tag else { completed(MRTDTagError.NoConnectedTag ); return }
        if filesToRead.count == 0 {
            completed(nil)
            return
        }

        let tag = filesToRead[0]
        Log.debug("Reading tag - %@", "\(tag)" )
        elementReadAttempts += 1

        tagReader.readLDSFile(tag:tag) { [unowned self] (resp, err) in
            self.updateReaderAlertProgress(progressPercentage: 100 )
            if let resp = resp {
                do {
                    //let dg = try DataGroupParser().parseDG(data: response)
                    self.ldsFiles[tag] =  try LDSFile(encodedTLV: resp)

                    /*if let com = dg as? efCOM {
                        let foundDGs = [.COM, .SOD] + com.dataGroupsPresent.map { LDSFileTag.fromName(name:$0) }
                        if self.readAllDatagroups == true {
                            self.dataGroupsToRead = foundDGs
                        }
                        else {
                            // We are reading specific datagroups but remove all the ones we've requested to be read that aren't actually available
                            self.dataGroupsToRead = self.dataGroupsToRead.filter { foundDGs.contains($0) }
                        }
                    }*/

                }
                catch let error as MRTDTagError {
                    Log.error("MRTDTagError reading tag - %@", "\(error)")
                    completed(error)
                    return
                }
                catch let error as TLVError {
                    Log.error("MRTDTagError failed to parse LDS file tag - %@", "\(error)")
                    completed(.ResponseError(error.value))
                    return
                }
                catch let error {
                    Log.error("Unexpected error reading tag - %@", "\(error)")
                    completed(.ResponseError("\(error)"))
                    return
                }

                // Remove it and read the next tag
                self.filesToRead.removeFirst()
                self.elementReadAttempts = 0
                self.readNextFile(completedReadingFiles: completed)
            }
            else {

                // OK we had an error - depending on what happened, we may want to try to re-read this
                // E.g. we failed to read the last Datagroup because its protected and we can't
                let errMsg = err?.value ?? "Unknown  error"
                print( "ERROR - \(errMsg)" )
                if errMsg == "Session invalidated" || errMsg == "Class not supported" || errMsg == "Tag connection lost"  {
                    // Can't go any more!
                    self.filesToRead.removeAll()
                    completed(err)
                }
                else if errMsg == "Security status not satisfied" || errMsg == "File not found" {
                    // Can't read this element as we aren't allowed - remove it and return out so we re-do BAC
                    self.filesToRead.removeFirst()
                    completed(nil)
                }
                else if errMsg == "SM data objects incorrect" {
                    // Can't read this element security objects now invalid - and return out so we re-do BAC
                    completed(nil)
                }
                else if errMsg.hasPrefix("Wrong length") {  // Should now handle errors 0x6C xx, and 0x67 0x00
                    // OK passport can't handle max length so drop it down
                    self.tag?.reduceDataReadingAmount()
                    completed(nil)
                }
                else {
                    // Retry
                    if self.elementReadAttempts > 3 {
                        self.filesToRead.removeFirst()
                        self.elementReadAttempts = 0
                    }
                    self.readNextFile(completedReadingFiles: completed)
                }
            }
        }
    }
}
