struct Article {
    var styleSheets: [StyleSheet]
    var scripts: [Script]
    var content: String

    var html: String {
        return """
<head>
\(styleSheets.map(\.html).joined(separator: "\n"))
\(scripts.map(\.html).joined(separator: "\n"))
</head>

\(content)
"""
    }
}
