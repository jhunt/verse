#!perl
use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Verse' or BAIL_OUT "Failed to `use Verse`" }

{ # qualify_path
	my $PWD = $ENV{PWD};
	is(Verse::qualify_path("a/path/to/stuff"),
		"$PWD/a/path/to/stuff",
		"Qualify paths per current working directory");

	is(Verse::qualify_path(undef),
		undef, "qualify(undef) yields undef");
	is(Verse::qualify_path(''),
		undef, "qualify('') yields undef");

	is(Verse::qualify_path('/etc/passwd'),
		'/etc/passwd',
		"Qualifying absolute paths is a no-op");
}

done_testing;
