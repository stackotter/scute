---
year: 2022
month: 04
day: 02
---
# Swift Bundler v2.0.0 released! 🎉

After almost exactly a month of work (and ~130 commits), I have finished rewriting the entirety of Swift Bundler to improve it in every single way! Rewriting Swift Bundler has taught me a lot about designing robust and user-friendly software, and hopefully I will soon find the time to create some articles about what I have learnt.

The reason that I decided to completely rewrite Swift Bundler instead of just incremently improving it was that the original version was created in only 3 days (because of time constraints), and therefore the architecture, error handling and code quality was terrible (most of the 3 days was spent figuring out how to create app bundles and how to get Xcode to play nice).

For those interested, here's [a link to the release notes on GitHub](https://github.com/stackotter/swift-bundler/releases/tag/v2.0.0).

## Overview

@TableOfContents{"stripEmojis":true,"depth":2}@

## Updating ✨

Updating to Swift Bundler v2.0.0 is extremely simple. Just run the following command.

```sh
mint install stackotter/swift-bundler
```

Note: If you have previously installed Swift Bundler with the installation script method, remove `/opt/swift-bundler`.

For more installation methods, see [the documentation](https://stackotter.github.io/swift-bundler/documentation/swiftbundler/installation).

After updating to v2.0.0, the next step is migrating your existing projects.

### Migrating existing projects automatically

Swift Bundler is full of breaking changes, which means that any existing projects will need migrating. But don't stress, because when Swift Bundler detects a `Bundle.json` file it will automatically attempt to migrate it to the new configuration format. Migration will be triggered the next time you build or run your app. The migrated configuration will be located at `Bundler.toml`.

## User-facing changes 👨‍💻

The biggest user-facing changes are; the addition of package templates, the new CLI, the new configuration format, the significantly more helpful error messages, and the [new documentation site](https://stackotter.github.io/swift-bundler/documentation/swiftbundler).

The next few sections discuss each of these changes and additions in turn.

### Package templates

Packages templates are a new feature created to make starting a new project as effortless as possible. By default, Swift Bundler v2.0.0 comes with a template for SwiftUI and a template for SwiftCrossUI. The default templates are hosted in [the swift-bundler-templates repository](https://github.com/stackotter/swift-bundler-templates).

Creating apps from templates is simple with the `create` command.

```sh
swift bundler create HelloWorld --template SwiftUI
```

Swift Bundler even provides the option to configure indentation style! (which Xcode notably does not)

### The new CLI

The new CLI is a lot more intuitive to use. Sometimes it even gives you helpful hints on what commands you may want to run next!

For example, when you create a new package with the `create` command you will get some tips on what to do next, and if the template you selected requires system dependencies you will get some instructions on how to install them as well. The new CLI also uses colours and styling to make output easier to understand at a glance.

![output from the create command](/image/swift-bundler-create.png)

### The new configuration format

When I got around to creating the new configuration format I knew that I had to use [TOML](https://toml.io/). In my opinion it's more compact, readable and human-friendly than JSON, and more readable than YAML (because it removes the need for excessive indentation).

Before I get too carried away talking about the benefits of TOML, I'll show you what the new configuration format looks like in action. This example configuration configures an app called `HelloWorld` and an app called `Updater` (which is possible because Swift Bundler now supports multi-app packages).

```toml
[apps.HelloWorld]
product = "HelloWorld"
version = "0.2.0"

[apps.HelloWorld.extra_plist_entries]
CFBundleShortVersionString = "{VERSION}_{COMMIT_HASH}"

[apps.Updater]
product = "HelloWorldUpdater"
version = "0.1.0"
```

Apps can also configure extra entries to be added to the app's `Info.plist`. These entries can include variables in them which get replaced at build time. The currently supported variables are `COMMIT_HASH` and `VERSION`. The example configuration above adds the current commit hash to the version string (which gets displayed on the `About HelloWorld` screen). This makes it very easy for users to report exactly which version of your app they are using.

### More helpful error messages

Thanks to v2.0.0's `Result`-based error handling and `LocalizedError` implementations for all error types, errors are now much more human-friendly (and they sometimes even provide helpful troubleshooting tips).

### The documentation site

The [new documentation site](https://stackotter.github.io/swift-bundler/documentation/swiftbundler/) was created using Swift's [docc](https://www.swift.org/documentation/docc/) tool. Once a public API is added to Swift Bundler, the site will also hold library documentation. The site is hosted on GitHub pages.

## Internal changes 🛠

While rewriting Swift Bundler I decided to try out `Result`-based error handling along with some functional programming patterns. I am now very glad that I made that decision, because the result (no pun intended) was a highly maintainable and robust system with good separation of concerns and useful context for each possible error.

### `Result`-based error handling

The appeal of `Result`-based error handling is that it forces each system to wrap errors in its own type before 'throwing' them. This means that even errors in obscure subsystems of the program have rich context that can be used to narrow down the source of the error without even needing to attach a debugger. `Result` also pairs nicely with functional programming patterns. I hope to make an in-depth article about my approach to `Result`-based error handling in the future.

### Functional programming patterns

Swift Bundler uses functional programming in the sense that each system is just an enum (acting as a namespace) of static functions that are pure in a loose sense. I say 'a loose sense' because many of the functions rely on the state of the file system and use the logger to log information, but almost all other inputs and outputs are defined in the function signature.

## License change 📄

To encourage a wider variety of use-cases, I have made the decision to change from GPL-v3.0 to the Apache-2.0 license. GPL-v3.0 is great at keeping all derivative works of a project open-source, which is why I love it, but this often makes GPL-v3.0 licensed tools and libraries notoriously difficult to use in corporate environments. Swift Bundler may not be production ready yet, but hopefully it will be in the near future, and I want people to be able to use it.

## Conclusion

The original version of Swift Bundler was basically just written for [Delta Client](https://github.com/stackotter/delta-client) (a personal project of mine), and it wasn't really flexible or mature enough for anyone else to use. I am very glad that I finally made the decision to rewrite it and turn it into a versatile tool for Xcode-less app creation. Hopefully in the near future I can find some time to bring Swift Bundler to Linux (and maybe even Windows) and get ever closer to the dream of cross-platform development with Swift.
