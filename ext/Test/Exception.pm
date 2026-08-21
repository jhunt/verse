package Test::Exception;

use strict;
use warnings;
use Test::More;

our $VERSION = '0.43';

use base 'Exporter';
our @EXPORT = qw(
	dies_ok
	lives_ok
	throws_ok
	lives_and
);

sub dies_ok(&;$) {
	my ($code, $name) = @_;
	$name ||= 'died as expected';

	eval { $code->() };
	my $error = $@;

	return ok($error, $name);
}

sub lives_ok(&;$) {
	my ($code, $name) = @_;
	$name ||= 'lived as expected';

	eval { $code->() };
	my $error = $@;

	return ok(!$error, $name) || diag("died with: $error");
}

sub throws_ok(&$;$) {
	my ($code, $expected, $name) = @_;
	$name ||= 'threw expected exception';

	eval { $code->() };
	my $error = $@;

	if (ref($expected) eq 'Regexp') {
		return like($error, $expected, $name);
	} else {
		return like($error, qr/\Q$expected\E/, $name);
	}
}

sub lives_and(&;$) {
	my ($code, $name) = @_;
	$name ||= 'lived and passed';

	eval { $code->() };
	my $error = $@;

	return ok(!$error, $name) || diag("died with: $error");
}

1;

__END__

=head1 NAME

Test::Exception - Minimal stub for Test::Exception

=head1 DESCRIPTION

This is a minimal implementation of Test::Exception for basic testing.

=cut
