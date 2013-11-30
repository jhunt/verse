#!perl
use strict;
use warnings;
use Test::More;
use Test::Deep;

BEGIN { use_ok 'Verse'
		or BAIL_OUT "Could not `use Verse`" }
BEGIN { use_ok 'Verse::Object::Page'
		or BAIL_OUT "Could not `use Verse::Object::Page`" }

$Verse::ROOT = 't/data/root/good';
my $Page = 'Verse::Object::Page';

{
	is($Page->type, 'page',  'Page type is correct');
	is($Page->path, 'pages', 'Page path is correct');
}

{ # page parsing
	$Verse::ROOT = 't/data/root/good';
	my $page;

	$page = $Page->parse(<<EOF);
---
title: New Page
url: about.html
--- |-
This is my about page
EOF
	isa_ok($page, $Page, 'Page->parse');
	is($page->type, 'page', 'Page overrides type');
	is($page->attrs->{body}, 'This is my about page');
	is($page->attrs->{url},  'about.html');
	is($page->attrs->{title}, 'New Page');
	is($page->uuid, 'about.html',
		'Page returns url as uuid');


	if (-x "/usr/bin/markdown") {
		$page = $Page->parse(<<EOF);
---
title: Markdown
url: md.html
format: markdown
--- |-
This is markdown
EOF
		is($page->{__attrs}{body}, "<p>This is markdown</p>",
			'Page supports markdown format');
	}
}

{ # unicode support
	$Verse::ROOT = 't/data/root/good';
	my $page;

	$page = $Page->parse(<<EOF);
---
title: The Last ∑
url:   last-sigma.html
--- |-
This is a literal ∑ character
EOF
	isa_ok($page, $Page, 'Page->parse (unicode)');
	is($page->attrs->{title}, 'The Last ∑',
		"Title with unicode sigma");
	is($page->{__attrs}{body}, "This is a literal ∑ character",
		"Body with unicode sigma");
}

done_testing;
