package Verse::Utils;

use base 'Exporter';
our @EXPORT = qw/
	markdown
/;

use File::Temp qw/tempfile/;

sub markdown
{
	my ($code, $config) = @_;

	my ($fh, $file) = tempfile;
	binmode($fh, ":utf8");
	print $fh $code; close $fh;
	$code = qx(/usr/bin/markdown --html4tags <$file);
	unlink $file;

	$code =~ s/^\s+//;
	$code =~ s/\s+$//;
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

=head2 markdown($code, \%config)

Render B<$code> as Markdown into HTML.  We go above and beyond stock
markdown by munging relative SRC and HREF attributes in the generated
HTML so that they are absolute, according to B<$config->{site}{url}>

This requires markdown (I</usr/bin/markdown>).

=head1 AUTHOR

James Hunt, C<< <james at niftylogic.com> >>

=cut
