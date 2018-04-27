#!perl
use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Exception;
use lib 'lib';
use lib 'ext';

BEGIN { use_ok 'Verse::Jump' or BAIL_OUT "Could not `use Verse::Jump`" }

{ # constructor
	throws_ok { Verse::Jump->read() }
		qr/no jump file specified/i,
		"No jump file specified";
	throws_ok { Verse::Jump->read("/no/such/file") }
		qr{/no/such/file: No such file or directory}i,
		"Non-existent jump file";

	lives_ok { Verse::Jump->read("t/data/jump.yml") }
		"Read a valid jump file";
}

{ # resolve
	my $j = Verse::Jump->read("t/data/jump.yml");
	ok $j->resolve("file:///x"), "Resolved jump file ok";
	cmp_deeply($j->{data}, {
			path1   => 'http://www.example.com/path1',
			path2   => 'http://www.example.com/path2',
			hello   => 'file:///x/about',
			hello2  => 'file:///x/about.html',
			html    => 'file:///x/http-is-fun.html',
			'a/b/c' => "file:///x/abc.html",
		}, "Data resolved as expected");

	cmp_deeply([$j->pairs], [
			[ 'a/b/c',  "file:///x/abc.html"],
			[ 'hello',  'file:///x/about'],
			[ 'hello2', 'file:///x/about.html'],
			[ 'html',   'file:///x/http-is-fun.html'],
			[ 'path1', 'http://www.example.com/path1'],
			[ 'path2', 'http://www.example.com/path2'],
		], "Pairs returned in sorted order");
}

done_testing;
