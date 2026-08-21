#!perl
use utf8;
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Cwd qw/chdir cwd/;
use lib 'lib';
use lib 'ext';

sub read_file {
	my ($file, %args) = @_;
	open my $fh, '<', $file or die "Can't open $file: $!";
	binmode $fh, $args{binmode} if $args{binmode};
	my $content = do { local $/; <$fh> };
	close $fh;
	return $content;
}

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

my $PWD = cwd;
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
	my $testdir = "t/data/root/blog";
	# Untaint for -T mode
	$testdir =~ m{^([-\@\w./ ]+)$} and $testdir = $1;

	chdir $testdir;
	$Verse::ROOT = cwd;
	$Verse::ROOT =~ m{^([-\@\w./ ]+)$} and $Verse::ROOT = $1; # untaint
	Verse::verse(1); # reload

	mkdir "htdocs"; # {site}

	# Clear build cache before first render
	unlink ".verse/build-cache.yml" if -f ".verse/build-cache.yml";

	Verse::Theme::render({},
		using  => "test.tt",
		at     => "{site}/test.html");
	is(read_file("htdocs/test.html"),
		"SITE\n", "Rendered with default layout");

	# Delete output and cache to force re-render with different layout
	unlink "htdocs/test.html";
	unlink ".verse/build-cache.yml" if -f ".verse/build-cache.yml";

	Verse::Theme::render({},
		using  => "test.tt",
		layout => "alt.tt",
		at     => "{site}/test.html");
	is(read_file("htdocs/test.html"),
		"ALT\n", "Rendered with alternate layout");

	# Delete output and cache to force re-render without layout
	unlink "htdocs/test.html";
	unlink ".verse/build-cache.yml" if -f ".verse/build-cache.yml";

	Verse::Theme::render({},
		using  => "test.tt",
		layout => "NONE",
		at     => "{site}/test.html");
	is(read_file("htdocs/test.html"),
		"from test.tt\n", "Rendered without layout");

	my $safe_pwd = $PWD;
	$safe_pwd =~ m{^([-\@\w./ ]+)$} and $safe_pwd = $1; # untaint
	chdir $safe_pwd;
	local $ENV{PATH} = '/bin:/usr/bin'; # Set safe PATH for -T mode
	qx(rm -fr t/data/root/blog/htdocs t/data/root/blog/.verse/build-cache.yml);
}

{ # unicode rendering
	my $testdir = "t/data/root/unicode";
	$testdir =~ m{^([-\@\w./ ]+)$} and $testdir = $1; # untaint
	chdir $testdir;
	$Verse::ROOT = cwd;
	$Verse::ROOT =~ m{^([-\@\w./ ]+)$} and $Verse::ROOT = $1; # untaint
	Verse::verse(1); # reload

	mkdir "htdocs"; # {site}
	unlink ".verse/build-cache.yml" if -f ".verse/build-cache.yml";

	my $obj = Verse::Object::Base->read(".verse/data/unicode.yml");
	is($obj->{__attrs}{title}, '∑', "read in unicode title");
	Verse::Theme::render($obj->{__attrs},
		using  => "unicode.tt",
		at     => "{site}/test.html");
	is(read_file("htdocs/test.html", binmode => ':utf8'),
		"var(∑), literal(∑)\n", "Rendered unicode");

	my $safe_pwd = $PWD;
	$safe_pwd =~ m{^([-\@\w./ ]+)$} and $safe_pwd = $1; # untaint
	chdir $safe_pwd;
	local $ENV{PATH} = '/bin:/usr/bin';
	qx(rm -fr t/data/root/unicode/htdocs t/data/root/unicode/.verse/build-cache.yml);
}

done_testing;
