#if os(Linux)
    import Glibc
#else
    import Foundation
#endif

struct Logger {
    static func log(_ message: String) {
        print(message)
        // Don't buffer stdout - without it, logs don't appear in Docker (until later, presumably)
        fflush(stdout)
    }
}
