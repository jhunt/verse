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
