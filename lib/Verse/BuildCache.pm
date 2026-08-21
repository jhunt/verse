package Verse::BuildCache;

use strict;
use warnings;

use Digest::SHA qw/sha256_hex/;
use YAML qw/LoadFile DumpFile/;
use File::Path qw/make_path/;
use File::Basename qw/dirname/;

sub new
{
	my ($class) = @_;
	return bless({
		version   => 1,
		timestamp => time,
		files     => {},
		outputs   => {},
		changed   => [],
	}, $class);
}

sub load
{
	my ($class, $cache_file) = @_;

	# If cache file doesn't exist, return empty cache
	return $class->new unless -f $cache_file;

	# Try to load existing cache
	my $data = eval { LoadFile($cache_file) };
	return $class->new unless $data;

	# Validate version
	return $class->new unless $data->{version} && $data->{version} == 1;

	return bless({
		version   => $data->{version},
		timestamp => $data->{timestamp} || time,
		files     => $data->{files} || {},
		outputs   => $data->{outputs} || {},
		changed   => [],
	}, $class);
}

sub save
{
	my ($self, $cache_file) = @_;

	# Ensure cache directory exists
	my $dir = dirname($cache_file);
	make_path($dir) unless -d $dir;

	# Save cache
	DumpFile($cache_file, {
		version   => $self->{version},
		timestamp => time,
		files     => $self->{files},
		outputs   => $self->{outputs},
	});
}

sub hash_file
{
	my ($self, $path) = @_;

	return undef unless -f $path;

	open my $fh, '<', $path or return undef;
	binmode $fh;
	my $content = do { local $/; <$fh> };
	close $fh;

	return sha256_hex($content);
}

sub hash_content
{
	my ($self, $content) = @_;
	return sha256_hex($content);
}

sub is_file_changed
{
	my ($self, $path) = @_;

	# If file doesn't exist, it's changed
	return 1 unless -f $path;

	# Compute current hash
	my $current_hash = $self->hash_file($path);
	return 1 unless $current_hash;

	# Compare with cached hash
	my $cached = $self->{files}{$path};
	return 1 unless $cached && $cached->{hash};

	return $current_hash ne $cached->{hash};
}

sub record_file
{
	my ($self, $path) = @_;

	return unless -f $path;

	my $hash = $self->hash_file($path);
	$self->{files}{$path} = {
		hash  => $hash,
		mtime => (stat($path))[9],
	};

	# Track if this file changed
	push @{$self->{changed}}, $path if $self->is_file_changed($path);
}

sub needs_rebuild
{
	my ($self, $sources, $output) = @_;

	# If output doesn't exist, rebuild
	return 1 unless $output && -f $output;

	# Convert single source to array
	$sources = [$sources] unless ref($sources) eq 'ARRAY';

	# Check if any source file changed
	for my $source (@$sources) {
		next unless $source && -f $source;

		if ($self->is_file_changed($source)) {
			return 1;
		}
	}

	# Check if output itself is missing from cache
	return 1 unless $self->{outputs}{$output};

	# Check if any recorded source for this output changed
	my $cached_output = $self->{outputs}{$output};
	if ($cached_output->{sources}) {
		for my $source (@{$cached_output->{sources}}) {
			if ($self->is_file_changed($source)) {
				return 1;
			}
		}
	}

	# No rebuild needed
	return 0;
}

sub record_output
{
	my ($self, $output, @sources) = @_;

	return unless $output;

	my $hash = -f $output ? $self->hash_file($output) : undef;

	$self->{outputs}{$output} = {
		hash    => $hash,
		sources => [@sources],
	};

	# Record all source files
	for my $source (@sources) {
		$self->record_file($source) if $source && -f $source;
	}
}

sub get_changed_files
{
	my ($self) = @_;
	return @{$self->{changed}};
}

sub clear_changed
{
	my ($self) = @_;
	$self->{changed} = [];
}

1;

=head1 NAME

Verse::BuildCache - Incremental Build Cache for Verse

=head1 SYNOPSIS

    use Verse::BuildCache;

    # Load cache from previous build
    my $cache = Verse::BuildCache->load('.verse/build-cache.yml');

    # Check if rebuild needed
    if ($cache->needs_rebuild(['template.tt', 'content.yml'], 'output.html')) {
        # Rebuild...
        $cache->record_output('output.html', 'template.tt', 'content.yml');
    }

    # Save cache for next build
    $cache->save('.verse/build-cache.yml');

=head1 DESCRIPTION

Verse::BuildCache provides content hash-based incremental build support.
It tracks file hashes and dependencies to determine what needs rebuilding
when sources change.

=head1 METHODS

=head2 new()

Create a new empty build cache.

=head2 load($cache_file)

Load a build cache from a YAML file. Returns empty cache if file
doesn't exist or is invalid.

=head2 save($cache_file)

Save the build cache to a YAML file.

=head2 hash_file($path)

Compute SHA256 hash of a file's contents.

=head2 hash_content($content)

Compute SHA256 hash of a string.

=head2 is_file_changed($path)

Check if a file's content has changed since last build.

=head2 record_file($path)

Record a file's current hash in the cache.

=head2 needs_rebuild(\@sources, $output)

Check if an output file needs to be rebuilt based on its sources.
Returns true if:
- Output doesn't exist
- Any source file changed
- Output not in cache

=head2 record_output($output, @sources)

Record an output file and its source dependencies in the cache.

=head2 get_changed_files()

Get list of files that changed since last build.

=head2 clear_changed()

Clear the list of changed files.

=head1 CACHE FILE FORMAT

The cache is stored as YAML with the following structure:

    version: 1
    timestamp: 1693234567
    files:
      path/to/file.yml:
        hash: abc123...
        mtime: 1693234560
    outputs:
      htdocs/index.html:
        hash: def456...
        sources:
          - template.tt
          - content.yml

=head1 AUTHOR

Claude <claude@localhost>

=cut
