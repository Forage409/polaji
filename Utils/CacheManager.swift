import Foundation
 
enum CacheManager {
    static func computeCacheSize() -> Int64 {
        var total: Int64 = 0
        let manager = FileManager.default
        let candidateDirs: [URL] = {
            var urls: [URL] = []
            urls.append(contentsOf: manager.urls(for: .cachesDirectory, in: .userDomainMask))
            let tmp = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            urls.append(tmp)
            return urls
        }()
        
        for dir in candidateDirs {
            total += directorySize(at: dir)
        }
        return total
    }
    
    static func clearCache() {
        let manager = FileManager.default
        var dirs: [URL] = []
        dirs.append(contentsOf: manager.urls(for: .cachesDirectory, in: .userDomainMask))
        dirs.append(URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true))
        
        for dir in dirs {
            guard let contents = try? manager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else { continue }
            for url in contents {
                try? manager.removeItem(at: url)
            }
        }
    }
    
    static func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
    
    private static func directorySize(at url: URL) -> Int64 {
        let manager = FileManager.default
        guard let enumerator = manager.enumerator(at: url, includingPropertiesForKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey]) else {
            return 0
        }
        var size: Int64 = 0
        for case let fileURL as URL in enumerator {
            let values = try? fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey])
            if let total = values?.totalFileAllocatedSize {
                size += Int64(total)
            } else if let alloc = values?.fileAllocatedSize {
                size += Int64(alloc)
            }
        }
        return size
    }
}
