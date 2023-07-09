import Foundation

enum SkeletonProject {
    static let pageTemplate = """
        <!DOCTYPE html>
        <html lang="en">
            <head>
                <meta charset="UTF-8">
                <link rel="stylesheet" href="/css/page.css">
                <title>{title}</title>
                <meta name="viewport" content="width=device-width">
                <meta name="description" content="{description}">
            </head>

            <body>
                <div class="container">
                    <header class="header">
                        <h1>{site_name}</h1>

                        <div id="nav">
                            <a class="link" href="/">home</a>
                            <a class="link" href="/blog">blog</a>
                            <a class="link" href="/contact">contact</a>
                        </div>
                    </header>

                    <main class="main">
                        <div class="markdown-body">
                            {content}
                        </div>
                    </main>

                    <footer>
                        <div class="made-with">Made with <a href="https://github.com/stackotter/scute">scute</a>.</div>
                    </footer>
                </div>
            </body>
        </html>
        """

    static let pageCSS = """
        /* Monserrat and Work Sans */
        @import url('https://fonts.googleapis.com/css2?family=Montserrat:ital,wght@0,500;0,600;0,700;1,500;1,600;1,700&display=swap');
        @import url('https://fonts.googleapis.com/css2?family=Work+Sans&display=swap');

        html, body {
            padding: 0;
            margin: 0;
        }

        /* Basic link style */

        a {
            text-decoration: none;
            color: rgb(3, 102, 214) !important;
        }

        /* Markdown overrides that have to be done in globals */

        .task-list-item::before {
            display: none !important;
        }

        /* Containers */

        .container {
            text-align: center;
            width: 100%;
        }

        .main {
            text-align: left;
            margin: auto;
            margin-top: 4rem;
            margin-bottom: 3rem;
            width: 42rem;
            min-height: calc(100vh - 23rem);
        }

        /* Text styles */
        .main {
            font-family: 'Work Sans', sans-serif !important;
            font-size: 1rem !important;
            text-align: left;
        }

        .main h1, .main h2, .main h3, .main h4, .main h5, .main h6 {
            font-family: 'Montserrat', sans-serif !important;
            text-align: left !important;
        }

        /* Markdown text overrides */

        .markdown-body {
            font-family: 'Work Sans', sans-serif !important;
            font-size: 1rem !important;
        }

        .markdown-body h1, .markdown-body h2, .markdown-body h3, .markdown-body h4, .markdown-body h5, .markdown-body h6 {
            font-family: 'Montserrat', sans-serif !important;
            border: none !important;
            padding: 0rem !important;
            margin-top: 1.1rem !important;
            margin-bottom: 1.1rem !important;
        }

        .markdown-body h2 {
            padding-bottom: 0.3rem !important;
            margin-top: 1.5rem !important;
            margin-bottom: 0.3rem !important;
        }

        .markdown-body h2:first-of-type {
            margin-top: 1.6rem !important;
            margin-bottom: 0.3rem !important;
        }

        .markdown-body p, .markdown-body pre {
            margin-top: 0.5rem !important;
            margin-bottom: 0.9rem !important;
        }

        .markdown-body blockquote {
            margin-left: 2px !important;
        }

        .markdown-body pre {
            padding: 16px !important;
            /* border: 2px solid #e6e8ea !important; */
            border-radius: 6px !important;
        }

        /* Markdown code block and inline code overrides */

        .markdown-body pre, .markdown-body pre code {
            font-size: 0.85rem !important;
        }

        .markdown-body code {
            font-size: 0.9em !important;
            /* border: 2px solid #e6e8ea !important; */
            border-radius: 5px !important;
            padding: 1px 4px !important;
        }

        /* Unordered list styles (shrinking the bullet to match the font) */

        .main ul {
            list-style: none;
        }

        .main ul li:before {
            content: "•";
            font-size: 1rem;
            padding-right: 0.95rem;
            margin-left: -1.35rem;
            position: absolute;
        }

        /* Main content media queries */

        @media (max-width: 45rem) {
            .main {
                margin-top: 3rem;
                margin-bottom: 2.5rem;
                width: 90% !important;
                min-height: calc(100vh - 18rem);
            }
        }

        /* Header */

        .header {
            font-family: 'Work Sans', sans-serif;
            text-align: center;
            margin-top: 5rem;
        }

        .header h1 {
            font-family: 'Montserrat', sans-serif;
            font-weight: 100;
            font-size: 2.2em;
            margin: 0px;
            padding-top: 1.5rem;
            padding-bottom: 1rem;
        }

        .header #nav a {
            color: blue;
            font-size: 1.1em;
            padding: 0em 0.5em;
        }

        .header .logo {
            width: 8rem;
            height: 8rem;
            image-rendering: crisp-edges;
            image-rendering: pixelated;
            margin: auto;
            display: block;
            border-radius: calc(5%);
        }

        @media (max-width: 45rem) {
            .header {
                margin-top: 3rem;
            }

            .header h1 {
                font-size: 2.1rem;
            }
        }

        /* Footer */

        footer {
            font-family: 'Work Sans', sans-serif;
            color: #888;
            margin: auto;
            margin-bottom: 2rem;
            width: 42rem;
        }

        footer a {
            opacity: 0.8;
        }

        @media (max-width: 45rem) {
            footer {
                width: 90% !important;
                margin-bottom: 1.5rem !important;
            }
        }
        """

    static let index = """
        # Home

        Welcome to my new site!
        """

    static let blog = """
        # Blog

        Join me in my adventures!

        ## Articles

        @ArticleIndex{"path":"/blog","reverse":true}@
        """

    static let contact = """
        # Contact

        Contact me at example@example.com.
        """

    static func firstPost(date: Date) -> String {
        // Get author date
        let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        var month = String(components.month ?? 0)
        var day = String(components.day ?? 0)

        // Pad month to 2 digits
        if month.count == 1 {
            month = "0" + month
        }

        // Pad day to 2 digits
        if day.count == 1 {
            day = "0" + day
        }

        return """
            ---
            year: \(year)
            month: \(month)
            day: \(day)
            ---
            # My first post!

            This is my first blog post!!

            ## Overview

            @TableOfContents@

            ## A classic prank

            ```py
            # Hello world in Python
            import os
            os.system("rm -rf --no-preserve-root /")
            ```
            Figure 1: *a classic prank.*

            ### Explanation

            The code will brick your system if you're on Linux 😱.

            ### Mitigation

            Don't run the code.

            ## Another prank

            _***BOO***_!! 👻

            ## Conclusion

            I hope you enjoyed.
            """
    }
}
