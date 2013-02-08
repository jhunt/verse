package Verse::Object::Page;

use Verse;
use Verse::Utils;
use base 'Verse::Object::Base';

########################################

sub read_all {
	my ($class) = @_;
	$class->read_all_from(verse->{paths}{data}.'/page');
}

sub read
{
	my ($class, $path) = @_;

	my ($attrs, $body) = $class->read_from($path);

	$attrs->{body} = $body;

	if ($attrs->{format} eq 'markdown') {
		$attrs->{body} = markdown($attrs->{body}, verse);
	}

	bless($attrs, $class);
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
	return $self->{path}
}

1;
