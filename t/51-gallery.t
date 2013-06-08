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
	my $gallery = $Gallery->parse(<<EOF);
title: Folio
path:  gallery/folio
pieces:
  - file: image1
    details: oil on canvas, 18x24
  - file: image2.jpg
    details: oil on hardboard, 3x5
EOF
	is($gallery->type, 'gallery', 'Gallery type is correct');
	is($gallery->attrs->{title}, 'Folio');
	is($gallery->attrs->{path},  'gallery/folio');
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
