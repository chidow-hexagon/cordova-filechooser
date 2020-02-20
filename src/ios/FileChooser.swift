import UIKit
import MobileCoreServices
import Foundation


@objc(FileChooser)
class FileChooser : CDVPlugin {
	var commandCallback: String?

	func callPicker (utis: [String]) {
		let picker = UIDocumentPickerViewController(documentTypes: utis, in: .import)
		picker.delegate = self
		self.viewController.present(picker, animated: true, completion: nil)
	}

	func documentWasSelected (url: URL) {
		self.send(url.absoluteString)
		url.stopAccessingSecurityScopedResource()
	}

	@objc(open:)
	func open (command: CDVInvokedUrlCommand) {
		self.commandCallback = command.callbackId

		let utis = [kUTTypeData as String]

		self.callPicker(utis: utis)
	}

	func send (_ message: String, _ status: CDVCommandStatus = CDVCommandStatus_OK) {
		if let callbackId = self.commandCallback {
			self.commandCallback = nil

			let pluginResult = CDVPluginResult(
				status: status,
				messageAs: message
			)

			self.commandDelegate!.send(
				pluginResult,
				callbackId: callbackId
			)
		}
	}

	func sendError (_ message: String) {
		self.send(message, CDVCommandStatus_ERROR)
	}
}

extension FileChooser : UIDocumentPickerDelegate {
	@available(iOS 11.0, *)
	func documentPicker (
		_ controller: UIDocumentPickerViewController,
		didPickDocumentsAt urls: [URL]
	) {
		if let url = urls.first {
			self.documentWasSelected(url: url)
		}
	}

	func documentPicker (
		_ controller: UIDocumentPickerViewController,
		didPickDocumentAt url: URL
	) {
		self.documentWasSelected(url: url)
	}

	func documentPickerWasCancelled (_ controller: UIDocumentPickerViewController) {
		self.sendError("RESULT_CANCELED")
	}
}
