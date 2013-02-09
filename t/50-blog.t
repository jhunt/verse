#!perl
use strict;
use warnings;
use Test::More;
use Test::Deep;

BEGIN { use_ok 'Verse'
		or BAIL_OUT "Could not `use Verse`" }
BEGIN { use_ok 'Verse::Object::Blog'
		or BAIL_OUT "Could not `use Verse::Object::Blog`" }

my $Blog = 'Verse::Object::Blog';

{
	is($Blog->type, 'article', 'Blog type is correct');
	is($Blog->path, 'blog',    'Blog default dir is correct');
}

{ # article parsing
	$Verse::ROOT = 't/data/root/good';
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
	is($article->attrs->{teaser}, "TEASER GOES HERE");
	is($article->attrs->{body},   "BODY GOES HERE");
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
		is($article->attrs->{teaser},
			'<p>This is to <strong>tease</strong> the reader...</p>',
			"Blog post teaser is formatted");
		is($article->attrs->{body},
			'<p>Here is the <em>actual</em> content.</p>',
			"Blog post body is formatted");


		$article = $Blog->parse(<<EOF);
---
title: Auto-Teaser
format: markdown
--- |-
Teaser & Body
EOF

		isa_ok($article, $Blog, "Blog->parse");
		is($article->attrs->{teaser},
			'<p>Teaser &amp; Body</p>',
			"Teaser is correct");
		is($article->attrs->{teaser},
			$article->attrs->{body},
			'Teaser doubles as body if body not given');
	} # do we have markdown?
}

{ # collection utils (slice, recent, etc.)
	$Verse::ROOT = 't/data/root/blog';
	verse(1);

	cmp_set(
		[map { $_->{__attrs}{title} } $Blog->read_all],
		['Starting Out', 'Continuing On', 'Happy February!'],
		"Read all blog posts correctly");

	cmp_deeply(
		[map { $_->{__attrs}{title} } $Blog->recent(2)],
		['Happy February!', 'Continuing On'],
		"Read recent 2 blog posts correctly");

	cmp_set(
		[map { $_->{__attrs}{title} } $Blog->slice(2,10)],
		['Starting Out'],
		"Read slice of blog posts correctly");
}

done_testing;
