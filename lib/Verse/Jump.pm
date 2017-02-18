package Verse::Jump;

use strict;
use warnings;
use YAML::Old qw/LoadFile/;

sub read
{
	my ($class, $file) = @_;
	die "No jump file specified\n" unless $file;
	die "$file: $!\n" unless -f $file;
	bless({
			data => LoadFile($file),
		}, $class);
}

sub resolve
{
	my ($self, $uri) = @_;
	for (keys %{ $self->{data} }) {
		my $target = $self->{data}{$_};
		next if $target =~ m{^https?://};
		next if $target =~ m{^ftps?://};
		next if $target =~ m{^mailto:};

		$uri =~ s|/+$||;
		$target = "/$target" unless substr($target, 0, 1) eq '/';
		$self->{data}{$_} = "$uri$target";
	}

	$self;
}

sub pairs
{
	my ($self) = @_;
	map { [ $_, $self->{data}{$_} ] } sort keys %{ $self->{data} };
}

1;

=head1 NAME

Verse::Jump - Redirection / Jump Page Management

=head1 DESCRIPTION

Jump Pages are small HTTP endpoints that exist to track a visitor
(via standard web server access/request logs) and then redirect
them to their finl destination.  These can be useful for tracking
the effectiveness of online marketing, as well as determinine
where viewers are coming from.

=head1 METHODS

=head2 read($file)

Reads the jump.yml file, which is a YAML file containining a
single-level hash that maps relative paths to URI destinations
(either on-site relative, or off-site).

=head2 resolve($uri)

Resolves relative destination targets as absolute, using $uri as
the base URI.

=head2 pairs()

Returns a list of arrayref pairs, where the first element of each
arrayref is the local URI, and the second element is the resolved
target/destination.  This is designed to be easily used from a for
loop or map/grep-style operator.

=head1 AUTHOR

James Hunt, C<< <james at niftylogic.com> >>

=cut
