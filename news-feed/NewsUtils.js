// NewsUtils.js - RSS and Atom Feed parsing, entity decoding, and preset catalog
.pragma library

// Curated library of popular feeds
var PRESETS = [
    {
        name: "Arch Linux News",
        url: "https://archlinux.org/feeds/news/",
        category: "Linux",
        icon: "terminal",
        description: "Official package updates, manual intervention warnings, and release announcements"
    },
    {
        name: "CachyOS News",
        url: "https://cachyos.org/feed.xml",
        category: "Linux",
        icon: "speed",
        description: "Kernel optimizations, desktop environment updates, and CachyOS announcements"
    },
    {
        name: "Phoronix",
        url: "https://www.phoronix.com/phoronix-rss.php",
        category: "Hardware",
        icon: "memory",
        description: "Open-source Linux hardware benchmarks, kernel graphics drivers, and reviews"
    },
    {
        name: "Hacker News",
        url: "https://news.ycombinator.com/rss",
        category: "Tech",
        icon: "code",
        description: "Curated community tech, programming, and computer science discussions"
    },
    {
        name: "GamingOnLinux",
        url: "https://www.gamingonlinux.com/article_rss.php",
        category: "Gaming",
        icon: "sports_esports",
        description: "Proton, Steam Deck, native Linux gaming, and driver progress"
    },
    {
        name: "Insider Gaming",
        url: "https://insider-gaming.com/feed/",
        category: "Gaming",
        icon: "videogame_asset",
        description: "Video game industry leaks, exclusives, and latest updates"
    },
    {
        name: "Android Authority",
        url: "https://www.androidauthority.com/feed/",
        category: "Mobile",
        icon: "android",
        description: "Android smartphone reviews, updates, ecosystem news, and apps"
    },
    {
        name: "GSMArena",
        url: "https://www.gsmarena.com/rss-news-reviews.php3",
        category: "Mobile",
        icon: "smartphone",
        description: "Mobile device specifications, teardowns, camera comparisons, and tech news"
    },
    {
        name: "Ars Technica",
        url: "https://feeds.arstechnica.com/arstechnica/index",
        category: "Tech",
        icon: "newspaper",
        description: "In-depth analysis of technology, science, policy, and gadget news"
    },
    {
        name: "GitHub Blog",
        url: "https://github.blog/feed/",
        category: "Dev",
        icon: "terminal",
        description: "Developer tools, open-source updates, Git features, and security advisories"
    },
    {
        name: "The Verge",
        url: "https://www.theverge.com/rss/index.xml",
        category: "Tech",
        icon: "language",
        description: "Technology news, gear reviews, consumer electronics, and culture"
    },
    {
        name: "Linux Weekly News",
        url: "https://lwn.net/headlines/rss",
        category: "Linux",
        icon: "article",
        description: "Technical reporting on the Linux kernel and free software development"
    }
];

// Clean HTML and unescape HTML/XML entities
function cleanText(text) {
    if (!text) return "";
    var s = String(text);
    // Strip CDATA wrappers
    s = s.replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, "$1");
    // Strip HTML tags
    s = s.replace(/<[^>]+>/g, " ");
    // Unescape common XML/HTML entities
    s = s.replace(/&amp;/g, "&")
         .replace(/&lt;/g, "<")
         .replace(/&gt;/g, ">")
         .replace(/&quot;/g, "\"")
         .replace(/&#039;/g, "'")
         .replace(/&apos;/g, "'")
         .replace(/&nbsp;/g, " ")
         .replace(/&#8217;/g, "’")
         .replace(/&#8216;/g, "‘")
         .replace(/&#8220;/g, "“")
         .replace(/&#8221;/g, "”")
         .replace(/&#8211;/g, "–")
         .replace(/&#8212;/g, "—")
         .replace(/&#(\d+);/g, function(match, dec) {
             return String.fromCharCode(dec);
         });
    // Collapse excess whitespace
    s = s.replace(/\s+/g, " ").trim();
    return s;
}

// Format date into human readable string
function formatDate(dateStr) {
    if (!dateStr) return "";
    var d = new Date(dateStr);
    if (isNaN(d.getTime())) {
        return cleanText(dateStr);
    }
    
    var now = new Date();
    var diffMs = now.getTime() - d.getTime();
    var diffMinutes = Math.floor(diffMs / (1000 * 60));
    var diffHours = Math.floor(diffMs / (1000 * 60 * 60));
    var diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

    if (diffMinutes >= 0 && diffMinutes < 60) {
        return diffMinutes <= 1 ? "Just now" : diffMinutes + "m ago";
    }
    if (diffHours >= 0 && diffHours < 24) {
        return diffHours + "h ago";
    }
    if (diffDays === 1) {
        return "Yesterday";
    }
    if (diffDays > 1 && diffDays < 7) {
        return diffDays + "d ago";
    }

    try {
        var options = { month: "short", day: "numeric", year: (d.getFullYear() !== now.getFullYear() ? "numeric" : undefined) };
        return d.toLocaleDateString(undefined, options);
    } catch (e) {
        return d.toLocaleDateString();
    }
}

// Extract hostname/domain from URL
function getDomain(url) {
    if (!url) return "";
    var match = url.match(/^(?:https?:\/\/)?(?:www\.)?([^\/\?#]+)/i);
    return match ? match[1] : url;
}

// Parse XML string (supporting RSS 2.0 and Atom) into array of articles
function parseFeedXml(xmlString) {
    var articles = [];
    if (!xmlString || typeof xmlString !== "string") {
        return articles;
    }

    // Check if Atom format (<entry>)
    var isAtom = /<feed\b[^>]*>/i.test(xmlString) && /<entry\b/i.test(xmlString);

    if (isAtom) {
        var entryRegex = /<entry\b[^>]*>([\s\S]*?)<\/entry>/gi;
        var entryMatch;
        while ((entryMatch = entryRegex.exec(xmlString)) !== null) {
            var entryContent = entryMatch[1];

            var titleMatch = entryContent.match(/<title\b[^>]*>([\s\S]*?)<\/title>/i);
            var dateMatch = entryContent.match(/<(?:published|updated)\b[^>]*>([\s\S]*?)<\/(?:published|updated)>/i);
            var summaryMatch = entryContent.match(/<(?:summary|content)\b[^>]*>([\s\S]*?)<\/(?:summary|content)>/i);
            
            // Atom links are typically <link href="..." ... /> or <link rel="alternate" href="..." />
            var linkHrefMatch = entryContent.match(/<link\b[^>]*href=["']([^"']+)["'][^>]*>/i);

            var title = titleMatch ? cleanText(titleMatch[1]) : "Untitled";
            var link = linkHrefMatch ? linkHrefMatch[1] : "";
            var dateRaw = dateMatch ? dateMatch[1].trim() : "";
            var summary = summaryMatch ? cleanText(summaryMatch[1]) : "";

            if (link) {
                articles.push({
                    title: title,
                    link: link,
                    dateRaw: dateRaw,
                    date: formatDate(dateRaw),
                    summary: summary
                });
            }
        }
    } else {
        // Standard RSS 2.0 (<item>)
        var itemRegex = /<item\b[^>]*>([\s\S]*?)<\/item>/gi;
        var itemMatch;
        while ((itemMatch = itemRegex.exec(xmlString)) !== null) {
            var itemContent = itemMatch[1];

            var rTitleMatch = itemContent.match(/<title\b[^>]*>([\s\S]*?)<\/title>/i);
            var rLinkMatch = itemContent.match(/<link\b[^>]*>([\s\S]*?)<\/link>/i);
            var rDateMatch = itemContent.match(/<pubDate\b[^>]*>([\s\S]*?)<\/pubDate>/i) || itemContent.match(/<dc:date\b[^>]*>([\s\S]*?)<\/dc:date>/i);
            var rDescMatch = itemContent.match(/<description\b[^>]*>([\s\S]*?)<\/description>/i);

            var rTitle = rTitleMatch ? cleanText(rTitleMatch[1]) : "Untitled";
            var rLink = rLinkMatch ? cleanText(rLinkMatch[1]) : "";
            var rDateRaw = rDateMatch ? cleanText(rDateMatch[1]) : "";
            var rSummary = rDescMatch ? cleanText(rDescMatch[1]) : "";

            if (rLink) {
                articles.push({
                    title: rTitle,
                    link: rLink,
                    dateRaw: rDateRaw,
                    date: formatDate(rDateRaw),
                    summary: rSummary
                });
            }
        }
    }

    return articles;
}

// Extract channel/feed title from XML
function getFeedTitle(xmlString) {
    if (!xmlString) return "";
    var match = xmlString.match(/<channel\b[^>]*>[\s\S]*?<title\b[^>]*>([\s\S]*?)<\/title>/i);
    if (match) return cleanText(match[1]);
    var atomMatch = xmlString.match(/<feed\b[^>]*>[\s\S]*?<title\b[^>]*>([\s\S]*?)<\/title>/i);
    if (atomMatch) return cleanText(atomMatch[1]);
    return "";
}
