# Upgrading to Modern Verse

This guide helps you upgrade existing Verse sites to take advantage of new features:

- **Content-based cache busting** - Asset URLs that only change when content changes
- **Better meta tags** - Automatic, content-aware Open Graph and Twitter Card meta tags
- **Sitemap generation** - Automatic sitemap.xml for better SEO
- **Selective regeneration** - Faster builds that only rebuild changed content

## Table of Contents

- [Quick Start](#quick-start)
- [1. Content-Based Cache Busting](#1-content-based-cache-busting)
- [2. Better Meta Tags](#2-better-meta-tags)
- [3. Sitemap Generation](#3-sitemap-generation)
- [4. Selective Regeneration](#4-selective-regeneration)
- [Troubleshooting](#troubleshooting)

---

## Quick Start

**Minimum upgrade steps:**

1. Update templates to use `[% asset "..." %]` for CSS/JS/images
2. Update `site.tt` layout to use new meta tag helpers
3. Remove `[% dometa = 'yes' %]` from content templates
4. Add `meta:` section to `site.yml`
5. Build and verify

**Full upgrade for all features:**

Follow all sections in this guide.

---

## 1. Content-Based Cache Busting

### What Changed

**Before:** Verse set a time-based `buster` on every build, invalidating all assets even if unchanged.

**After:** Use the `[% asset "path" %]` keyword to generate content-based cache-busting URLs. Asset URLs only change when the file content changes.

### Upgrade Steps

#### Step 1.1: Update your theme templates

Find all hardcoded asset references and replace them with `[% asset "..." %]`:

**Before:**
```html
<link rel="stylesheet" href="/css/style.css">
<script src="/js/app.js"></script>
<img src="/images/logo.png" alt="Logo">
```

**After:**
```html
<link rel="stylesheet" href="/[% asset 'css/style.css' %]">
<script src="/[% asset 'js/app.js' %]"></script>
<img src="/[% asset 'images/logo.png' %]" alt="Logo">
```

**Generated HTML:**
```html
<link rel="stylesheet" href="/css/style.css?vabc123def456">
<script src="/js/app.js?v789012ghi345"></script>
<img src="/images/logo.png?vjkl678mno901" alt="Logo">
```

The hash changes only when the file content changes.

#### Step 1.2: Remove manual buster usage (optional)

If your templates use `site.buster`, you can remove it:

**Before:**
```html
<link rel="stylesheet" href="/style.css?v=[% site.buster %]">
```

**After:**
```html
<link rel="stylesheet" href="/[% asset 'style.css' %]">
```

#### Step 1.3: Remove buster from site.yml (optional)

The `buster` setting is no longer set automatically. If you have a manual `buster:` in `site.yml`, you can remove it or keep it for backwards compatibility with older templates.

### Benefits

- ✅ Assets only invalidate when content changes
- ✅ Better browser caching
- ✅ Works with CDNs
- ✅ No manual intervention needed

---

## 2. Better Meta Tags

### What Changed

**Before:** Meta tags required manual coordination between templates and content:
- Templates checked `[% if dometa -%]` flag
- Content set `[% dometa = 'yes' %]` manually
- Hardcoded fallbacks like "I'm sure it's enthralling and interesting"
- Brittle path construction

**After:** Automatic, content-aware meta tags with smart defaults:
- Auto-detects content objects (page, article, gallery)
- Helper methods with fallback chain: explicit meta → content attributes → site defaults
- No `dometa` coordination needed
- Proper Open Graph and Twitter Card support

### Upgrade Steps

#### Step 2.1: Add meta defaults to site.yml

Add a `meta:` section with site-wide defaults:

```yaml
site:
  title: My Awesome Site
  subtitle: Thoughts and musings
  author: Your Name
  canon: https://example.com

  # Meta tag defaults (NEW)
  meta:
    default_description: "My personal blog about web development, design, and technology"
    default_image: /images/og-default.jpg
    twitter:
      card: summary_large_image
      site: yourusername  # without @
    facebook:
      app_id: 123456789
      author: https://www.facebook.com/yourprofile
```

#### Step 2.2: Update your layout template

Replace the old meta tag block in `layouts/site.tt`:

**Before:**
```html
[% if dometa -%]
  <meta name="twitter:card" content="summary">
  [% if site.id.twitter -%]
  <meta name="twitter:site" content="@[% site.id.twitter %]">
  [% end %]
  
  <meta property="og:type" content="article">
  <meta property="og:title" content="[% article.attrs.title %]">
  <meta property="og:url" content="[% site.canon %]/writings/[% article.attrs.permalink %].html">
  
  [% if article.attrs.thumb -%]
  <meta property="og:image" content="[% site.canon %]/content/wrt/stack.jpg">
  [% end -%]
  
  <meta property="og:description" content="[% filter collapse %]
    [% if article.attrs.abstract %]
      [% article.attrs.abstract %]
    [% else %]
      I'm sure it's enthralling and interesting
    [% end %]
  [% end %]">
  
  <title>[% article.attrs.title %] - [% site.title %]</title>
[% else -%]
  <title>[% site.title %]</title>
[% end %]
```

**After:**
```html
[% # Auto-detect if we have content object for meta tags -%]
[% has_content = page || article || gallery -%]
[% meta_obj = page || article || gallery -%]

[% if has_content -%]
  [% # Twitter Card -%]
  <meta name="twitter:card" content="[% if meta_obj.attrs.meta.twitter_card %][% meta_obj.attrs.meta.twitter_card %][% elsif site.meta.twitter.card %][% site.meta.twitter.card %][% else %]summary[% end %]">
  [% if site.meta.twitter.site -%]
  <meta name="twitter:site" content="@[% site.meta.twitter.site %]">
  [% end -%]
  
  [% # Open Graph -%]
  <meta property="og:type" content="[% meta_obj.meta_type %]">
  <meta property="og:title" content="[% meta_obj.attrs.title %]">
  <meta property="og:site_name" content="[% site.title %]">
  [% if page -%]
  <meta property="og:url" content="[% meta_obj.meta_url(meta_obj.uuid) %]">
  [% else -%]
  <meta property="og:url" content="[% meta_obj.meta_url('/writings/' _ meta_obj.uuid _ '.html') %]">
  [% end -%]
  
  [% if meta_obj.meta_description -%]
  <meta property="og:description" content="[% meta_obj.meta_description | collapse %]">
  [% end -%]
  
  [% if meta_obj.meta_image -%]
  <meta property="og:image" content="[% site.canon %][% meta_obj.meta_image %]">
  [% end -%]
  
  [% if meta_obj.meta_published_time -%]
  <meta property="article:published_time" content="[% meta_obj.meta_published_time %]">
  [% end -%]
  
  [% if site.meta.facebook.author -%]
  <meta property="article:author" content="[% site.meta.facebook.author %]">
  [% end -%]
  
  <title>[% meta_obj.meta_title %]</title>
  
[% else -%]
  [% # Homepage / no specific content -%]
  <meta property="og:type" content="website">
  <meta property="og:title" content="[% site.title %]">
  [% if site.meta.default_description -%]
  <meta property="og:description" content="[% site.meta.default_description %]">
  [% end -%]
  <meta property="og:url" content="[% site.canon %]">
  [% if site.meta.default_image -%]
  <meta property="og:image" content="[% site.canon %][% site.meta.default_image %]">
  [% end -%]
  
  <title>[% site.title %][% if site.subtitle %] - [% site.subtitle %][% end %]</title>
[% end %]
```

#### Step 2.3: Remove dometa from content templates

Remove the `[% dometa = 'yes' %]` line from your content templates:

**Before (`templates/article.tt`):**
```html
[% dometa = 'yes' %]
<h2>[% article.attrs.title %]</h2>
<p>[% article.attrs.dated %]</p>
[% article.attrs.body %]
```

**After:**
```html
<h2>[% article.attrs.title %]</h2>
<p>[% article.attrs.dated %]</p>
[% article.attrs.body %]
```

#### Step 2.4: Add meta overrides to content (optional)

Content can now override meta tags:

```yaml
# data/blog/my-post.yml
title: Amazing Discovery
permalink: amazing-discovery
dated: 2024-03-15
format: markdown

# Meta tag overrides (optional)
meta:
  description: "A deep dive into an amazing discovery that will change everything"
  image: /images/discovery-hero.jpg
  twitter_card: summary_large_image

---
Your content here...
```

### Available Helper Methods

The following methods are available on all content objects (page, article, gallery):

- `meta_title` - Smart title with site title appended
- `meta_description` - Tries: meta.description → abstract → summary → teaser → site default
- `meta_image` - Tries: meta.image → thumb → cover → featured_image → site default
- `meta_url($path)` - Builds canonical URL
- `meta_type` - Returns 'article' or 'website'
- `meta_author` - From content or site author
- `meta_published_time` - ISO 8601 format for dated content

### Benefits

- ✅ No coordination needed between theme and content
- ✅ Smart defaults reduce errors
- ✅ Content can override any meta tag
- ✅ Better SEO and social sharing
- ✅ No placeholder text like "I'm sure it's enthralling"

---

## 3. Sitemap Generation

### What Changed

**Before:** No sitemap generation - search engines had to discover pages by crawling.

**After:** Automatic `sitemap.xml` generation with:
- All HTML pages automatically included
- Last modification dates
- Priority and changefreq support
- Image sitemap support
- Configurable per-content-type defaults

### Upgrade Steps

#### Step 3.1: Add sitemap configuration to site.yml

Add a `sitemap:` section with defaults:

```yaml
site:
  title: My Site
  canon: https://example.com  # Required for sitemap!

  # Sitemap configuration (NEW)
  sitemap:
    defaults:
      page:
        priority: 0.7
        changefreq: monthly
      article:
        priority: 0.8
        changefreq: weekly
      index:
        priority: 1.0
        changefreq: daily
```

**Note:** The `canon:` URL is **required** for sitemap generation. Sitemap URLs are only generated when `site.canon` is set.

#### Step 3.2: Update your theme's render script

Add sitemap generation at the end of your `theme/*/render` script:

```perl
# ... existing render logic ...

# Generate sitemap (NEW)
use Verse::Sitemap;
sitemap_generate(path("{site}/sitemap.xml"));

1;
```

#### Step 3.3: Add sitemap overrides to content (optional)

Content can override sitemap attributes:

```yaml
# data/blog/important-post.yml
title: Very Important Post
permalink: important
dated: 2024-03-15

# Sitemap overrides (optional)
sitemap:
  priority: 0.9
  changefreq: daily
  images:
    - /images/important-hero.jpg
    - /images/important-diagram.png

---
Content here...
```

#### Step 3.4: Verify sitemap generation

After running `verse build`, check for `htdocs/sitemap.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"
        xmlns:image="http://www.google.com/schemas/sitemap-image/1.1">
  <url>
    <loc>https://example.com/index.html</loc>
    <lastmod>2024-03-15</lastmod>
    <priority>1.0</priority>
    <changefreq>daily</changefreq>
  </url>
  <url>
    <loc>https://example.com/writings/my-post.html</loc>
    <lastmod>2024-03-10</lastmod>
    <priority>0.8</priority>
    <changefreq>weekly</changefreq>
    <image:image>
      <image:loc>https://example.com/images/hero.jpg</image:loc>
    </image:image>
  </url>
</urlset>
```

#### Step 3.5: Submit sitemap to search engines

Add to your `robots.txt`:
```
Sitemap: https://example.com/sitemap.xml
```

Submit to:
- Google Search Console: https://search.google.com/search-console
- Bing Webmaster Tools: https://www.bing.com/webmasters

### Benefits

- ✅ Better SEO with proper sitemap
- ✅ Automatic URL discovery
- ✅ Fine-grained control per content
- ✅ Image sitemap support
- ✅ Standard sitemap.xml format

---

## 4. Selective Regeneration

### What Changed

**Before:** Every build regenerated all pages, even if nothing changed.

**After:** Content hash-based incremental builds - only rebuild what changed:
- Tracks SHA256 hashes of all source files
- Detects changes in content, templates, and configuration
- Skips rendering unchanged pages
- Dramatically faster builds for large sites

### Upgrade Steps

#### Step 4.1: No configuration needed!

Selective regeneration is **automatic**. Just run `verse build` as normal.

#### Step 4.2: Understand the build cache

On the first build, you'll see normal output:
```
[render] main.tt :: htdocs/index.html
[render] article.tt :: htdocs/writings/post1.html
[render] article.tt :: htdocs/writings/post2.html
[cache] Saved build cache to .verse/build-cache.yml
```

On subsequent builds with no changes:
```
[render] SKIP (cached) main.tt :: htdocs/index.html
[render] SKIP (cached) article.tt :: htdocs/writings/post1.html
[render] SKIP (cached) article.tt :: htdocs/writings/post2.html
[cache] Saved build cache to .verse/build-cache.yml
```

After editing `post2.yml`:
```
[render] SKIP (cached) main.tt :: htdocs/index.html
[render] SKIP (cached) article.tt :: htdocs/writings/post1.html
[render] article.tt :: htdocs/writings/post2.html
[cache] Saved build cache to .verse/build-cache.yml
```

#### Step 4.3: Add build cache to .gitignore

The build cache is specific to each environment and should not be committed:

```
# .gitignore
build-cache.yml
.verse/build-cache.yml
```

This is already done in the default `.gitignore`.

#### Step 4.4: Force full rebuild (if needed)

To force a complete rebuild, delete the cache:

```bash
rm .verse/build-cache.yml
verse build
```

Or if using `site.yml` in the root:

```bash
rm build-cache.yml
verse build
```

### How It Works

The build cache tracks:

1. **Source files** - Content (.yml), templates (.tt), site.yml
2. **Outputs** - Generated HTML files
3. **Dependencies** - What sources affect each output

For each render operation:
1. Compute SHA256 hash of all source files
2. Compare with previous build's hashes
3. Skip rendering if unchanged
4. Record new hashes after rendering

### When Pages Are Rebuilt

A page is rebuilt if **any** of these changed:
- The content file (e.g., `blog/post.yml`)
- The template (e.g., `templates/article.tt`)
- The layout (e.g., `layouts/site.tt`)
- The site configuration (`site.yml`)

**Example:** If you modify `layouts/site.tt`, **all pages** are rebuilt because they all use that layout.

### Benefits

- ✅ Dramatically faster builds (10-100x for large sites)
- ✅ Accurate change detection via content hashing
- ✅ Automatic dependency tracking
- ✅ No manual configuration needed

---

## Complete Example: Before and After

### Before (Old site.yml)

```yaml
site:
  title: My Blog
  author: John Doe
  canon: http://example.com
  theme: default
  
  id:
    twitter: johndoe
    facebook: https://www.facebook.com/johndoe
```

### After (Modern site.yml)

```yaml
site:
  title: My Blog
  subtitle: Thoughts on code and life
  author: John Doe
  canon: https://example.com  # Changed to https
  theme: default
  
  # Modern meta tag defaults
  meta:
    default_description: "John Doe's personal blog about web development, programming, and technology"
    default_image: /images/og-default.jpg
    twitter:
      card: summary_large_image
      site: johndoe
    facebook:
      author: https://www.facebook.com/johndoe
  
  # Sitemap configuration
  sitemap:
    defaults:
      page:
        priority: 0.7
        changefreq: monthly
      article:
        priority: 0.8
        changefreq: weekly
```

### Before (Old content file)

```yaml
# data/blog/my-post.yml
title: My Amazing Post
permalink: my-post
dated: 2024-03-15
format: markdown

---
Post content here...
```

### After (Modern content file with overrides)

```yaml
# data/blog/my-post.yml
title: My Amazing Post
permalink: my-post
dated: 2024-03-15
format: markdown

# Meta tag overrides
meta:
  description: "An in-depth exploration of amazing things"
  image: /images/my-post-hero.jpg
  twitter_card: summary_large_image

# Sitemap overrides
sitemap:
  priority: 0.9
  changefreq: weekly
  images:
    - /images/my-post-hero.jpg
    - /images/diagram1.png

---
Post content here...
```

---

## Troubleshooting

### Sitemap not generating

**Problem:** No `sitemap.xml` file after build.

**Solutions:**
1. Ensure `site.canon` is set in `site.yml` (required!)
2. Verify you added `sitemap_generate()` to your theme's render script
3. Check for errors during build
4. Ensure `use Verse::Sitemap;` is in your render script

### Asset keyword not working

**Problem:** `[% asset 'file.css' %]` shows error or doesn't generate hash.

**Solutions:**
1. Ensure the asset file exists in the output directory before the template runs
2. Assets must be copied before templates that reference them
3. Check file path is relative to site root (no leading slash in asset call)

### Build cache not skipping unchanged files

**Problem:** Every build regenerates everything.

**Solutions:**
1. Check if `.verse/build-cache.yml` is being created
2. Ensure you're not deleting `htdocs/` between builds
3. Verify file permissions allow writing to `.verse/`
4. Check for errors during cache save at end of build

### Meta tags showing "undefined"

**Problem:** Meta tags show undefined values.

**Solutions:**
1. Ensure `site.meta` section exists in `site.yml`
2. Add `default_description` and `default_image` to `site.meta`
3. Verify content objects are being passed to templates correctly
4. Check that `page`, `article`, or `gallery` variables are set in templates

### Perl errors about "can't call method"

**Problem:** Errors like "Can't call method 'can' on unblessed reference"

**Solutions:**
1. Ensure you're running the latest version of Verse
2. Verify all UNIVERSAL::can() calls are used (not $obj->can())
3. Update to latest templates

### Build very slow despite cache

**Problem:** Builds still slow even with cache.

**Solutions:**
1. First build is always slow (creates cache)
2. Changing `site.yml` forces full rebuild (by design)
3. Changing layout templates forces full rebuild (by design)
4. Check if cache file is being deleted between builds
5. Large asset copying still happens every build (only rendering is cached)

---

## Migration Checklist

Use this checklist when upgrading:

- [ ] **Cache Busting**
  - [ ] Replace hardcoded CSS links with `[% asset 'css/...' %]`
  - [ ] Replace hardcoded JS links with `[% asset 'js/...' %]`
  - [ ] Replace hardcoded image paths with `[% asset 'images/...' %]`
  - [ ] Remove manual `buster` usage

- [ ] **Meta Tags**
  - [ ] Add `meta:` section to `site.yml`
  - [ ] Set `default_description` and `default_image`
  - [ ] Configure `twitter:` and `facebook:` settings
  - [ ] Update `layouts/site.tt` with new meta tag block
  - [ ] Remove `[% dometa = 'yes' %]` from content templates
  - [ ] Test meta tags with Facebook Debugger and Twitter Card Validator

- [ ] **Sitemap**
  - [ ] Verify `canon:` is set in `site.yml` (required!)
  - [ ] Add `sitemap:` section to `site.yml`
  - [ ] Add `sitemap_generate()` to theme render script
  - [ ] Test build and verify `sitemap.xml` exists
  - [ ] Add sitemap to `robots.txt`
  - [ ] Submit to Google Search Console and Bing Webmaster

- [ ] **Build Cache**
  - [ ] Verify `.verse/build-cache.yml` in `.gitignore`
  - [ ] Test incremental builds work
  - [ ] Document force-rebuild process for team

- [ ] **Testing**
  - [ ] Build site: `verse build`
  - [ ] Verify no errors
  - [ ] Check meta tags in HTML source
  - [ ] Verify sitemap.xml exists and is valid
  - [ ] Test asset URLs include hashes
  - [ ] Test incremental build (modify one file, rebuild)
  - [ ] Test social sharing (Facebook, Twitter, LinkedIn)

---

## For AI Assistants

When helping users upgrade their Verse sites, follow this workflow:

1. **Analyze current setup:**
   - Check `site.yml` for existing structure
   - Identify theme directory and templates
   - Check for custom meta tag implementations

2. **Prioritize changes:**
   - Start with meta tags (most impact on user experience)
   - Then sitemap (SEO benefit)
   - Then cache busting (performance)
   - Build cache is automatic (mention it but don't require action)

3. **Make incremental changes:**
   - Update one system at a time
   - Test after each change
   - Don't break existing functionality

4. **Validate changes:**
   - Run `verse build` after each update
   - Check for errors in output
   - Verify generated HTML
   - Test sitemap.xml structure

5. **Common pitfalls to avoid:**
   - Don't forget `site.canon` is required for sitemaps
   - Don't use `$obj->can()` - use `UNIVERSAL::can($obj, 'method')`
   - Don't forget to remove `dometa` from templates
   - Asset paths in `[% asset %]` are relative to site root

---

## Additional Resources

- **Verse Documentation:** Run `perldoc Verse` for core API
- **Template Syntax:** Run `perldoc Verse::Template`
- **Meta Tag Testing:**
  - Facebook: https://developers.facebook.com/tools/debug/
  - Twitter: https://cards-dev.twitter.com/validator
  - LinkedIn: https://www.linkedin.com/post-inspector/
- **Sitemap Validation:** https://www.xml-sitemaps.com/validate-xml-sitemap.html

---

## Questions or Issues?

If you encounter problems during the upgrade:

1. Check this guide's [Troubleshooting](#troubleshooting) section
2. Review your build output for error messages
3. Verify you completed all steps in the relevant section
4. Check file permissions on `.verse/` directory
5. Try a clean build: `rm -rf htdocs .verse/build-cache.yml && verse build`

Happy upgrading! 🚀
