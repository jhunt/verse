#!perl
use strict;
use warnings;
use Test::More;
use Test::Deep;

BEGIN { use_ok 'Verse::Object::Base'
		or BAIL_OUT "Could not `use Verse::Object::Base`" }

my $Base = 'Verse::Object::Base';

{ # read
	ok(!-f "/no/such/file",
		"[sanity] /no/such/file should not exist");
	is($Base->read("/no/such/file"), undef,
		"read(<ENOENT>) yields undef");

	ok(-f "/etc/shadow",
		"[sanity] /etc/shadow should be a file");
	ok(!-r "/etc/shadow",
		"[sanity] /etc/shadow should be unreadable");
	is($Base->read("/etc/shadow"), undef,
		"read(<EPERM>) yields undef");

	ok(-d "t/data",
		"[sanity] t/data should be a directory");
	ok(-r "t/data",
		"[sanity] t/data should be readable");
	is($Base->read("t/data"), undef,
		"read(<ISDIR>) yields undef");

	ok(-f "t/data/base/simple.yml" and -r "t/data/base/simple.yml",
		"[sanity] t/data/base/simple.yml should be a readable file");
	my $obj = $Base->read("t/data/base/simple.yml");
	isa_ok($obj, $Base, "Base->read(<FILE>)");

	cmp_deeply($obj->attrs, {
			title  => 'An entry',
			author => 'jhunt',
			dated  => '11 Oct 2012 10:11:12 GMT',
		}, "Read attributes from YAML");

	is($obj->type, "object", "Type is correct");
	cmp_deeply($obj->vars, {
			object => $obj->attrs,
		}, "By default, vars == { type => attrs }");

	is($obj->dated, 1349950272,
		"Generated 'dated' meta-attribute");
	is($obj->path, "t/data/base/simple.yml",
		"Generated 'path' meta-attribute");

	my $id = $obj->uuid;
	ok($id, "Generated a UUID");
	is($obj->uuid, $id, "UUID is permanent");

	$obj = $Base->read("t/data/base/undated.yml");
	is($obj->dated, undef,
		"Object without 'dated' attribute has dated() == undef");
	ok($obj->uuid, "New object has a UUID");
	isnt($obj->uuid, $id, "Object UUID is different for 2nd object");
}

{ # multi-stream objects

	my @list = $Base->read("t/data/base/multi.yml");
	isa_ok($list[0], $Base, "First item of multi-stream");
	is($list[1], "a string",
		"Retrieved second item from multi-stream input");
}

{ # read-all
	my @all = $Base->read_all("t/data/base/all");
	is(scalar @all, 3, "Found three objects in t/data/base/all");
	cmp_deeply(
		[sort map { $_->attrs->{name} } @all],
		[qw[first second third]],
		"Found the correct objects");
}

done_testing;
