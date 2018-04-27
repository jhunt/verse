#!perl
use strict;
use warnings;
use Test::More;
use Test::Deep;
use lib 'lib';
use lib 'ext';

BEGIN { use_ok 'Verse::Object::Base'
		or BAIL_OUT "Could not `use Verse::Object::Base`" }

my $Base = 'Verse::Object::Base';

{ # class types and methods
	is($Base->type, 'object', "Base object type");
	is($Base->path, 'misc', "Base object path");
}

{ # parse
	my $obj;

	$obj = $Base->parse(<<EOF);
title:  An entry
author: jhunt
dated:  11 Oct 2012 10:11:12 GMT
EOF
	isa_ok($obj, $Base, "Base->parse(YAML)");

	cmp_deeply($obj->attrs, {
			title  => 'An entry',
			author => 'jhunt',
			dated  => '11 Oct 2012 10:11:12 GMT',
		}, "Parsed attributes from YAML");

	is($obj->type, "object", "Type is correct");
	is($obj->dated, 1349950272,
		"Generated 'dated' meta-attribute");
	is($obj->format, 'plain',
		"Default format meta-attribute");

	my $id = $obj->uuid;
	ok($id, "Generated a UUID");
	is($obj->uuid, $id, "UUID is permanent");


	$obj = $Base->parse(<<EOF);
title: An entry
format: markdown
# no dated: key...
EOF
	is($obj->dated, undef,
		"Object without 'dated' attribute has dated() == undef");
	is($obj->format, 'markdown',
		"Object definition supplies own format");
	ok($obj->uuid, "New object has a UUID");
	isnt($obj->uuid, $id, "Object UUID is different for 2nd object");


	my @list = $Base->parse(<<EOF);
first: var
--- |-
a string
EOF
	isa_ok($list[0], $Base, "First item of multi-stream");
	is($list[1], "a string",
		"Retrieved second item from multi-stream input");
}

{ # read
	ok(!-f "/no/such/file",
		"[sanity] /no/such/file should not exist");
	is($Base->read("/no/such/file"), undef,
		"read(<ENOENT>) yields undef");

	my $secret = -f "/etc/shadow"        ? "/etc/shadow"         # linux
	           : -f "/etc/master.passwd" ? "/etc/master.passwd"  # darwin
	           :    BAIL_OUT "could not find an extant but unreadable file!";
	ok(-f $secret,
		"[sanity] $secret should be a file");
	ok(!-r $secret,
		"[sanity] $secret should be unreadable");
	is($Base->read($secret), undef,
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
	is($obj->dated, 1349950272,
		"Generated 'dated' meta-attribute");
	is($obj->file, "t/data/base/simple.yml",
		"Generated 'file' meta-attribute");
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
