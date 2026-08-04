import Foundation

#if DEBUG
  public enum EnvUtils {
    private static var isSimulator: Bool {
      ProcessInfo.processInfo.environment["SIMULATOR_DEVICE_NAME"] != nil
    }

    private static var macIPAddress: String {
      Bundle.main.object(forInfoDictionaryKey: "MacIPAddress") as? String ?? ""
    }

    public static var isEmulator: Bool {
      isSimulator || !macIPAddress.isEmpty
    }

    public static var emulatorHost: String {
      if isSimulator { return "localhost" }
      assert(!macIPAddress.isEmpty, "MAC_IP_ADDRESS must be set in xcconfig")
      return macIPAddress
    }
  }
#endif
