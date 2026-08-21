package Verse::Object::Base;

use strict;
use warnings;

use Carp;
use Verse;
use Verse::Utils;

use File::Find qw/find/;
use YAML qw/Load Dump/;
use Time::ParseDate qw/parsedate/;
use POSIX qw/strftime/;

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

	# Untaint file path for -T mode (allow reasonable file paths)
	my $untainted_file = $file;
	if ($file =~ m{^([-\@\w./]+)$}) {
		$untainted_file = $1;
	} else {
		croak "Unsafe file path: $file\n";
	}

	open my $fh, "<:encoding(UTF-8)", $untainted_file
		or croak "Failed to open $untainted_file: $!\n";
	my ($self, @rest) = $class->parse(do { local $/; <$fh> });
	close $fh;

	$self->{__file} = $untainted_file;
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

sub replacements { $_[0]->{__attrs}{replace} }

my $UUID = 1;
sub uuid
{
	my ($self) = @_;
	$self->{__permalink} = $UUID++ unless $self->{__permalink};
	return $self->{__permalink};
}

########################################
# Meta Tag Helper Methods

sub meta_title
{
	my ($self) = @_;

	# Try content title first
	my $title = $self->attrs->{title};
	return "$title - ".verse->{site}{title} if $title;

	# Fall back to site title
	return verse->{site}{title};
}

sub meta_description
{
	my ($self) = @_;

	# Check explicit meta description
	return $self->attrs->{meta}{description}
		if $self->attrs->{meta} && $self->attrs->{meta}{description};

	# Try abstract/summary
	return $self->attrs->{abstract} if $self->attrs->{abstract};
	return $self->attrs->{summary} if $self->attrs->{summary};

	# For blog posts, try teaser
	return $self->attrs->{teaser} if $self->attrs->{teaser};

	# Fall back to site default
	return verse->{site}{meta}{default_description}
		if verse->{site}{meta} && verse->{site}{meta}{default_description};

	return undef;
}

sub meta_image
{
	my ($self) = @_;

	# Check explicit meta image
	return $self->attrs->{meta}{image}
		if $self->attrs->{meta} && $self->attrs->{meta}{image};

	# Try thumb/cover/featured_image
	return $self->attrs->{thumb} if $self->attrs->{thumb};
	return $self->attrs->{cover} if $self->attrs->{cover};
	return $self->attrs->{featured_image} if $self->attrs->{featured_image};

	# Fall back to site default
	return verse->{site}{meta}{default_image}
		if verse->{site}{meta} && verse->{site}{meta}{default_image};

	return undef;
}

sub meta_url
{
	my ($self, $path) = @_;

	my $canon = verse->{site}{canon} || '';
	$canon =~ s{/$}{};  # Remove trailing slash

	return "$canon$path";
}

sub meta_type
{
	my ($self) = @_;

	# Check explicit type
	return $self->attrs->{meta}{type}
		if $self->attrs->{meta} && $self->attrs->{meta}{type};

	# Default based on content type
	return 'article' if $self->type eq 'article';
	return 'website';
}

sub meta_author
{
	my ($self) = @_;

	# Check content author
	return $self->attrs->{author} if $self->attrs->{author};

	# Fall back to site author
	return verse->{site}{author};
}

sub meta_published_time
{
	my ($self) = @_;

	return undef unless $self->dated;
	return strftime('%Y-%m-%dT%H:%M:%S+00:00', gmtime($self->dated));
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

=head2 replacements()

Hashref of text substitutions.

=head2 uuid()

Returns a globally unique identifier for this object, used in
URIs.  By default, a unique number will be returned.  This method
can (and should) be overridden by sub-classes to provide more
appropriate, type-specific behavior.

=head2 meta_title()

Returns a title suitable for meta tags. Uses content title with
site title appended, or just site title if no content title.

=head2 meta_description()

Returns a description suitable for meta tags. Tries in order:
explicit meta.description, abstract, summary, teaser, site default.

=head2 meta_image()

Returns an image URL suitable for meta tags. Tries in order:
explicit meta.image, thumb, cover, featured_image, site default.

=head2 meta_url($path)

Returns a canonical URL for the given path, using the site's
canonical domain.

=head2 meta_type()

Returns an Open Graph type string. Returns 'article' for blog
posts, 'website' otherwise, unless explicitly overridden.

=head2 meta_author()

Returns the author name, from content or site default.

=head2 meta_published_time()

Returns ISO 8601 formatted publication time for articles with
a 'dated' attribute.

=head1 AUTHOR

James Hunt C<< <james@niftylogic.com> >>

=cut
