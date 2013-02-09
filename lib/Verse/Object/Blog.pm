package Verse::Object::Blog;

use Verse;
use Verse::Utils;
use base Verse::Object::Base;

########################################

sub read_all {
	my ($class) = @_;
	$class->read_all(verse->{paths}{data}.'/blog');
}

sub read
{
	my ($class, $path) = @_;

	my ($self, $teaser, $body) = $class->SUPER::read($path);
	return unless $self;

	if ($self->{__attrs}{format} eq 'markdown') {
		$teaser = markdown($teaser, verse);
		$body   = markdown($body,   verse) if $body;
	}
	$body = $teaser unless $body;

	return $self;
}

########################################

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

sub vars
{
	my ($self) = @_;
	return {
		article => $self,
	};
}

sub permalink
{
	my ($self) = @_;
	return $self->{perma};
}

1;
