import Cocoa
import FlutterMacOS
import Security

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)
    AonwKeychainPlugin.register(with: flutterViewController)

    super.awakeFromNib()
  }
}

private enum AonwKeychainPlugin {
  private static let service = "com.aonw.aonwFlutter.auth"
  private static let maximumValueBytes = 16 * 1024

  static func register(with controller: FlutterViewController) {
    let channel = FlutterMethodChannel(
      name: "aonw/keychain",
      binaryMessenger: controller.engine.binaryMessenger)
    channel.setMethodCallHandler(handle)
  }

  private static func handle(
    _ call: FlutterMethodCall,
    result: @escaping FlutterResult
  ) {
    guard
      let arguments = call.arguments as? [String: Any],
      let key = arguments["key"] as? String,
      !key.isEmpty,
      key.utf8.count <= 256
    else {
      result(FlutterError(
        code: "invalid_keychain_request",
        message: "The Keychain request is invalid.",
        details: nil))
      return
    }

    switch call.method {
    case "read":
      read(key: key, result: result)
    case "write":
      guard
        let value = arguments["value"] as? String,
        !value.isEmpty,
        let data = value.data(using: .utf8),
        data.count <= maximumValueBytes
      else {
        result(FlutterError(
          code: "invalid_keychain_request",
          message: "The Keychain request is invalid.",
          details: nil))
        return
      }
      write(key: key, data: data, result: result)
    case "delete":
      delete(key: key, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func baseQuery(key: String) -> [CFString: Any] {
    return [
      kSecClass: kSecClassGenericPassword,
      kSecAttrService: service,
      kSecAttrAccount: key,
    ]
  }

  private static func read(key: String, result: @escaping FlutterResult) {
    var query = baseQuery(key: key)
    query[kSecMatchLimit] = kSecMatchLimitOne
    query[kSecReturnData] = true
    var item: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &item)
    if status == errSecItemNotFound {
      result(nil)
      return
    }
    guard
      status == errSecSuccess,
      let data = item as? Data,
      let value = String(data: data, encoding: .utf8)
    else {
      fail(status: status, result: result)
      return
    }
    result(value)
  }

  private static func write(
    key: String,
    data: Data,
    result: @escaping FlutterResult
  ) {
    let query = baseQuery(key: key)
    let updateStatus = SecItemUpdate(
      query as CFDictionary,
      [kSecValueData: data] as CFDictionary)
    if updateStatus == errSecSuccess {
      result(nil)
      return
    }
    if updateStatus != errSecItemNotFound {
      fail(status: updateStatus, result: result)
      return
    }
    var item = query
    item[kSecValueData] = data
    let addStatus = SecItemAdd(item as CFDictionary, nil)
    if addStatus == errSecSuccess {
      result(nil)
      return
    }
    fail(status: addStatus, result: result)
  }

  private static func delete(key: String, result: @escaping FlutterResult) {
    let status = SecItemDelete(baseQuery(key: key) as CFDictionary)
    if status == errSecSuccess || status == errSecItemNotFound {
      result(nil)
      return
    }
    fail(status: status, result: result)
  }

  private static func fail(status: OSStatus, result: @escaping FlutterResult) {
    result(FlutterError(
      code: "keychain_failure",
      message: "The private Keychain operation failed.",
      details: status))
  }
}
