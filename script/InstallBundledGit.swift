import Darwin
import Foundation

let source = CommandLine.arguments[1]
let destination = CommandLine.arguments[2]
let flags =
	FileManager.default.fileExists(atPath: destination) ? UInt32(RENAME_SWAP) : UInt32(RENAME_EXCL)

guard renamex_np(source, destination, flags) == 0 else {
	perror("Install bundled Git")
	exit(EXIT_FAILURE)
}
