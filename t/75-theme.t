#!perl
use strict;
use warnings;
use Test::More;
use Test::Deep;

BEGIN { use_ok 'Verse'
		or BAIL_OUT "Could not `use Verse`" }
BEGIN { use_ok 'Verse::Theme'
		or BAIL_OUT "Could not `use Verse::Object::Blog`" }

use Verse::Object::Blog;
use Verse::Object::Page;

{ # shortcut methods
	is(blog, 'Verse::Object::Blog');
	is(page, 'Verse::Object::Page');
}

{ # path interpolation
	local $Verse::ROOT = 't/data/root/blog';

	is(Verse::Theme::path('{root}/path/from/root'),
		't/data/root/blog/.verse/path/from/root',
		"path interpolation understands {root}");

	is(Verse::Theme::path('{data}/path/from/data'),
		't/data/root/blog/.verse/data/path/from/data',
		"path interpolation understands {data}");

	is(Verse::Theme::path('{theme}/path/from/theme'),
		't/data/root/blog/.verse/theme/default/path/from/theme',
		"path interpolation understands {theme}");

	is(Verse::Theme::path('{site}/path/from/site'),
		't/data/root/blog/htdocs/path/from/site',
		"path interpolation understands {site}");

	is(Verse::Theme::path('{a}/{b}/{c}',
			a => 1, b => 2, c => 3),
		'1/2/3', "path interpolation understands extra params");
}

done_testing;
