#!perl
use strict;
use warnings;
use Test::More;
use Test::Deep;

BEGIN { use_ok 'Verse'
		or BAIL_OUT "Could not `use Verse`" }
BEGIN { use_ok 'Verse::Object::Page'
		or BAIL_OUT "Could not `use Verse::Object::Page`" }

my $Page = 'Verse::Object::Page';

{
	is($Page->type, 'page',  'Page type is correct');
	is($Page->path, 'pages', 'Page path is correct');
}

{ # page parsing
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
	cmp_deeply($page->vars, {
			page => {
				title => 'New Page',
				url => 'about.html',
				body => 'This is my about page'
			}
		}, "Page attributes are correct");
	is($page->uuid, 'about.html',
		'Page returns url as uuid');


	if (-x "/usr/bin/markdown") {
		local $Verse::ROOT = 't/data/root/good';
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

done_testing;
