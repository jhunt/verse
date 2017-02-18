package Verse::Object::Gallery;

use Storable qw/dclone/;
use Verse;
use Verse::Utils;
use base Verse::Object::Base;

sub type { 'gallery' }
sub path { 'gallery' }

sub parse
{
	my ($class, $yaml) = @_;
	my ($self) = $class->SUPER::parse($yaml);
	return unless $self;

	if (my $stmt = $self->{__attrs}{statement}) {
		$self->{__attrs}{statement} = markdown($stmt, $self->replacements, verse);
	}

	return $self;
}

sub pieces
{
	my ($self) = @_;
	my $path = $self->attrs->{path};

	my @lst = map {
		my $o = dclone($_);
		$o->{file} =~ s/\.jpg$//i;
		$o->{thumbnail} = "$path/$o->{file}.t.jpg";
		$o->{image}     = "$path/$o->{file}.full.jpg";
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

=head2 parse($yaml)

=head1 AUTHOR

James Hunt C<< <james@niftylogic.com> >>

=cut
