#!perl
use strict;
use warnings;
use Test::More;
use Test::Deep;

BEGIN { use_ok 'Verse'
		or BAIL_OUT "Could not `use Verse`" }
BEGIN { use_ok 'Verse::Object::Gallery'
		or BAIL_OUT "Could not `use Verse::Object::Gallery`" }

my $Gallery = 'Verse::Object::Gallery';

{
	is($Gallery->type, 'gallery', 'Gallery type is correct');
	is($Gallery->path, 'gallery', 'Gallery path is correct');
}

{ # parse
	$Verse::ROOT = 't/data/root/good';

	my $gallery = $Gallery->parse(<<EOF);
title: Folio
path:  gallery/folio
statement: |-
  para 1

  para 2
pieces:
  - file: image1
    details: oil on canvas, 18x24
  - file: image2.jpg
    details: oil on hardboard, 3x5
EOF
	is($gallery->type, 'gallery', 'Gallery type is correct');
	is($gallery->attrs->{title}, 'Folio', 'Gallery title is correct');
	is($gallery->attrs->{path},  'gallery/folio', 'Gallery path is correct');
	like($gallery->attrs->{statement}, qr{<p>para 1</p>.*<p>para 2</p>}s,
		"Formatted the artist's statement");
	cmp_deeply($gallery->pieces, [
			{
				file      => 'image1',
				details   => 'oil on canvas, 18x24',
				image     => 'gallery/folio/image1.full.jpg',
				thumbnail => 'gallery/folio/image1.t.jpg',
			},
			{
				file      => 'image2',
				details   => 'oil on hardboard, 3x5',
				image     => 'gallery/folio/image2.full.jpg',
				thumbnail => 'gallery/folio/image2.t.jpg',
			},
		], 'Gallery pieces retrieved in-order');
}

done_testing;
