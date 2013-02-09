package Verse::Object::Base;

use Verse::Utils;

use File::Find qw/find/;
use YAML qw/LoadFile Dump/;
use Time::ParseDate qw/parsedate/;

sub type { 'object' }

########################################

sub read
{
	my ($class, $path) = @_;
	return unless -r $path and -f $path;

	my ($attrs, @rest) = LoadFile($path);
	my $self = bless({
		__attrs => $attrs,
		__path  => $path
	}, $class);

	if (exists $attrs->{dated}) {
		$self->{__dated} = parsedate($attrs->{dated},
			NO_RELATIVE => 1);
	}

	return wantarray ? ($self, @rest) : $self;
}

sub dated { $_[0]->{__dated} }
sub path  { $_[0]->{__path}  }
sub attrs { $_[0]->{__attrs} }

sub vars {
	my ($self) = @_;
	return { $self->type => $self->attrs };
}

my $UUID = 1;
sub uuid
{
	my ($self) = @_;
	$self->{__permalink} = $UUID++ unless $self->{__permalink};
	return $self->{__permalink};
}

########################################

sub read_all
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

1;

=head1 NAME

Verse::Object::Base - Object Base Class

=head1 DESCRIPTION

Provides common functionality for all Verse object types.

=head1 CLASS METHODS

=head2 read($path)

Read an object definition from YAML file at $path.

=head2 read_all($path)

Find all *.yml files under $path, and read them in.

=head1 INSTANCE METHODS

=head2 type()

Type of object.  Should be overridden by sub-classes.

=head2 dated()

Epoch timestamp parsed from the 'dated' attribute.

=head2 path()

Path that the object was originally read from.

=head2 attrs()

Hashref of raw object attributes.

=head2 vars()

Hashref of object attributes, properly wrapped in a subkey, for
use in rendered templates.  This method can be overridden by
sub-classes.

=head2 uuid()

Returns a globally unique identifier for this object, used in
URIs.  By default, a unique number will be returned.  This method
can (and should) be overridden by sub-classes to provide more
appropriate, type-specific behavior.

=head1 AUTHOR

James Hunt C<< <james@niftylogic.com> >>

=cut
