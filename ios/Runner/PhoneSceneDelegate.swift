import Flutter
import UIKit

class PhoneSceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    registerSceneLifeCycle(with: AppDelegate.engine)
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    guard let windowScene = scene as? UIWindowScene else { return }
    let controller = FlutterViewController(
      engine: AppDelegate.engine,
      nibName: nil,
      bundle: nil
    )
    let window = UIWindow(windowScene: windowScene)
    window.rootViewController = controller
    self.window = window
    window.makeKeyAndVisible()
  }
}
