#!perl
use strict;
use warnings;
use Test::More;
use Test::Deep;

BEGIN { use_ok 'Verse::Object::Blog'
		or BAIL_OUT "Could not `use Verse::Object::Blog`" }

my $Blog = 'Verse::Object::Blog';

{
	is($Blog->type, 'article', 'Blog type is correct');
	is($Blog->path, 'blog',    'Blog default dir is correct');
}

{ # article parsing
	my $article;

	$article = $Blog->parse(<<EOF);
---
title: My New Post
permalink: my-new-post
--- |-
TEASER GOES HERE
--- |-
BODY GOES HERE
EOF
	isa_ok($article, $Blog, "Blog->parse");

	is($article->type, 'article', 'Blog overrides type');
	cmp_deeply($article->vars, {
			article => {
				title => 'My New Post',
				permalink => 'my-new-post',
				teaser => 'TEASER GOES HERE',
				body  => 'BODY GOES HERE'
			}
		}, 'Blog attributes are correct');

	is($article->uuid, 'my-new-post',
		"Blog overrides UUID to pull data from post");


	$article = $Blog->parse(<<EOF);
---
title: Text
format: plain
--- |-
Plain Text Teaser
--- |-
Plain Text Body
EOF
	is($article->{__attrs}{teaser},
		'Plain Text Teaser',
		'Unknown format is treated as "no format"');


	if (-x '/usr/bin/markdown') {
		local $Verse::ROOT = 't/data/root/good';
		$article = $Blog->parse(<<EOF);
---
title: Markdown
format: markdown
--- |-
This is to **tease** the reader...
--- |-
Here is the _actual_ content.
EOF
		isa_ok($article, $Blog, "Blog->parse");
		cmp_deeply($article->vars, {
				article => {
					title => 'Markdown',
					format => 'markdown',
					teaser => '<p>This is to <strong>tease</strong> the reader...</p>',
					body  => '<p>Here is the <em>actual</em> content.</p>',
				}
			}, 'Blog formats teaser and body as markdown, when appropriate');
	} # do we have markdown?


	$article = $Blog->parse(<<EOF);
---
title: Auto-Teaser
format: markdown
--- |-
Teaser & Body
EOF

	isa_ok($article, $Blog, "Blog->parse");
	cmp_deeply($article->vars, {
			article => {
				title => 'Auto-Teaser',
				format => 'markdown',
				teaser => '<p>Teaser &amp; Body</p>',
				body  => '<p>Teaser &amp; Body</p>',
			}
		}, 'Teaser doubles as body if body not given');
}

done_testing;
