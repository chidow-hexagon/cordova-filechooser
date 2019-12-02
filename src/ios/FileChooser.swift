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

		let accept = command.arguments.first as! String
		let mimeTypes = accept.components(separatedBy: ",")

		let utis = mimeTypes.map { (mimeType: String) -> String in
			switch mimeType {
				case "audio/*":
					return kUTTypeAudio as String
				case "font/*":
					return "public.font"
				case "image/*":
					return kUTTypeImage as String
				case "text/*":
					return kUTTypeText as String
				case "video/*":
					return kUTTypeVideo as String
				default:
					break
			}

			if mimeType.range(of: "*") == nil {
				let utiUnmanaged = UTTypeCreatePreferredIdentifierForTag(
					kUTTagClassMIMEType,
					mimeType as CFString,
					nil
				)

				if let uti = (utiUnmanaged?.takeRetainedValue() as? String) {
					if !uti.hasPrefix("dyn.") {
						return uti
					}
				}
			}

			return kUTTypeData as String
		}

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
		self.send("RESULT_CANCELED")
	}
}
