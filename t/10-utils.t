#!perl
use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Verse::Utils' or BAIL_OUT "Could not `use Verse::Utils`" }

{ # vpath
	my $PWD = $Verse::ROOT;
	is(vpath("a/path/to/stuff"),
		"$PWD/a/path/to/stuff",
		"Qualify paths per current working directory");

	is(vpath(undef),
		undef, "qualify(undef) yields undef");
	is(vpath(''),
		undef, "qualify('') yields undef");

	is(vpath('/etc/passwd'),
		'/etc/passwd',
		"Qualifying absolute paths is a no-op");

	local $Verse::ROOT = "/some/root";
	is(vpath("some/where"),
		"/some/root/some/where",
		"vpath honors Verse::ROOT changes");
}

done_testing;
