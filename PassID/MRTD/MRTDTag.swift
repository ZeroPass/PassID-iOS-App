//
//  MRTDTag.swift
// Modified copy of https://github.com/AndyQ/NFCPassportReader/blob/ccb7a7940df514b2c8e4973aa59ed8b8024ac739/Sources/NFCPassportReader/TagReader.swift

import Foundation
import CoreNFC


@available(iOS 13, *)
public enum MRTDTagError: Error {
    case ResponseError(String)
    case InvalidResponse
    case UnexpectedError
    case NFCNotSupported
    case NoConnectedTag
    case UnableToProtectAPDU
    case UnableToUnprotectAPDU
    case UnsupportedDataGroup
    case DataGroupNotRead
    case UnknownTag
    case UnknownImageFormat
    case NotImplemented

    var value: String {
        switch self {
        case .ResponseError(let errMsg): return errMsg
        case .InvalidResponse: return "InvalidResponse"
        case .UnexpectedError: return "UnexpectedError"
        case .NFCNotSupported: return "NFCNotSupported"
        case .NoConnectedTag: return "NoConnectedTag"
        case .UnableToProtectAPDU: return "UnableToProtectAPDU"
        case .UnableToUnprotectAPDU: return "UnableToUnprotectAPDU"
        case .UnsupportedDataGroup: return "UnsupportedDataGroup"
        case .DataGroupNotRead: return "DataGroupNotRead"
        case .UnknownTag: return "UnknownTag"
        case .UnknownImageFormat: return "UnknownImageFormat"
        case .NotImplemented: return "NotImplemented"
        }
    }
}



@available(iOS 13, *)
public class MRTDTag {
    var tag: NFCISO7816Tag
    var session: MRTDSession?
    var maxDataLengthToRead: UInt8 = 224

    var progress : ((Int)->())?

    init(tag: NFCISO7816Tag) {
        self.tag = tag
    }
    
    func reduceDataReadingAmount() {
         maxDataLengthToRead = 0xA0
    }

    func readLDSFile(tag: LDSFileTag, completed: @escaping ([UInt8]?, MRTDTagError?)->())  {
        readFileByFID(tag.fid(), completed: completed)
    }
    
    func getChallenge(completed: @escaping (ResponseAPDU?, MRTDTagError?)->()) {
        let cmd = NFCISO7816APDU(
            instructionClass: 00,
            instructionCode: 0x84,
            p1Parameter: 0,
            p2Parameter: 0,
            data: Data(),
            expectedResponseLength: 8
        )
        send(cmd: cmd, completed: completed)
    }
    
    func doInternalAuthentication(challenge: [UInt8], completed: @escaping (ResponseAPDU?, MRTDTagError?)->()) {
        let randNonce = Data(challenge)
        let cmd = NFCISO7816APDU(
            instructionClass: 00,
            instructionCode: 0x88,
            p1Parameter: 0,
            p2Parameter: 0,
            data: randNonce,
            expectedResponseLength: 256
        )
        send(cmd: cmd, completed: completed)
    }

    func doMutualAuthentication(cmdData: Data, completed: @escaping (ResponseAPDU?, MRTDTagError?)->()) {
        let cmd = NFCISO7816APDU(
            instructionClass: 00,
            instructionCode: 0x82,
            p1Parameter: 0,
            p2Parameter: 0,
            data: cmdData,
            expectedResponseLength: 40
        )
        send(cmd: cmd, completed: completed)
    }
    
    var header = [UInt8]()
    func readFileByFID(_ fid: FID, completed: @escaping ([UInt8]?, MRTDTagError?)->()) {
        selectFileByFID(fid) { [unowned self] (resp, err) in
            if let error = err {
                completed(nil, error)
                return
            }
            
            // Read first 4 bytes of header to see how big the data structure is
            let data: [UInt8] = [0x00, 0xB0, 0x00, 0x00, 0x00, 0x00,0x04]
            //print( "--------------------------------------\nSending \(binToHexRep(data))" )
            let cmd = NFCISO7816APDU(data: Data(data))!
            self.send(cmd: cmd) { [unowned self] (resp, err) in
                guard let response = resp else {
                    completed( nil, err)
                    return
                }
                
                // Header looks like:  <tag><length of data><nextTag> e.g.60145F01 -
                // the total length is the 2nd value plus the two header 2 bytes
                // We've read 4 bytes so we now need to read the remaining bytes from offset 4
                let (len, o) = try! TLV.decodeLength([UInt8](response.data[1..<4]))
                let leftToRead = Int(len)
                let offset = Int(o) + 1
                
                //print( "Got \(binToHexRep(response.data)) which is \(leftToRead) bytes with offset \(o)" )
                self.header = [UInt8](response.data[..<offset])//response.data

                Log.verbose("Amount of data to read - %d", leftToRead)
                self.readBinary(leftToRead: leftToRead, amountRead: offset, completed: completed)
            }
        }
    }
    
    func selectFileByFID(_ fid: FID, completed: @escaping (ResponseAPDU?, MRTDTagError?)->()) {
        let data : [UInt8] = [0x00, 0xA4, 0x02, 0x0C, 0x02] + fid
        let cmd = NFCISO7816APDU(data: Data(data))!
        send(cmd: cmd, completed: completed)
    }
    
    func readBinary(leftToRead: Int, amountRead: Int, completed: @escaping ([UInt8]?, MRTDTagError?)->()) {
        var readAmount: UInt8 = maxDataLengthToRead
        if leftToRead < maxDataLengthToRead {
            readAmount = UInt8(leftToRead)
        }
        
        self.progress?(Int(Float(amountRead) / Float(leftToRead + amountRead) * 100))
        let offset = intToBin(amountRead, pad: 4)

        let data: [UInt8] = [0x00, 0xB0, offset[0], offset[1], 0x00, 0x00, readAmount]
        //print( "Sending \(binToHexRep(data))" )
        
        let cmd = NFCISO7816APDU(data: Data(data))!
        self.send(cmd: cmd) { (resp, err) in
            guard let response = resp else {
                completed(nil, err)
                return
            }
            
            Log.debug("got resp - %@", "\(response)")
            self.header += response.data
            
            let remaining = leftToRead - response.data.count
        //print( "      read \(response.data.count) bytes" )
            Log.verbose("Amount of data left read - %d bytes", remaining)
            if remaining > 0 {
                self.readBinary(leftToRead: remaining, amountRead: amountRead + response.data.count, completed: completed)
            } else {
                completed(self.header, err)
            }
        }
    }

    func send(cmd: NFCISO7816APDU, completed: @escaping (ResponseAPDU?, MRTDTagError?)->()) {
        var toSend = cmd
        if let sm = session {
            do {
                toSend = try sm.protect(apdu: cmd)
            } catch {
                completed( nil, MRTDTagError.UnableToProtectAPDU )
            }
            Log.debug("[SM] %@", "\(toSend)")
        }

        tag.sendCommand(apdu: toSend) { [unowned self] (data, sw1, sw2, error) in
            if let error = error {
                Log.error("Error reading tag - %@", error.localizedDescription)
                completed( nil, MRTDTagError.ResponseError(error.localizedDescription) )
            }
            else {
                var rep = ResponseAPDU(data: [UInt8](data), sw1: sw1, sw2: sw2)
                if let sm = self.session {
                    do {
                        rep = try sm.unprotect(rapdu: rep)
//                        Log.debug(String(format:"[SM] \(rep.data), sw1:0x%02x sw2:0x%02x", rep.sw1, rep.sw2) )
                    } catch {
                        completed(nil, MRTDTagError.UnableToUnprotectAPDU)
                        return
                    }
                }
                
                if rep.sw1 == 0x90 && rep.sw2 == 0x00 {
                    completed(rep, nil)
                }
                else {
                    let errorMsg = self.decodeError(sw1: rep.sw1, sw2: rep.sw2)
                    Log.error("Error reading tag: sw1 - %X, sw2 - %X - reason: %@", sw1, sw2, errorMsg )
                    completed(nil, MRTDTagError.ResponseError(errorMsg))
                }
            }
        }
    }
    
    private func decodeError(sw1: UInt8, sw2: UInt8) -> String {
        let errors : [UInt8 : [UInt8:String]] = [
            0x62: [0x00:"No information given",
                   0x81:"Part of returned data may be corrupted",
                   0x82:"End of file/record reached before reading Le bytes",
                   0x83:"Selected file invalidated",
                   0x84:"FCI not formatted according to ISO7816-4 section 5.1.5"],
            
            0x63: [0x00:"No information given",
                   0x81:"File filled up by the last write",
                   0x82:"Card Key not supported",
                   0x83:"Reader Key not supported",
                   0x84:"Plain transmission not supported",
                   0x85:"Secured Transmission not supported",
                   0x86:"Volatile memory not available",
                   0x87:"Non Volatile memory not available",
                   0x88:"Key number not valid",
                   0x89:"Key length is not correct",
                   0xC:"Counter provided by X (valued from 0 to 15) (exact meaning depending on the command)"],
            0x65: [0x00:"No information given",
                   0x81:"Memory failure"],
            0x67: [0x00:"Wrong length"],
            0x68: [0x00:"No information given",
                   0x81:"Logical channel not supported",
                   0x82:"Secure messaging not supported"],
            0x69: [0x00:"No information given",
                   0x81:"Command incompatible with file structure",
                   0x82:"Security status not satisfied",
                   0x83:"Authentication method blocked",
                   0x84:"Referenced data invalidated",
                   0x85:"Conditions of use not satisfied",
                   0x86:"Command not allowed (no current EF)",
                   0x87:"Expected SM data objects missing",
                   0x88:"SM data objects incorrect"],
            0x6A: [0x00:"No information given",
                   0x80:"Incorrect parameters in the data field",
                   0x81:"Function not supported",
                   0x82:"File not found",
                   0x83:"Record not found",
                   0x84:"Not enough memory space in the file",
                   0x85:"Lc inconsistent with TLV structure",
                   0x86:"Incorrect parameters P1-P2",
                   0x87:"Lc inconsistent with P1-P2",
                   0x88:"Referenced data not found"],
            0x6B: [0x00:"Wrong parameter(s) P1-P2]"],
            0x6D: [0x00:"Instruction code not supported or invalid"],
            0x6E: [0x00:"Class not supported"],
            0x6F: [0x00:"No precise diagnosis"],
            0x90: [0x00:"Success"] //No further qualification
        ]
        
        // Special cases - where sw2 isn't an error but contains a value
        if sw1 == 0x61 {
            return "SW2 indicates the number of response bytes still available - (\(sw2) bytes still available)"
        }
        else if sw1 == 0x64 {
            return "State of non-volatile memory unchanged (SW2=00, other values are RFU)"
        }
        else if sw1 == 0x6C {
            return "Wrong length Le: SW2 indicates the exact length - (exact length :\(sw2))"
        }

        if let dict = errors[sw1], let errorMsg = dict[sw2] {
            return errorMsg
        }
        
        return "Unknown error - sw1: \(sw1), sw2: \(sw2)"
    }
}
