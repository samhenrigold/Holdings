Holdings is an investment and expansion strategy game. It's a clone of the board game Acquire.

The aim of the game is to earn the most money by building and merging corporations.

When a corporation is acquired by a larger corporation, players earn money based on the size of the acquired corporation. At the end of the game, all shares are sold and the player with the most money wins.

The project requires the iOS SDK and targets iOS 18+, leveraging the latest SwiftUI APIs. We're building with Swift 6 strict concurrency enabled. The default actor isolation is `MainActor`.

### Key Architectural Patterns
**Do NOT use ViewModels or MVVM patterns**.

- **Modern Approach**: Views as pure state expressions using SwiftUI primitives
- **Environment Objects**: Used for dependency injection (Router, CurrentAccount, Theme, etc.)
- **Swift Concurrency**: Async/await throughout for API calls
- **Observation Framework**: Uses `@Observable` for services injected via Environment

## Modern SwiftUI Architecture Guidelines (2025)

### Core Philosophy

- SwiftUI is the default UI paradigm - embrace its declarative nature
- Avoid legacy UIKit patterns and unnecessary abstractions
- Focus on simplicity, clarity, and native data flow
- Let SwiftUI handle the complexity - don't fight the framework
- **No ViewModels** - Use native SwiftUI data flow patterns

### Architecture Principles

#### 1. Native State Management

Use SwiftUI's built-in property wrappers appropriately:
- `@State` - Local, ephemeral view state
- `@Binding` - Two-way data flow between views
- `@Observable` - Shared state (preferred for new code)
  - Adds update tracking to classes
  - Reading a property establishes a dependency
    - Equatable properties don't trigger updates
  - Writing a property doesn't establish a dependency
- `@Environment` - Dependency injection for app-wide concerns

@State vs. @Observable
- @State
  - For data owned by a view, and used and modified locally
  - For tightly coupled two-way data sharing between views (with @Binding)
- @Observable
  - For shared data that needs to be written or read across many views

#### 2. State Ownership

- Views own their local state unless sharing is required
- State flows down, actions flow up
- Keep state as close to where it's used as possible
- Extract shared state only when multiple views need it

Example:
```swift
struct TimelineView: View {
    @Environment(Client.self) private var client
    @State private var viewState: ViewState = .loading

    enum ViewState {
        case loading
        case loaded(statuses: [Status])
        case error(Error)
    }

    var body: some View {
        Group {
            switch viewState {
            case .loading:
                ProgressView()
            case .loaded(let statuses):
                StatusList(statuses: statuses)
            case .error(let error):
                ErrorView(error: error)
            }
        }
        .task {
            await loadTimeline()
        }
    }

    private func loadTimeline() async {
        do {
            let statuses = try await client.getHomeTimeline()
            viewState = .loaded(statuses: statuses)
        } catch {
            viewState = .error(error)
        }
    }
}
```

#### 3. Modern Async Patterns

- Use `async/await` as the default for asynchronous operations
- Leverage `.task` modifier for lifecycle-aware async work.
- Use `.task` to "pre-warm" expensive resources (like camera sessions) before the user fully interacts, moving asset loading off the critical interaction path.
- Handle errors gracefully with try/catch
- Avoid Combine unless absolutely necessary

#### 4. View Composition

- Build UI with small, focused views
- Extract reusable components naturally
- Use view modifiers to encapsulate common styling
- Prefer composition over inheritance

#### 5. Code Organization

- Organize by feature (e.g., Timeline/, Account/, Settings/)
- Keep related code together in the same file when appropriate
- Use extensions to organize large files
- Follow Swift naming conventions consistently

### Best Practices

#### DO:
- Write self-contained views when possible
- Use property wrappers as intended by Apple
- Test logic in isolation, preview UI visually
- Handle loading and error states explicitly
- Keep views focused on presentation
- Use Swift's type system for safety
- Trust SwiftUI's update mechanism

#### DON'T:
- Create ViewModels for every view
- Move state out of views unnecessarily
- Add abstraction layers without clear benefit
- Use Combine for simple async operations
- Fight SwiftUI's update mechanism
- Overcomplicate simple features
- **Nest @Observable objects within other @Observable objects** - This breaks SwiftUI's observation system. Initialize services at the view level instead.
- Specify VStack/HStack spacing or padding values — just use the defaults

### SwiftUI performance tips
- **Optimize Escaping Closures**
  - Storing escaping closures (like `@ViewBuilder`) on a View struct breaks SwiftUI's equality check because closures are hard to compare.
  - **Solution:** Execute the closure inside the View's `init` and store the resulting *View* instead of the closure function. This allows SwiftUI to compare the view hierarchy correctly.

- **Manage Hot Paths (High Frequency Updates)**
  - A hot path is code that executes frequently (e.g., scrolling, video frame updates, window resizing).
  - **The Anti-Pattern:** Updating `@State` or writing to the `@Environment` continuously during a hot path causes massive downstream updates because every view reading that Environment must re-check dependencies.
  - **The Fix:** Move high-frequency data (like scroll offset or playback time) into an `@Observable` class reference type. Update the property on the class instead of writing to View State. This bypasses the view hierarchy update cycle.

- **Visual Effects & Rendering**
  - **Group Visual Effects:** Rendering individual glass/blur effects is expensive. Group nearby elements into a container and apply the effect to the container.
  - **Avoid Invisible Rerenders:** Be cautious of animations (like spinners) hidden under other layers; they may still trigger rerenders of the parent container.

#### Performance FAQ
Q: Is there a good pattern to pass an action closure to a view while minimizing impact, given that closures are hard to compare?
A: Try to capture as little as possible in closures---for example, by not relying on implicit captures (which usually capture self and therefore depend on the whole view value) and instead capturing only the properties of the view value that you actually need in the closure.

Q: How should I think about a skipped update? Are we saying that frames were skipped?
A: No, it means that the view's value (that is, all stored properties of a view) was equal to the previous view value and therefore the view's body wasn't evaluated.

Q: How do you recommend keeping an Observable model object in sync with a backing store, like a database? Should I use a private backing variable with a `didSet` to propagate bindings to the database, or is it better to write a custom observable object without the macro?
A: Should you choose to do this yourself, I would strongly encourage you to aggregate changes together at a greater scale than just a property change before propagating them to a database. In general, reacting synchronously to individual property changes one at a time is not good for performance.

Q: If injecting an Observable view model into a view, should it be stored as @State?
A: You don't need to store it as `@State` and it can just be stored in a `let` or `var`

Q: Would using a Timer to update my SwiftUI view be costly in terms of performance? For example, if I want to show the current time in hours, minutes, and seconds, but also have other views that depend on how long the timer has been running?
A: Yeah, this is fine! If you don't need other events to happen in sync with the timer updating, we'd recommend using a date-relative text, but if you need multiple UI elements to be in sync with a timer, there's nothing wrong with doing that. As host has emphasized though, be sure that you're only causing updates for views which actually need to change with the timer!

Q: When does it make sense (if ever) to use `@Binding` in a child view to improve performance versus using let? Assume the child view does not update the value of the property passed in by the parent.
A: You should prefer using a `let` if you don't need to write back to the binding. In most cases reading a binding is equivalent to just passing the value directly, but in certain situations (such as if the binding is not generated directly from a `@State`), bindings can add additional overhead.

Q: In our app, a Combine Published object updates the UI. We can use either `receive(on: RunLoop.main)` or `receive(on: DispatchQueue.main)`, and both seem to work. Is there a recommended choice between the two?
A: Both options will schedule work to be completed on the main thread and allow you to update your UI. The decision depends on the exact details. Using `DispatchQueue.main` will result in your work executing on the main thread as soon as possible. Using `RunLoop.main` will schedule work onto the `RunLoop` and can result in delays to your UI updates. Consider a scenario where you are scrolling---updating your UI frequently while scrolling can degrade performance. In this case, scheduling onto the RunLoop could result in smoother scrolling. However, if you need the UI to update as quickly as possible, scheduling onto `DispatchQueue.main` is the best choice.

## Core instructions
- Swift 6.2 or later, using modern Swift concurrency.
- SwiftUI backed up by `@Observable` classes for shared data.
- Do not introduce third-party frameworks without asking first.
- Avoid UIKit unless requested.

## Swift instructions

- Always mark `@Observable` classes with `@MainActor`.
- Assume strict Swift concurrency rules are being applied.
- Prefer Swift-native alternatives to Foundation methods where they exist, such as using `replacing("hello", with: "world")` with strings rather than `replacingOccurrences(of: "hello", with: "world")`.
- Prefer modern Foundation API, for example `URL.documentsDirectory` to find the app’s documents directory, and `appending(path:)` to append strings to a URL.
- Never use C-style number formatting such as `Text(String(format: "%.2f", abs(myNumber)))`; always use `Text(abs(change), format: .number.precision(.fractionLength(2)))` instead.
- Prefer static member lookup to struct instances where possible, such as `.circle` rather than `Circle()`, and `.borderedProminent` rather than `BorderedProminentButtonStyle()`.
- Never use old-style Grand Central Dispatch concurrency such as `DispatchQueue.main.async()`. If behavior like this is needed, always use modern Swift concurrency.
- Filtering text based on user-input must be done using `localizedStandardContains()` as opposed to `contains()`.
- Avoid force unwraps and force `try` unless it is unrecoverable.


## SwiftUI instructions

- Always use `foregroundStyle()` instead of `foregroundColor()`.
- Always use `clipShape(.rect(cornerRadius:))` instead of `cornerRadius()`.
- Always use the `Tab` API instead of `tabItem()`.
- Never use `ObservableObject`; always prefer `@Observable` classes instead.
- Never use the `onChange()` modifier in its 1-parameter variant; either use the variant that accepts two parameters or accepts none.
- Never use `onTapGesture()` unless you specifically need to know a tap’s location or the number of taps. All other usages should use `Button`.
- Never use `Task.sleep(nanoseconds:)`; always use `Task.sleep(for:)` instead.
- Never use `UIScreen.main.bounds` to read the size of the available space.
- Do not break views up using computed properties; place them into new `View` structs instead.
- Do not force specific font sizes; prefer using Dynamic Type instead.
- Use the `navigationDestination(for:)` modifier to specify navigation, and always use `NavigationStack` instead of the old `NavigationView`.
- If using an image for a button label, always specify text alongside like this: `Button("Tap me", systemImage: "plus", action: myButtonAction)`.
- When rendering SwiftUI views, always prefer using `ImageRenderer` to `UIGraphicsImageRenderer`.
- Don’t apply the `fontWeight()` modifier unless there is good reason. If you want to make some text bold, always use `bold()` instead of `fontWeight(.bold)`.
- Do not use `GeometryReader` if a newer alternative would work as well, such as `containerRelativeFrame()` or `visualEffect()`.
- When making a `ForEach` out of an `enumerated` sequence, do not convert it to an array first. So, prefer `ForEach(x.enumerated(), id: \.element.id)` instead of `ForEach(Array(x.enumerated()), id: \.element.id)`.
- When hiding scroll view indicators, use the `.scrollIndicators(.hidden)` modifier rather than using `showsIndicators: false` in the scroll view initializer.
- If a ScrollView has an opaque background, explicitly apply `.scrollContentBackground(.visible)` (or a specific color) to optimize scroll edge rendering performance.
- Place view logic into view models or similar, so it can be tested.
- Avoid `AnyView` unless it is absolutely required.
- Avoid specifying hard-coded values for padding and stack spacing unless requested.
- Avoid using AppKit colors in SwiftUI code.


## Project structure

- Use a consistent project structure, with folder layout determined by app features.
- Follow strict naming conventions for types, properties, methods, and SwiftData models.
- Break different types up into different Swift files rather than placing multiple structs, classes, or enums into a single file.
- Write unit tests for core application logic.
- Only write UI tests if unit tests are not possible.
- Add code comments and documentation comments as needed.
- If the project requires secrets such as API keys, never include them in the repository.