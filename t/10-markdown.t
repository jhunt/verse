#!perl
use strict;
use warnings;
use Test::More;
use lib 'lib';
use lib 'ext';

use_ok 'Verse::Utils' or BAIL_OUT "Could not `use Verse::Utils`";

my $config = {
	site => {
		url => 'http://www.example.com'
	}
};

is(markdown("__test__", $config), "<p><strong>test</strong></p>",
	"markdown works");
is(markdown("  __test__\n", $config), "<p><strong>test</strong></p>",
	"markdown ignores trailing/leading whitespace");

# comments
is(markdown("a single\n// commented\nline\n", $config),
   markdown("a single\nline\n", $config),
   "markdown ignores Verse comments");

is(markdown("line 1\n\n// comment\n// again\n\nline 2\n", $config),
   markdown("line 1\n\nline 2\n", $config),
   "markdown ignores comment paragraphs");

is(markdown("    // formatted comments are ok\n", $config),
   "<pre><code>// formatted comments are ok\n</code></pre>",
   "markdown allows formatted comment-like productions");

is(markdown("paragraph // with a comment\n", $config),
   markdown("paragraph\n", $config),
   "markdown strips comments from the end of lines");

# unicode
is(markdown("∑ (sigma)", $config),
   "<p>∑ (sigma)</p>",
   "markdown handles unicode reliably");

done_testing;
