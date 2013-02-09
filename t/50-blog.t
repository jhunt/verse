#!perl
use strict;
use warnings;
use Test::More;
use Test::Deep;

BEGIN { use_ok 'Verse::Object::Blog'
		or BAIL_OUT "Could not `use Verse::Object::Blog`" }

{ # read fails
	my $Blog = 'Verse::Object::Blog';

	ok(-f "t/data/blog.yml" and -r "t/data/blog.yml",
		"[sanity] t/data/blog.yml should be a readable file");
	isa_ok($Blog->read("t/data/blog.yml"),
		$Blog, "Blog->read");

}

done_testing;
