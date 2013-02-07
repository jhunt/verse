#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Verse' ) || print "Bail out!\n";
}

diag( "Testing Verse $Verse::VERSION, Perl $], $^X" );
