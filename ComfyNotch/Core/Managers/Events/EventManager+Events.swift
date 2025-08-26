//
//  EventManager+Events.swift
//  ComfyNotch
//
//  Created by Aryan Rogye on 7/30/25.
//

import Foundation
import EventKit

extension EventManager {
    public func createEvent(
        title: String, 
        startDate: Date,
        endDate: Date,
        calendarName: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        /// Find Matching Calendar Event
        guard let calendar = self.store
            .calendars(for: .event)
            .first(where: { $0.title == calendarName && !$0.isImmutable }) else {
            completion(.failure(NSError(domain: "EventManager", code: 1001, userInfo: [NSLocalizedDescriptionKey : "Calendar not found or is read-only: \(calendarName)"])))
            return
        }
        
        /// Create Event
        let event = EKEvent(eventStore: self.store)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.calendar = calendar
        
        /// Save Event
        do {
            try self.store.save(event, span: .thisEvent)
            completion(.success(()))
        } catch {
            completion(.failure(error))
        }
    }
}
