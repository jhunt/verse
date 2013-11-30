#!perl
use utf8;
use strict;
use warnings;
use Test::More;
use Test::Deep;
use File::Slurp qw/read_file/;
use Cwd qw/chdir/;

BEGIN { use_ok 'Verse'
		or BAIL_OUT "Could not `use Verse`" }
BEGIN { use_ok 'Verse::Object::Base'
		or BAIL_OUT "Could not `use Verse::Object::Base`" }
BEGIN { use_ok 'Verse::Theme'
		or BAIL_OUT "Could not `use Verse::Theme`" }

use Verse::Object::Blog;
use Verse::Object::Page;

{ # shortcut methods
	is(blog, 'Verse::Object::Blog', 'blog() => Blog');
	is(page, 'Verse::Object::Page', 'page() => Page');
}

my $PWD = $ENV{PWD};
{ # path interpolation
	local $Verse::ROOT = "t/data/root/blog";

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

{ # rendering w/layout
	chdir "t/data/root/blog";
	$Verse::ROOT = $ENV{PWD};
	Verse::verse(1); # reload

	is(Verse::Theme::template,
		Verse::Theme::template('site.tt'),
		"site.tt is the default template");

	isnt(Verse::Theme::template,
		Verse::Theme::template('alt.tt'),
		"alt.tt is not site.tt");

	is(Verse::Theme::template,
		Verse::Theme::template('nonexistent.tt'),
		"nonexistent layout == default");

	mkdir "htdocs"; # {site}

	Verse::Theme::render({},
		using  => "test.tt",
		at     => "{site}/test.html");
	is(read_file("htdocs/test.html"),
		"SITE", "Rendered with default layout");

	Verse::Theme::render({},
		using  => "test.tt",
		layout => "alt.tt",
		at     => "{site}/test.html");
	is(read_file("htdocs/test.html"),
		"ALT", "Rendered with default layout");

	chdir $PWD;
	qx(rm -fr t/data/root/blog/htdocs);
}

{ # unicode rendering
	chdir "t/data/root/unicode";
	$Verse::ROOT = $ENV{PWD};
	Verse::verse(1); # reload

	mkdir "htdocs"; # {site}

	my $obj = Verse::Object::Base->read(".verse/data/unicode.yml");
	is($obj->{__attrs}{title}, '∑', "read in unicode title");
	Verse::Theme::render($obj->{__attrs},
		using  => "unicode.tt",
		at     => "{site}/test.html");
	is(read_file("htdocs/test.html", binmode => ':utf8'),
		"var(∑), literal(∑)", "Rendered unicode");

	chdir $PWD;
	qx(rm -fr t/data/root/unicode/htdocs);
}

done_testing;
