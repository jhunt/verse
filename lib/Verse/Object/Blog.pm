package Verse::Object::Blog;

use Verse;
use Verse::Utils;
use base Verse::Object::Base;

sub type { 'article' }
sub path { 'blog' }

sub parse
{
	my ($class, $yaml) = @_;

	my ($self, $teaser, $body) = $class->SUPER::parse($yaml);
	return unless $self;

	if ($self->format eq 'markdown') {
		$teaser = markdown($teaser, verse);
		$body   = markdown($body,   verse) if $body;
	}
	$body = $teaser unless $body;
	$self->{__attrs}{teaser} = $teaser;
	$self->{__attrs}{body}   = $body;

	return $self;
}

sub slice
{
	my ($class, $offset, $limit) = @_;
	return grep { $_ }
		(sort { $b->{__dated} cmp $a->{__dated} }
		$class->read_all)[$offset .. $offset+$limit-1];
}

sub recent
{
	my ($class, $n) = @_;
	$class->slice(0, $n);
}

########################################

sub uuid { $_[0]->{__attrs}{permalink} }

1;

=head1 NAME

Verse::Object::Blog - Blog Article Support for Verse

=head1 METHODS

=head2 slice($offset, $limit)

Retrieve a slice of the reverse-chronological article history.

=head2 recent($n)

Retrieve the most recent B<$n> articles.

=head1 OVERRIDDEN METHODS

=head2 type()

=head2 path()

=head2 parse($yaml)

=head2 uuid()

=head1 AUTHOR

James Hunt C<< <james@niftylogic.com> >>

=cut
