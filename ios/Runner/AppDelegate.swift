import Flutter
import UIKit
import Security
import LocalAuthentication

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var deviceChannel: FlutterMethodChannel?
  private var signing = false
  private let keyTag = Data("zoom_monitor_biometric_v2".utf8)
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "DeviceBiometricsV2") else { return }
    deviceChannel = FlutterMethodChannel(name: "zoom_monitor/device_biometrics_v2", binaryMessenger: registrar.messenger())
    deviceChannel?.setMethodCallHandler { [weak self] call, reply in
      guard let self = self else { return }
      if self.signing { reply(FlutterError(code: "BUSY", message: "Verifikasi sedang berlangsung", details: nil)); return }
      self.signing = true
      DispatchQueue.global(qos: .userInitiated).async {
        let value: Any?
        do { value = try self.handleDeviceKey(call) }
        catch { value = FlutterError(code: "BIOMETRIC_UNAVAILABLE", message: "Biometrik dibatalkan atau tidak tersedia. Gunakan password atau daftarkan ulang perangkat.", details: nil) }
        DispatchQueue.main.async { self.signing = false; reply(value) }
      }
    }
  }

  private func query() -> [String: Any] {
    return [kSecClass as String: kSecClassKey, kSecAttrApplicationTag as String: keyTag, kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom]
  }

  private func handleDeviceKey(_ call: FlutterMethodCall) throws -> Any? {
    let failure = NSError(domain: "DeviceBiometricsV2", code: 1)
    switch call.method {
    case "hasKey":
      var lookup = query()
      lookup[kSecUseAuthenticationUI as String] = kSecUseAuthenticationUIFail
      let status = SecItemCopyMatching(lookup as CFDictionary, nil)
      return status == errSecSuccess || status == errSecInteractionNotAllowed
    case "deleteKey":
      SecItemDelete(query() as CFDictionary)
      return nil
    case "createKey":
      let context = LAContext()
      guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil) else { throw failure }
      SecItemDelete(query() as CFDictionary)
      var error: Unmanaged<CFError>?
      guard let access = SecAccessControlCreateWithFlags(nil, kSecAttrAccessibleWhenUnlockedThisDeviceOnly, [.privateKeyUsage, .biometryCurrentSet], &error) else { throw failure }
      let attrs: [String: Any] = [
        kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
        kSecAttrKeySizeInBits as String: 256,
        kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
        kSecPrivateKeyAttrs as String: [kSecAttrIsPermanent as String: true, kSecAttrApplicationTag as String: keyTag, kSecAttrAccessControl as String: access]
      ]
      guard let key = SecKeyCreateRandomKey(attrs as CFDictionary, &error),
            let pub = SecKeyCopyPublicKey(key),
            let raw = SecKeyCopyExternalRepresentation(pub, &error) as Data?, raw.count == 65 else { throw failure }
      // SPKI algorithm identifier for id-ecPublicKey + prime256v1; the key is X9.63 uncompressed.
      var spki = Data([0x30,0x59,0x30,0x13,0x06,0x07,0x2a,0x86,0x48,0xce,0x3d,0x02,0x01,0x06,0x08,0x2a,0x86,0x48,0xce,0x3d,0x03,0x01,0x07,0x03,0x42,0x00])
      spki.append(raw)
      return spki.base64EncodedString()
    case "sign":
      guard let args = call.arguments as? [String: Any], let challenge = args["challenge"] as? String, !challenge.isEmpty, challenge.utf8.count <= 1024 else { throw failure }
      let context = LAContext()
      context.localizedReason = "Verifikasi untuk masuk ke Zoom Monitor"
      context.localizedFallbackTitle = ""
      var lookup = query()
      lookup[kSecReturnRef as String] = true
      lookup[kSecUseAuthenticationContext as String] = context
      var item: CFTypeRef?
      guard SecItemCopyMatching(lookup as CFDictionary, &item) == errSecSuccess, let item = item else { throw failure }
      let key = item as! SecKey
      var error: Unmanaged<CFError>?
      guard let signature = SecKeyCreateSignature(key, .ecdsaSignatureMessageX962SHA256, Data(challenge.utf8) as CFData, &error) as Data? else { throw failure }
      return signature.base64EncodedString()
    default: return FlutterMethodNotImplemented
    }
  }
}
