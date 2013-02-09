package Verse::Object::Gallery;

use Storable qw/dclone/;
use Verse;
use Verse::Utils;
use base Verse::Object::Base;

sub type { 'gallery' }
sub path { 'gallery' }

sub pieces
{
	my ($self) = @_;
	my $path = $self->attrs->{path};

	my @lst = map {
		my $o = dclone($_);
		$o->{thumbnail} = "$path/$o->{name}.t.jpg";
		$o->{image}     = "$path/$o->{name}.full.jpg";
		$o;
	} @{$self->attrs->{pieces}};
	return \@lst;
}

1;
