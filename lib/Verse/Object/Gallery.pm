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

=head1 NAME

Verse::Object::Gallery - Gallery Support for Verse

=head1 METHODS

=head2 pieces()

Retrieve an augmented list of the pieces in the Gallery.

=head2 OVERRIDDEN METHODS

=head2 type()

=head2 path()

=head1 AUTHOR

James Hunt C<< <james@niftylogic.com> >>

=cut
