package Verse::Object::Blog;

use Verse;
use Verse::Utils;
use base Verse::Object::Base;

########################################

sub read_all {
	my ($class) = @_;
	$class->read_all_from(verse->{paths}{data}.'/blog');
}

sub read
{
	my ($class, $path) = @_;

	my ($attrs, $teaser, $body) = $class->read_from($path);

	$attrs->{teaser} = $teaser;
	$attrs->{body}   = $body || $teaser;

	if ($attrs->{format} eq 'markdown') {
		$attrs->{teaser} = markdown($attrs->{teaser}, verse);
		$attrs->{body} = markdown($attrs->{body}, verse);
	}

	bless($attrs, $class);
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
