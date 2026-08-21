package File::Slurp;

use strict;
use warnings;
use Carp;

use base 'Exporter';
our @EXPORT = qw(read_file write_file);
our @EXPORT_OK = qw(read_file write_file slurp);

our $VERSION = '9999.99';

sub read_file {
	my ($file, %args) = @_;

	open my $fh, '<', $file
		or croak "Can't open $file: $!";

	if ($args{binmode}) {
		binmode $fh, $args{binmode};
	}

	my $content;
	if (wantarray) {
		my @lines = <$fh>;
		close $fh;
		return @lines;
	} else {
		local $/;
		$content = <$fh>;
		close $fh;
		return $content;
	}
}

sub write_file {
	my ($file, @data) = @_;

	open my $fh, '>', $file
		or croak "Can't open $file: $!";

	if (ref($data[0]) eq 'HASH') {
		my %args = %{shift @data};
		if ($args{binmode}) {
			binmode $fh, $args{binmode};
		}
	}

	print $fh @data;
	close $fh;
	return 1;
}

sub slurp {
	goto &read_file;
}

1;

__END__

=head1 NAME

File::Slurp - Minimal stub for File::Slurp

=head1 DESCRIPTION

This is a minimal implementation of File::Slurp for basic testing.

=cut
