package Verse::Object::Base;

use strict;
use warnings;

use Carp;
use Verse;
use Verse::Utils;

use File::Find qw/find/;
use YAML qw/Load Dump/;
use Time::ParseDate qw/parsedate/;

sub type { 'object' }
sub path { 'misc' }

########################################

sub parse
{
	my ($class, $yaml) = @_;

	my ($attrs, @rest) = Load($yaml);
	my $self = bless({
		__attrs => $attrs,
	}, $class);

	if (exists $attrs->{dated}) {
		$self->{__dated} = parsedate($attrs->{dated},
			NO_RELATIVE => 1);
	}

	$self->{__format} = 'plain';
	if (exists $attrs->{format}) {
		$self->{__format} = $attrs->{format};
	}

	return wantarray ? ($self, @rest) : $self;
}
sub read
{
	my ($class, $file) = @_;
	return unless -r $file and -f $file;

	open my $fh, "<", $file
		or croak "Failed to read $file: $!\n";
	my ($self, @rest) = $class->parse(do { local $/; <$fh> });
	close $fh;

	$self->{__file} = $file;
	return wantarray ? ($self, @rest) : $self;
}

sub read_all
{
	my ($class, $dir) = @_;
	$dir = verse->{paths}{data}.'/'.$class->path unless $dir;
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

sub dated  { $_[0]->{__dated}  }
sub file   { $_[0]->{__file}   }
sub format { $_[0]->{__format} }
sub attrs  { $_[0]->{__attrs}  }

my $UUID = 1;
sub uuid
{
	my ($self) = @_;
	$self->{__permalink} = $UUID++ unless $self->{__permalink};
	return $self->{__permalink};
}

1;

=head1 NAME

Verse::Object::Base - Object Base Class

=head1 DESCRIPTION

Provides common functionality for all Verse object types.

=head1 CLASS METHODS

=head2 parse($yaml)

Parse an object definition from a literal YAML string.

=head2 read($file)

Read an object definition from YAML file at $file.

=head2 read_all($path)

Find all *.yml files under $path, and read them in.

=head1 INSTANCE METHODS

=head2 type()

Type of object.  Should be overridden by sub-classes.

=head2 path()

Path to the area where these objects are stored, relative to
the Verse data directory (usually .verse/data).

=head2 dated()

Epoch timestamp parsed from the 'dated' attribute.

=head2 file()

Path that the object was originally read from.

=head2 format()

The format requested by the object.  Defaults to 'plain'.

=head2 attrs()

Hashref of raw object attributes.

=head2 uuid()

Returns a globally unique identifier for this object, used in
URIs.  By default, a unique number will be returned.  This method
can (and should) be overridden by sub-classes to provide more
appropriate, type-specific behavior.

=head1 AUTHOR

James Hunt C<< <james@niftylogic.com> >>

=cut
