package Verse::Utils;

use Verse::Markdown;
use Clone qw/clone/;
use base 'Exporter';
our @EXPORT = qw/
	vpath
	markdown
	merge
	slurp
/;

use Verse;

sub vpath
{
	my ($path) = @_;
	return unless $path;
	return $path if substr($path, 0, 1) eq '/';
	return "$Verse::ROOT/$path";
}

sub markdown
{
	my ($code, $replace, $config) = @_;

	# drop the comments
	$code =~ s|^//.*\n||gm;
	$code =~ s|(\S)\s+//.*|$1|g;

	for my $search (keys %{$replace || {}}) {
		$code =~ s/$search/$replace->{$search}/g;
	}

	$code = Verse::Markdown::format($code);
	$code =~ s/(href|src)=(["']?)\//$1=$2$config->{site}{url}\//g;
	return $code;
}

my %_merge = (
	SCALAR => {
		SCALAR => sub { $_[0] },
		ARRAY  => sub { $_[0] },
		HASH   => sub { $_[0] },
	},
	ARRAY => {
		SCALAR => sub { [ @{$_[0]},          $_[1]  ] },
		ARRAY  => sub { [ @{$_[0]},        @{$_[1]} ] },
		SCALAR => sub { [ @{$_[0]}, values %{$_[1]} ] },
	},
	HASH => {
		SCALAR => sub { $_[0] },
		ARRAY  => sub { $_[0] },
		HASH   => sub {
			my ($l,$r) = @_;
			my %new;
			for my $k (keys %$l) {
				$new{$k} = exists $r->{$k} ? merge($l->{$k}, $r->{$k})
										   : clone($l->{$k});
			}
			for my $k (grep { ! exists $l->{$_} } keys %$r) {
				$new{$k} = clone($r->{$k});
			}
			return \%new;
		},
	},
);

sub merge
{
	my ($l, $r) = @_;

	my $lt = ref $l eq 'HASH'  ? 'HASH'
	       : ref $l eq 'ARRAY' ? 'ARRAY'
	       :                     'SCALAR';

	my $rt = ref $r eq 'HASH'  ? 'HASH'
	       : ref $l eq 'ARRAY' ? 'ARRAY'
	       :                     'SCALAR';

	return $_merge{$lt}{$rt}->($l,$r);
}

sub slurp
{
	my ($file) = @_;
	open my $fh, "<", $file
		or die $!;
	binmode $fh, ':utf8';
	my $s = do { local $/; <$fh> };
	close $fh;
	return $s;
}

1;

=head1 NAME

Verse::Utils - Internal Utilities used by Verse

=head1 DESCRIPTION

These are tools for implementing Verse.  They aren't terribly interesting
or useful to anyone but Verse hackers, but here is the documentation anyway.

=head1 FUNCTIONS

=head2 vpath($relpath)

Turn B<$relpath> into an absolute path, based on the current Verse
ROOT (which defaults to the current working directory).

If B<$relpath> is already absolute, vpath returns it unmodified.

=head2 markdown($code, \%config)

Render B<$code> as Markdown into HTML.  We go above and beyond stock
markdown by munging relative SRC and HREF attributes in the generated
HTML so that they are absolute, according to B<$config->{site}{url}>

This requires markdown (I</usr/bin/markdown>).

=head2 slurp($path)

Open a file (in utf-8 mode) and reads its contents into a string scalar,
which is then returned to the caller.  Failure to open or read from the file
results in a C<die>.

=head2 merge(\%a, \%b)

Merge two hashrefs together, preferring values in C<$a> over those in C<$b>,
and return the aggregated hashref.

=head1 AUTHOR

James Hunt, C<< <james at niftylogic.com> >>

=cut
