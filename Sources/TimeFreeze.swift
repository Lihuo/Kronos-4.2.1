import Foundation


private var kUptimeKey = "Uptime"
private var kTimestampKey = "Timestamp"
private var kOffsetKey = "Offset"

///Origin code
/*
private let kUptimeKey = "Uptime"
private let kTimestampKey = "Timestamp"
private let kOffsetKey = "Offset"
*/

public struct TimeFreeze {
    
    private var uptime: TimeInterval
    private var timestamp: TimeInterval
    private var offset: TimeInterval
    
    ///Original code
    /*
     private let uptime: TimeInterval
     private let timestamp: TimeInterval
     private let offset: TimeInterval
     */
    
    /// The stable timestamp adjusted by the most accurate offset known so far.
    var adjustedTimestamp: TimeInterval {
        return self.offset + self.stableTimestamp
    }

    /// The stable timestamp (calculated based on the uptime); note that this doesn't have sub-seconds
    /// precision. See `systemUptime()` for more information.
    var stableTimestamp: TimeInterval {
        return (TimeFreeze.systemUptime() - self.uptime) + self.timestamp
    }

    /// Time interval between now and the time the NTP response represented by this TimeFreeze was received.
    var timeSinceLastNtpSync: TimeInterval {
        return TimeFreeze.systemUptime() - uptime
    }

    init(offset: TimeInterval) {
        self.offset = offset
        self.timestamp = currentTime()
        self.uptime = TimeFreeze.systemUptime()
    }

    init?(from dictionary: [String: TimeInterval]) {
        guard let dictUptime = dictionary[kUptimeKey], let dictTimestamp = dictionary[kTimestampKey], let dictOffset = dictionary[kOffsetKey] else {
            return nil
        }
        
        let currentUptime = TimeFreeze.systemUptime()
        //let currentTimestamp = currentTime()
        //let currentBoot = currentUptime - currentTimestamp
        //let previousBoot = uptime - timestamp
        
//        let result = rint(currentUptime) - rint(dictUptime)
//        let result2 = rint(currentTimestamp) + (rint(currentUptime) - rint(dictUptime))
//        print(" \(result) = \(rint(dictUptime)) + (\(rint(currentUptime)) - \(rint(dictUptime)))")
//        print(" \(result2) = \(rint(currentTimestamp)) + (\(rint(currentUptime)) - \(rint(dictUptime)))")
        
        if currentUptime - dictUptime < 0 {
            UserDefaults.standard.setValue(nil, forKey: "KronosStableTime")
            return nil
            
        } else {
            self.uptime = dictUptime + (currentUptime - dictUptime)
            self.timestamp = dictTimestamp + (currentUptime - dictUptime)
            self.offset = dictOffset
            
            let newDict: [String: TimeInterval] = [
                kUptimeKey: self.uptime,
                kTimestampKey: self.timestamp,
                kOffsetKey: offset,
            ]
            UserDefaults.standard.setValue(newDict, forKey: "KronosStableTime")
        }
        
        ///Original code
        /*
        guard let uptime = dictionary[kUptimeKey], let timestamp = dictionary[kTimestampKey], let offset = dictionary[kOffsetKey] else { return nil }
        let currentUptime = TimeFreeze.systemUptime()
        let currentTimestamp = currentTime()

        let currentBoot = currentUptime - currentTimestamp
        let previousBoot = uptime - timestamp

        self.uptime = uptime
        self.timestamp = timestamp
        self.offset = offset

        if rint(currentBoot) - rint(previousBoot) != 0 {
            return nil
        }
        */
    }

    /// Convert this TimeFreeze to a dictionary representation.
    ///
    /// - returns: A dictionary representation.
    func toDictionary() -> [String: TimeInterval] {
        return [
            kUptimeKey: self.uptime,
            kTimestampKey: self.timestamp,
            kOffsetKey: self.offset,
        ]
    }

    /// Returns a high-resolution measurement of system uptime, that continues ticking through device sleep
    /// *and* user- or system-generated clock adjustments. This allows for stable differences to be calculated
    /// between timestamps.
    ///
    /// Note: Due to an issue in BSD/darwin, sub-second precision will be lost;
    /// see: https://github.com/darwin-on-arm/xnu/blob/master/osfmk/kern/clock.c#L522.
    ///
    /// - returns: An Int measurement of system uptime in microseconds.
    static func systemUptime() -> TimeInterval {
        var mib = [CTL_KERN, KERN_BOOTTIME]
        var size = MemoryLayout<timeval>.stride
        var bootTime = timeval()

        let bootTimeError = sysctl(&mib, u_int(mib.count), &bootTime, &size, nil, 0) != 0
        assert(!bootTimeError, "system clock error: kernel boot time unavailable")

        let now = currentTime()
        let uptime = Double(bootTime.tv_sec) + Double(bootTime.tv_usec) / 1_000_000
        assert(now >= uptime, "inconsistent clock state: system time precedes boot time")

        return now - uptime
    }
}
