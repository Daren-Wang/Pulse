// The MIT License (MIT)
//
// Copyright (c) 2020–2023 Alexander Grebenyuk (github.com/kean).

import SwiftUI
import Pulse

#warning("TODO: remove unused")
#warning("TODO: remoe actions for KeyValueSectionViewModel")
#warning("TODO: standardize lineHeight")

extension KeyValueSectionViewModel {
    static func makeParameters(for request: NetworkRequestEntity) -> KeyValueSectionViewModel {
        var items: [(String, String?)] = [
            ("Cache Policy", request.cachePolicy.description),
            ("Timeout Interval", DurationFormatter.string(from: TimeInterval(request.timeoutInterval), isPrecise: false))
        ]
        // Display only non-default values
        if !request.allowsCellularAccess {
            items.append(("Allows Cellular Access", request.allowsCellularAccess.description))
        }
        if !request.allowsExpensiveNetworkAccess {
            items.append(("Allows Expensive Network Access", request.allowsExpensiveNetworkAccess.description))
        }
        if !request.allowsConstrainedNetworkAccess {
            items.append(("Allows Constrained Network Access", request.allowsConstrainedNetworkAccess.description))
        }
        if !request.httpShouldHandleCookies {
            items.append(("Should Handle Cookies", request.httpShouldHandleCookies.description))
        }
        if request.httpShouldUsePipelining {
            items.append(("HTTP Should Use Pipelining", request.httpShouldUsePipelining.description))
        }
        return KeyValueSectionViewModel(title: "Options", color: .indigo, items: items)
    }

    static func makeComponents(for url: URL) -> KeyValueSectionViewModel? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }
        return KeyValueSectionViewModel(
            title: "URL Components",
            color: .blue,
            items: [
                ("Scheme", components.scheme),
                ("Port", components.port?.description),
                ("User", components.user),
                ("Password", components.password),
                ("Host", components.host),
                ("Path", components.path),
                ("Query", components.query),
                ("Fragment", components.fragment)
            ].filter { $0.1?.isEmpty == false })
    }

    static func makeHeaders(title: String, headers: [String: String]?) -> KeyValueSectionViewModel {
        KeyValueSectionViewModel(
            title: title,
            color: .red,
            items: (headers ?? [:]).sorted { $0.key < $1.key }
        )
    }

    static func makeErrorDetails(for task: NetworkTaskEntity) -> KeyValueSectionViewModel? {
        guard task.errorCode != 0, task.state == .failure else {
            return nil
        }
        return KeyValueSectionViewModel(
            title: "Error",
            color: .red,
            items: [
                ("Domain", task.errorDomain),
                ("Code", descriptionForError(domain: task.errorDomain, code: task.errorCode)),
                ("Description", task.errorDebugDescription)
            ])
    }

    private static func descriptionForError(domain: String?, code: Int32) -> String {
        guard domain == NSURLErrorDomain else {
            return "\(code)"
        }
        return "\(code) (\(descriptionForURLErrorCode(Int(code)))"
    }

    static func makeQueryItems(for url: URL) -> KeyValueSectionViewModel? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems,
              !queryItems.isEmpty else {
            return nil
        }
        return makeQueryItems(for: queryItems)
    }

    static func makeQueryItems(for queryItems: [URLQueryItem]) -> KeyValueSectionViewModel? {
        KeyValueSectionViewModel(
            title: "Query Items",
            color: .purple,
            items: queryItems.map { ($0.name, $0.value) }
        )
    }

#if !os(watchOS)
    static func makeDetails(for jwt: JWT) -> NSAttributedString {
        let renderer = TextRenderer()
        let sections: [NSAttributedString] = [
            TextMake(renderer: renderer)
                .subheadline("Header")
                .json(jwt.header, color: .systemRed)
                .newline(),
            TextMake(renderer: renderer)
                .subheadline("Payload")
                .json(jwt.body, color: .systemPurple)
                .newline(),
            jwt.signature.map {
                TextMake(renderer: renderer)
                    .subheadline("Signature")
                    .pre($0, color: .systemBlue)
                    .newline()
            },
            TextMake(renderer: renderer)
                .subheadline("Encoded")
                .pre(jwt.parts[0], color: .systemRed)
                .pre(".")
                .pre(jwt.parts[1], color: .systemPurple)
                .pre(".")
                .pre(jwt.parts[2], color: .systemBlue)
        ].compactMap { $0?.make() }
        return renderer.joined(sections)
    }
#endif

#warning("TODO: remove?")

#if os(iOS) || os(macOS) || os(tvOS)
    static func makeTiming(for transaction: NetworkTransactionMetricsEntity) -> KeyValueSectionViewModel {
        let timeFormatter = DateFormatter()
        timeFormatter.locale = Locale(identifier: "en_US")
        timeFormatter.dateFormat = "HH:mm:ss.SSSSSS"

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.dateStyle = .medium
        dateFormatter.doesRelativeDateFormatting = true

        var startDate: Date?
        var items: [(String, String?)] = []
        func addDate(_ date: Date?, title: String) {
            guard let date = date else { return }
            if items.isEmpty {
                startDate = date
                items.append(("Date", dateFormatter.string(from: date)))
            }
            var value = timeFormatter.string(from: date)
            if let startDate = startDate, startDate != date {
                let duration = date.timeIntervalSince(startDate)
                value += " (+\(DurationFormatter.string(from: duration)))"
            }
            items.append((title, value))
        }
        let timing = transaction.timing
        addDate(timing.fetchStartDate, title: "Fetch Start")
        addDate(timing.domainLookupStartDate, title: "Domain Lookup Start")
        addDate(timing.domainLookupEndDate, title: "Domain Lookup End")
        addDate(timing.connectStartDate, title: "Connect Start")
        addDate(timing.secureConnectionStartDate, title: "Secure Connect Start")
        addDate(timing.secureConnectionEndDate, title: "Secure Connect End")
        addDate(timing.connectEndDate, title: "Connect End")
        addDate(timing.requestStartDate, title: "Request Start")
        addDate(timing.requestEndDate, title: "Request End")
        addDate(timing.responseStartDate, title: "Response Start")
        addDate(timing.responseEndDate, title: "Response End")

        return KeyValueSectionViewModel(title: "Timing", color: .orange, items: items)
    }
#endif
}
