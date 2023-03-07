//
//  Copyright (c) Microsoft Corporation. All rights reserved.
//  Licensed under the MIT License.
//

import Foundation

class CallHistoryRepository {
    private let storageKey: String = "com.azure.ios.communication.ui.calling.CallHistory"
    private let logger: Logger
    private let userDefaults: UserDefaults

    init(logger: Logger, userDefaults: UserDefaults = .standard) {
        self.logger = logger
        self.userDefaults = userDefaults
    }

    func insert(callStartedOn: Date, callId: String) -> Error? {
        var historyRecords = self.getAllAsDictionary()
        if var existingCalls = historyRecords[callStartedOn] {
            existingCalls.append(callId)
            historyRecords[callStartedOn] = existingCalls
        } else {
            historyRecords[callStartedOn] = [callId]
        }
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(historyRecords)
            self.userDefaults.set(data, forKey: self.storageKey)
        } catch let error {
            self.logger.error("Failed to save call history, reason: \(error.localizedDescription)")
            return error
        }
        return nil
    }

    func getAll() -> [CallHistoryRecord] {
        return getAllAsDictionary()
            .map({ (callStartedOn, callIds) in
                return CallHistoryRecord(callStartedOn: callStartedOn, callIds: callIds)
            })
    }

    private func cleanupOldRecords(_ historyRecords: [Date: [String]]) -> [Date: [String]] {
        guard let thresholdDate = Calendar.current.date(byAdding: DateComponents(day: -31), to: Date()) else {
            return historyRecords
        }

        return historyRecords.filter { callHistoryRecord in
            callHistoryRecord.key >= thresholdDate
        }
    }

    private func getAllAsDictionary() -> [Date: [String]] {
        if let data = userDefaults.data(forKey: storageKey) {
            do {
                let decoder = JSONDecoder()
                return try cleanupOldRecords(decoder.decode([Date: [String]].self, from: data))
            } catch {
                return [:]
            }
        }
        return [:]
    }
}
