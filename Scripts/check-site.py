#!/usr/bin/env python3
"""Static checks for the landing page in site/. Usage: python3 Scripts/check-site.py"""

import re
import sys
from html.parser import HTMLParser
from pathlib import Path

SITE = Path(__file__).resolve().parent.parent / "site"
CSS_ORDER = ["css/tokens.css", "css/base.css", "css/atoms.css", "css/molecules.css", "css/organisms.css", "css/templates.css"]
PREFIX = re.compile(r"^[amot]-[a-z0-9-]+")

failures = []


def check(condition, message):
    if not condition:
        failures.append(message)


class Page(HTMLParser):
    def __init__(self):
        super().__init__()
        self.elements = []  # (tag, attrs, ancestors' classes)
        self.stack = []
        self.text = []
        self.h1 = []
        self.in_h1 = False

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        self.elements.append((tag, attrs, [c for _, a in self.stack for c in a.get("class", "").split()]))
        if tag not in ("img", "link", "meta", "br", "source", "input", "path", "circle", "rect", "line", "polyline"):
            self.stack.append((tag, attrs))
        if tag == "h1":
            self.in_h1 = True

    def handle_startendtag(self, tag, attrs):
        self.elements.append((tag, dict(attrs), [c for _, a in self.stack for c in a.get("class", "").split()]))

    def handle_endtag(self, tag):
        for i in range(len(self.stack) - 1, -1, -1):
            if self.stack[i][0] == tag:
                del self.stack[i:]
                break
        if tag == "h1":
            self.in_h1 = False

    def handle_data(self, data):
        self.text.append(data)
        if self.in_h1:
            self.h1.append(data)

    def all(self, tag=None, cls=None):
        return [(t, a, p) for t, a, p in self.elements
                if (tag is None or t == tag) and (cls is None or cls in a.get("class", "").split())]

    def inside(self, cls, tag=None, inner_cls=None):
        return [(t, a) for t, a, p in self.elements
                if cls in p and (tag is None or t == tag) and (inner_cls is None or inner_cls in a.get("class", "").split())]


def local(ref):
    return ref and not re.match(r"^(https?:|#|mailto:|data:)", ref)


index = SITE / "index.html"
if not index.exists():
    print("FAIL: site/index.html does not exist")
    sys.exit(1)

page = Page()
page.feed(index.read_text())
text = " ".join(" ".join(page.text).split())
css_files = {p: (SITE / p).read_text() for p in CSS_ORDER if (SITE / p).exists()}
css = "\n".join(css_files.values())

# Structure
check(len(page.all("h1")) == 1, "exactly one <h1>")
check(any(a.get("lang") == "en" for _, a, _ in page.all("html")), '<html lang="en">')
sheets = [a.get("href") for _, a, _ in page.all("link") if a.get("rel") == "stylesheet"]
check(sheets == CSS_ORDER, f"stylesheets in Atomic Design order, got {sheets}")

for tag, attrs, _ in page.elements:
    for key in ("href", "src", "srcset"):
        ref = attrs.get(key)
        if not ref:
            continue
        for part in ref.split(","):
            path = part.strip().split(" ")[0].split("#")[0]
            if local(path):
                check((SITE / path).exists(), f"{tag} {key}={path} exists")
    if tag == "script" and attrs.get("src"):
        check(local(attrs["src"]), f"script {attrs['src']} is local")
    if tag == "link" and attrs.get("rel") == "stylesheet":
        check(local(attrs.get("href")), f"stylesheet {attrs.get('href')} is local")

for _, attrs, _ in page.all("img"):
    name = attrs.get("src")
    check("alt" in attrs and (attrs["alt"] or attrs.get("aria-hidden") == "true"), f"img {name} has alt")
    check(attrs.get("width") and attrs.get("height"), f"img {name} has width and height")

used = {PREFIX.match(c).group(0).split("--")[0] for _, a, _ in page.elements for c in a.get("class", "").split() if PREFIX.match(c)}
for cls in sorted(used):
    check(re.search(r"\." + re.escape(cls) + r"(?![a-z0-9_-])", css), f"class .{cls} is styled")

for name, content in css_files.items():
    if name != "css/tokens.css":
        check(not re.search(r"#[0-9a-fA-F]{3,8}\b|rgba?\(", content), f"{name} has no color literals")

# Hero
BREW = "brew install --cask kijart/tap/network-menu-bar"
LATEST = "https://github.com/kijart/network-menu-bar/releases/latest"
check("Know how you're connected." in "".join(page.h1), "h1 is the hero headline")
check(any(t == "code" and "m-copy-command" in p for t, a, p in page.elements), "a .m-copy-command holds a <code>")
check(BREW in text, "the Homebrew command is on the page")
check(any(a.get("href") == LATEST for _, a, _ in page.all("a")), "a link to the latest release")
buttons = page.inside("m-copy-command", "button")
check(buttons and all("hidden" in a for _, a in buttons), "Copy buttons are hidden until JS enables them")

# Stats, features and spotlight
check(len(page.inside("o-stats", inner_cls="m-stat")) == 4, "four stats")
cards = page.inside("o-feature-grid", inner_cls="m-feature-card")
check(len(cards) == 6, "six feature cards")
card_svgs = [p for t, a, p in page.elements if t == "svg" and "m-feature-card" in p]
check(len(card_svgs) == 6, "each feature card has an inline SVG icon")
check(all(a.get("aria-hidden") == "true" for t, a, p in page.elements if t == "svg"), "SVG icons are aria-hidden")
check("Home Lab" in text and "HAL 9000" not in text, 'the VPN example is "Home Lab"')
check("Every VPN" not in text and "per network change" not in text, "no claims beyond the README")

# Install and privacy
ids = {a["id"] for _, a, _ in page.elements if "id" in a}
anchors = {a["href"][1:] for _, a, _ in page.all("a") if a.get("href", "").startswith("#") and len(a["href"]) > 1}
check({"features", "install", "privacy"} <= ids, "sections #features, #install and #privacy exist")
check(anchors <= ids, f"anchor links point to existing ids, missing {sorted(anchors - ids)}")
check(page.inside("o-install", inner_cls="m-copy-command"), "the install section has the Homebrew copy command")
check(any(a.get("href") == LATEST for _, a in page.inside("o-install", "a")), "the install section links to the latest release")
privacy = " ".join(" ".join(d for d in page.text).split())
privacy_section = privacy[privacy.find("Your network stays"):]
check("at launch" in privacy_section and "Refresh" in privacy_section, "privacy mentions the lookup at launch and on Refresh")

# SEO
CANONICAL = "https://kijart.github.io/network-menu-bar/"
metas = {(a.get("name") or a.get("property")): a.get("content", "") for _, a, _ in page.all("meta") if a.get("name") or a.get("property")}
titles = [d for d in re.findall(r"<title>(.*?)</title>", index.read_text(), re.S)]
check(len(titles) == 1 and 30 <= len(titles[0]) <= 60, f"<title> of 30-60 characters, got {titles}")
check(120 <= len(metas.get("description", "")) <= 160, f"meta description of 120-160 characters, got {len(metas.get('description', ''))}")
check(any(a.get("rel") == "canonical" and a.get("href") == CANONICAL for _, a, _ in page.all("link")), "canonical URL")
for key in ("og:title", "og:description", "og:url", "og:image"):
    check(metas.get(key), f"{key} is set")
check(metas.get("og:type") == "website", "og:type is website")
check(metas.get("og:url") == CANONICAL, "og:url is the canonical URL")
og_image = metas.get("og:image", "")
check(og_image.startswith(CANONICAL) and (SITE / og_image[len(CANONICAL):]).exists(), "og:image is absolute and exists")
check(metas.get("twitter:card") == "summary_large_image", "twitter:card is summary_large_image")
themes = [a.get("media", "") for _, a, _ in page.all("meta") if a.get("name") == "theme-color"]
check(len(themes) == 2 and any("light" in m for m in themes) and any("dark" in m for m in themes), "theme-color for light and dark")

ld = re.findall(r'<script type="application/ld\+json">(.*?)</script>', index.read_text(), re.S)
check(len(ld) == 1, "one JSON-LD block")
import json
if ld:
    try:
        data = json.loads(ld[0])
        check(data.get("@type") == "SoftwareApplication", "JSON-LD is a SoftwareApplication")
        for key in ("operatingSystem", "applicationCategory", "downloadUrl", "license", "screenshot"):
            check(data.get(key), f"JSON-LD has {key}")
        check(data.get("offers", {}).get("price") == "0", "JSON-LD offers a price of 0")
    except json.JSONDecodeError as error:
        check(False, f"JSON-LD parses: {error}")

def text_of(name):
    path = SITE / name
    return path.read_text() if path.exists() else ""

check(CANONICAL in text_of("sitemap.xml"), "sitemap.xml lists the canonical URL")
check("Sitemap: " + CANONICAL + "sitemap.xml" in text_of("robots.txt"), "robots.txt points to the sitemap")
llms = text_of("llms.txt").splitlines()
check(llms[:1] == ["# Network Menu Bar"] and any(line.startswith("> ") for line in llms), "llms.txt has a title and a summary")
og_png = SITE / "images/og-image.png"
if og_png.exists():
    header = og_png.read_bytes()[16:24]
    check((int.from_bytes(header[:4], "big"), int.from_bytes(header[4:], "big")) == (1280, 640), "og-image.png is 1280x640")
else:
    check(False, "images/og-image.png exists")
for icon in ("favicon.svg", "favicon.png", "apple-touch-icon.png"):
    check(any(a.get("href") == icon for _, a, _ in page.all("link")), f"{icon} is linked")

# Review fixes
check(re.search(r"\[hidden\]\s*\{[^}]*display:\s*none", css), "[hidden] stays hidden over component display rules")
check(not re.search(r"grid-template-columns:\s*1fr\s*;", css), "single-column grids use minmax(0, 1fr) so they can shrink")
check(text.count("In the detailed layout") >= 2, "the via claim says it needs the detailed layout")
check("in the detailed layout" in text_of("llms.txt"), "llms.txt says via needs the detailed layout")
check("Open Anyway" in text, "the disk image steps name Open Anyway")
if ld:
    check(json.loads(ld[0]).get("publisher"), "JSON-LD has a publisher")
tokens_css = css_files.get("css/tokens.css", "")
dark = {name: value for name, value in re.findall(r"(--color-[a-z-]+):\s*light-dark\([^,]+,\s*([^)]+)\)", tokens_css)}
check(dark, "color tokens use light-dark()")
check(dark.get("--color-band-bg") not in (dark.get("--color-bg"), dark.get("--color-tint")), "the dark privacy band differs from the page and the spotlight")
check('[data-theme="dark"]' in tokens_css and '[data-theme="light"]' in tokens_css, "tokens follow a manual theme choice")
theme_buttons = [a for _, a, _ in page.all("button", "o-header__theme")]
check(theme_buttons and "hidden" in theme_buttons[0] and theme_buttons[0].get("aria-label"), "the theme button is labelled and hidden until JS enables it")
readme = (SITE.parent / "README.md").read_text()
check("same options" not in readme, "README does not overstate what the website covers")

if failures:
    for message in failures:
        print("FAIL:", message)
    sys.exit(1)
print(f"OK: {len(used)} classes, {len(page.all('img'))} images")
