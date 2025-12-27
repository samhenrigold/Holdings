//
//  LabeledContent+init.swift
//  Holdings
//
//  Created by Sam on 2025-12-02.
//

import SwiftUI

extension LabeledContent where Label == SwiftUI.Label<Text, Image>, Content: View {

    /// Creates a labeled content with a system icon image label and a title generated from a localized string.
    ///
    /// - Parameters:
    ///   - titleKey: A title generated from a localized string.
    ///   - systemImage: The name of the system image resource to lookup.
    ///   - content: The value content being labeled.
    nonisolated public init(
        _ titleKey: LocalizedStringKey,
        systemImage name: String,
        @ViewBuilder content: () -> Content
    ) {
        self.init {
            content()
        } label: {
            Label(titleKey, systemImage: name)
        }
    }

    /// Creates a labeled content with a system icon image label and a title generated from a string.
    ///
    /// - Parameters:
    ///   - title: A string used as the label's title.
    ///   - systemImage: The name of the system image resource to lookup.
    ///   - content: The value content being labeled.
    @_disfavoredOverload
    nonisolated public init<S>(
        _ title: S,
        systemImage name: String,
        @ViewBuilder content: () -> Content
    ) where S: StringProtocol {
        self.init {
            content()
        } label: {
            Label(title, systemImage: name)
        }
    }
}
