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

	if ($self->{__attrs}{format} and $self->{__attrs}{format} eq 'markdown') {
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
	return (sort { $b->{__date} cmp $a->{__date} }
		$class->read_all)[$offset .. $limit-$offset-1];
}

sub recent
{
	my ($class, $n) = @_;
	$class->slice(0, $n);
}

########################################

sub uuid { $_[0]->{__attrs}{permalink} }

1;
