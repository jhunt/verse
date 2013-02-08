#!perl
use strict;
use warnings;
use Test::More;

BEGIN { use_ok 'Verse::Utils' or BAIL_OUT "Could not `use Verse::Utils`" }

plan skip_all => "Markdown is not installed"
	unless -x '/usr/bin/markdown';

is(markdown("__test__"), "<p><strong>test</strong></p>",
	"markdown works");
is(markdown("  __test__\n"), "<p><strong>test</strong></p>",
	"markdown ignores trailing/leading whitespace");

done_testing;
