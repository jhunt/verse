package Verse::Object::Page;

use Verse;
use Verse::Utils;
use base Verse::Object::Base;

sub type { 'page' }
sub path { 'pages' }

sub parse
{
	my ($class, $yaml) = @_;

	my ($self, $body) = $class->SUPER::parse($yaml);
	return unless $self;

	if ($self->format eq 'markdown') {
		$body = markdown($body, verse);
	}

	$self->{__attrs}{body} = $body;

	return $self;
}

sub uuid { $_[0]->{__attrs}{url} }

1;

=head1 NAME

Verse::Object::Page - Page Support for Verse

=head1 OVERRIDDEN METHODS

=head2 type()

=head2 path()

=head2 parse($yaml)

=head2 uuid()

=head1 AUTHOR

James Hunt C<< <james@niftylogic.com> >>

=cut
