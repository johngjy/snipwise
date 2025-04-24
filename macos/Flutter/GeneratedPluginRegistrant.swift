//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import desktop_window
import isar_flutter_libs
import path_provider_foundation
import screen_capturer_macos
import screen_retriever
import shared_preferences_foundation
import window_manager

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  DesktopWindowPlugin.register(with: registry.registrar(forPlugin: "DesktopWindowPlugin"))
  IsarFlutterLibsPlugin.register(with: registry.registrar(forPlugin: "IsarFlutterLibsPlugin"))
  PathProviderPlugin.register(with: registry.registrar(forPlugin: "PathProviderPlugin"))
  ScreenCapturerMacosPlugin.register(with: registry.registrar(forPlugin: "ScreenCapturerMacosPlugin"))
  ScreenRetrieverPlugin.register(with: registry.registrar(forPlugin: "ScreenRetrieverPlugin"))
  SharedPreferencesPlugin.register(with: registry.registrar(forPlugin: "SharedPreferencesPlugin"))
  WindowManagerPlugin.register(with: registry.registrar(forPlugin: "WindowManagerPlugin"))
}
