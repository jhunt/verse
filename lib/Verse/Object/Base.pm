package Verse::Object::Base;

use Verse::Utils;

use File::Find qw/find/;
use YAML qw/LoadFile Dump/;
use Time::ParseDate qw/parsedate/;

########################################

my $UUID = 1;

sub permalink
{
	my ($self) = @_;
	$self->{__permalink} = $UUID++ unless $self->{__permalink};
	return $self->{__permalink};
}

sub vars
{
	my ($self) = @_;
	return $self->{attrs};
}

########################################

sub read_all_from
{
	my ($class, $dir) = @_;
	my @lst = ();
	find({
		no_chdir => 1,
		wanted   => sub {
			return unless m/\.yml$/;
			push @lst, $class->read($File::Find::name);
		},
	}, $dir);
	@lst;
}

sub read_from
{
	my ($self, $path) = @_;

	my ($attrs, @rest) = LoadFile($path);
	$attrs->{__path} = $path;

	if (exists $attrs->{posted}) {
		$attrs->{__date} = parsedate($attrs->{posted},
			NO_RELATIVE => 1);
	}

	return ($attrs, @rest);
}

1;
