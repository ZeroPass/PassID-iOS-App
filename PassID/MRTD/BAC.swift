//
//  BAC.swift
// Modified copy of https://github.com/AndyQ/NFCPassportReader/blob/ccb7a7940df514b2c8e4973aa59ed8b8024ac739/Sources/NFCPassportReader/BACHandler.swift

import Foundation
import CoreNFC

@available(iOS 13, *)
public class BAC {
    let KENC : [UInt8] = [0,0,0,1]
    let KMAC : [UInt8] = [0,0,0,2]

    static let keyLen = 16
    static let macLen = 8

    static let rndIfdLen = 8
    static let rndIcLen  = rndIfdLen

    static let kifdLen = keyLen
    static let kicLen  = kifdLen

    
    var ksenc : [UInt8] = []
    var ksmac : [UInt8] = []

    var rnd_icc : [UInt8] = []
    var rnd_ifd : [UInt8] = []
    var kifd : [UInt8] = []
    
    var tag : MRTDTag
    
   /* public init() {
        // For testing only
    }*/
    
    public init(mrtdTag: MRTDTag) {
        self.tag = mrtdTag
    }

    public func initSession(mrzKey : MRZKey, completed: @escaping (_ error : MRTDTagError?)->()) {
        /*guard let tagReader = self.tag else {
            completed(MRTDTagError.NoConnectedTag)
            return
        }*/
        
        _ = self.deriveDocumentBasicAccessKeys(mrzKey: mrzKey)
        
        // Make sure we clear secure messaging (could happen if we read an invalid DG or we hit a secure error
        tag.session = nil
        
        // get Challenge
        tag.getChallenge() { [unowned self] (response, error) in
            
            guard let response = response else {
                Log.error("ERROR - %@", error?.localizedDescription ?? "")
                completed( error )
                return
            }
            
            Log.verbose( "DATA - %@", "\(response.data)")
            let cmd_data = self.authentication(rnd_icc: [UInt8](response.data))
            self.tag.doMutualAuthentication(cmdData: Data(cmd_data)) { [unowned self] (response, error) in
                guard let response = response else {
                    Log.error("ERROR - @", error?.localizedDescription ?? "")
                    completed(error)
                    return
                }
                
                Log.verbose("DATA - %@", "\(response.data)")
                let (KSenc, KSmac, ssc) = self.sessionKeys(data: [UInt8](response.data))
                self.tag.session = MRTDSession(ksenc: KSenc, ksmac: KSmac, ssc: ssc)
                completed(nil)
            }
        }
    }

    func deriveDocumentBasicAccessKeys(mrzKey: MRZKey) -> ([UInt8], [UInt8]) {
        //let kmrz  = getMRZInfo(mrz: mrz)
        //let kseed = generateInitialKseed(kmrz: kmrz)
        
        Log.verbose("Calculate Kseed")
        let kseed = mrzKey.bacKeySeed()
        Log.verbose("\tKseed: %@", kseed.hex())
    
        Log.verbose("Calculate the Basic Acces Keys (Kenc and Kmac) using Appendix 5.1")
        let (kenc, kmac) = computeKeysFromKseed(Kseed: kseed)
        self.ksenc = kenc
        self.ksmac = kmac
                
        return (kenc, kmac)
    }
    
    /// - Parameter mrz:
//    func getMRZInfo( mrz : String ) -> String {
//        let kmrz = mrz
//        //        kmrz = docNumber + docNumberChecksum + \
//        //            mrz.dateOfBirth + mrz.dateOfBirthCheckSum + \
//        //                mrz.dateOfExpiry + mrz.dateOfExpiryChecksum
//
//        return kmrz
//    }
    
    ///
    /// Calculate the kseed from the kmrz:
    /// - Calculate a SHA-1 hash of the kmrz
    /// - Take the most significant 16 bytes to form the Kseed.
    /// @param kmrz: The MRZ information
    /// @type kmrz: a string
    /// @return: a 16 bytes string
    ///
    /// - Parameter kmrz: <#kmrz description#>
    /// - Returns: first 16 bytes of the mrz SHA1 hash
    ///
//    func generateInitialKseed(kmrz : String ) -> [UInt8] {
//        Log.verbose("Calculate the SHA-1 hash of MRZ_information")
//        let hash = sha1([UInt8](kmrz.data(using:.utf8)!))
//        Log.verbose("\tHsha1(MRZ_information): %@", hash.hex())
//
//        let subHash = Array(hash[0..<16])
//        Log.verbose("Take the most significant 16 bytes to form the Kseed")
//        Log.verbose("\tKseed: %@", subHash.hex())
//
//        return Array(subHash)
//    }
    

    func computeKeysFromKseed(Kseed : [UInt8] ) -> ([UInt8], [UInt8]) {
        Log.verbose("Compute Encryption key (c: %@)", KENC.hex())
        let kenc = self.deriveKey(kseed: Kseed, c: KENC)
        
        Log.verbose("Compute MAC Computation key (c: %@)", KMAC.hex())
        let kmac = self.deriveKey(kseed: Kseed, c: KMAC)
        
        //        return (kenc, kmac)
        return (kenc, kmac)
    }
    
    /// Key derivation from the kseed:
    /// - Concatenate Kseed and c (c=0 for KENC or c=1 for KMAC)
    /// - Calculate the hash of the concatenation of kseed and c (h = (sha1(kseed + c)))
    /// - Adjust the parity bits
    /// - return the key (The first 8 bytes are Ka and the next 8 bytes are Kb)
    /// @param kseed: The Kseed
    /// @type kseed: a 16 bytes string
    /// @param c: specify if it derives KENC (c=0) of KMAC (c=1)
    /// @type c: a byte
    /// @return: Return a 16 bytes key
    func deriveKey( kseed : [UInt8], c: [UInt8] ) -> [UInt8] {
        //        if c not in (BAC.KENC,BAC.KMAC):
        //        raise BACException, "Bad parameter (c=0 or c=1)"
        
        Log.verbose("\tConcatenate Kseed and c")
        let d = kseed + c
        Log.verbose("\t\tD: @%", d.hex())
        
        Log.verbose("\tCalculate the SHA-1 hash of D")
        let h = sha1(d)
        //        h = sha1(str(d)).digest()
        Log.verbose("\t\tHsha1(D): %@", h.hex())
        
        Log.verbose("\tForm keys Ka and Kb")
        
        var Ka = Array(h[0..<8])
        Log.verbose("\t\tKa: %@", Ka.hex())
        
        var Kb = Array(h[8..<16])
        Log.verbose("\t\tKb: %@", Kb.hex())
        
        
        Log.verbose("\tAdjust parity bits")
        
        Ka = self.DESParity(Ka)
        Log.verbose("\t\tKa: %@", Ka.hex())
        
        Kb = self.DESParity(Kb)
        Log.verbose("\t\tKb: %@", Kb.hex())

        return Ka+Kb
    }
    
    func DESParity(_ data : [UInt8] ) -> [UInt8] {
        var adjusted = [UInt8]()
        for x in data {
            let y = x & 0xfe
            var parity :UInt8 = 0
            for z in 0 ..< 8 {
                parity += y >> z & 1
            }
            
            let s = y + (parity % 2 == 0 ? 1 : 0)
            adjusted.append(s) // chr(y + (not parity % 2))
        }
        return adjusted
    }

    
    /// Construct the command data for the mutual authentication.
    /// - Request an 8 byte random number from the MRTD's chip (rnd.icc)
    /// - Generate an 8 byte random (rnd.ifd) and a 16 byte random (kifd)
    /// - Concatenate rnd.ifd, rnd.icc and kifd (s = rnd.ifd + rnd.icc + kifd)
    /// - Encrypt it with TDES and the Kenc key (eifd = TDES(s, Kenc))
    /// - Compute the MAC over eifd with TDES and the Kmax key (mifd = mac(pad(eifd))
    /// - Construct the APDU data for the mutualAuthenticate command (cmd_data = eifd + mifd)
    ///
    /// @param rnd_icc: The challenge received from the ICC.
    /// @type rnd_icc: A 8 bytes binary string
    /// @return: The APDU binary data for the mutual authenticate command
    func authentication( rnd_icc : [UInt8]) -> [UInt8] {
        self.rnd_icc = rnd_icc
        
        Log.verbose("Request an 8 byte random number from the MRTD's chip")
        Log.verbose("\tRND.ICC: %@", self.rnd_icc.hex())
        
        self.rnd_icc = rnd_icc
        let kifd     = randomBytes(BAC.kifdLen)
        let rnd_ifd  = randomBytes(BAC.rndIfdLen)
        
        Log.verbose("Generate an 8 byte random and a 16 byte random")
        Log.verbose("\tRND.IFD: %@", rnd_ifd.hex())
        Log.verbose("\tRND.Kifd: %@", kifd.hex())
        
        let s = rnd_ifd + rnd_icc + kifd
        
        Log.verbose("Concatenate RND.IFD, RND.ICC and Kifd")
        Log.verbose("\tS: %@", s.hex())
        
        let iv : [UInt8] = [0, 0, 0, 0, 0, 0, 0, 0]
        let eifd = tripleDESEncrypt(key: ksenc,message: s, iv: iv)
        
        Log.verbose("Encrypt S with TDES key Kenc as calculated in Appendix 5.2")
        Log.verbose("\tEifd: %@", eifd.hex())
        
        let mifd = ISO9797Alg3.mac(key: ksmac, msg: pad(eifd))

        Log.verbose("Compute MAC over eifd with TDES key Kmac as calculated in-Appendix 5.2")
        Log.verbose("\tMifd: %@", mifd.hex())
        // Construct APDU
        
        let cmd_data = eifd + mifd
        Log.verbose("Construct command data for MUTUAL AUTHENTICATE")
        Log.verbose("\tcmd_data: %@", cmd_data.hex())
        
        self.kifd    = kifd
        self.rnd_ifd = rnd_ifd
        
        return cmd_data
    }
    
    /// Calculate the session keys (KSenc, KSmac) and the SSC from the data
    /// received by the mutual authenticate command.
    
    /// @param data: the data received from the mutual authenticate command send to the chip.
    /// @type data: a binary string
    /// @return: A set of two 16 bytes keys (KSenc, KSmac) and the SSC
    public func sessionKeys(data : [UInt8] ) -> ([UInt8], [UInt8], [UInt8]) {
        Log.verbose("Decrypt and verify received data and compare received RND.IFD with generated RND.IFD %@", self.ksmac.hex())
        
        let response = tripleDESDecrypt(key: self.ksenc, message: [UInt8](data[0..<32]), iv: [0,0,0,0,0,0,0,0] )

        Log.verbose("Calculate XOR of Kifd and Kicc")
        let response_kicc = [UInt8](response[16..<32])
        
        let Kseed = generateKeySeed(self.kifd, response_kicc)
        Log.verbose("\tKseed: %@", Kseed.hex())
        
        
        Log.verbose("Calculate Session Keys (KSenc and KSmac) using Appendix 5.1")
        
        let KSenc = self.deriveKey(kseed: Kseed,c: KENC)
        Log.verbose("\tKSenc: %@", KSenc.hex())
        
        let KSmac = self.deriveKey(kseed: Kseed,c: KMAC)
        Log.verbose("\tKSmac: %@", KSmac.hex())
        
        
        Log.verbose("Calculate Send Sequence Counter")
        let ssc = [UInt8](self.rnd_icc.suffix(4) + self.rnd_ifd.suffix(4))
        Log.verbose("\tSSC: %@", ssc.hex())
        
        return (KSenc, KSmac, ssc)
    }
    
    func generateKeySeed(_ kifd : [UInt8], _ response_kicc : [UInt8] ) -> [UInt8] {
        var kseed = [UInt8]()
        for i in 0 ..< kifd.count {
            kseed.append(kifd[i] ^ response_kicc[i])
        }
        return kseed
    }
}
