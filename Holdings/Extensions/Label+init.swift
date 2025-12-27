//
//  Label+init.swift
//  Holdings
//
//  Created by Sam on 2025-12-02.
//

import SwiftUI

extension Label where Title == Text {

    /// Creates a label with a custom icon view and a title generated from a localized string.
    ///
    /// - Parameters:
    ///   - titleKey: A title generated from a localized string.
    ///   - icon: A view builder that creates the icon view.
    nonisolated public init(_ titleKey: LocalizedStringKey, @ViewBuilder icon: () -> Icon) {
        self.init {
            Text(titleKey)
        } icon: {
            icon()
        }
    }

    /// Creates a label with a custom icon view and a title generated from a string.
    ///
    /// - Parameters:
    ///   - title: A string used as the label's title.
    ///   - icon: A view builder that creates the icon view.
    @_disfavoredOverload
    nonisolated public init<S>(_ title: S, @ViewBuilder icon: () -> Icon) where S: StringProtocol {
        self.init {
            Text(title)
        } icon: {
            icon()
        }
    }
}

extension Label where Title == Text, Icon == Image {

    /// Creates a label with an internal system icon image and a title generated from a localized string.
    ///
    /// - Parameters:
    ///   - titleKey: A title generated from a localized string.
    ///   - internalSystemName: The name of the internal system image resource to lookup.
    nonisolated public init(_ titleKey: LocalizedStringKey, internalSystemName systemName: String) {
        self.init {
            Text(titleKey)
        } icon: {
            Image(_internalSystemName: systemName)
        }
    }

    /// Creates a label with an internal system icon image and a title generated from a string.
    ///
    /// - Parameters:
    ///   - title: A string used as the label's title.
    ///   - internalSystemName: The name of the internal system image resource to lookup.
    @_disfavoredOverload
    nonisolated public init<S>(_ title: S, internalSystemName systemName: String) where S: StringProtocol {
        self.init {
            Text(title)
        } icon: {
            Image(_internalSystemName: systemName)
        }
    }
}
