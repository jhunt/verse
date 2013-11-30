package Verse::Utils;

use Verse::Markdown;
use base 'Exporter';
our @EXPORT = qw/
	vpath
	markdown
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
	my ($code, $config) = @_;

	# drop the comments
	$code =~ s|^//.*\n||gm;
	$code =~ s|(\S)\s+//.*|$1|g;

	$code = Verse::Markdown::format($code);
	$code =~ s/(href|src)=(["']?)\//$1=$2$config->{site}{url}\//g;
	return $code;
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

=head1 AUTHOR

James Hunt, C<< <james at niftylogic.com> >>

=cut
