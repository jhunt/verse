package Test::Output;

use strict;
use warnings;
use Test::More;

our $VERSION = '1.03';

use base 'Exporter';
our @EXPORT = qw(
	stdout_is
	stdout_isnt
	stdout_like
	stdout_unlike
	stderr_is
	stderr_isnt
	stderr_like
	stderr_unlike
	combined_is
	combined_isnt
	combined_like
	combined_unlike
	output_is
	output_isnt
	output_like
	output_unlike
);

sub _capture {
	my $code = shift;

	my ($stdout, $stderr) = ('', '');

	{
		local *STDOUT;
		local *STDERR;
		open(STDOUT, '>', \$stdout) or die "Can't redirect STDOUT: $!";
		open(STDERR, '>', \$stderr) or die "Can't redirect STDERR: $!";
		$code->();
	}

	return ($stdout, $stderr);
}

sub stdout_is(&$;$) {
	my ($code, $expected, $name) = @_;
	my ($stdout, $stderr) = _capture(sub { $code->() });
	return is($stdout, $expected, $name);
}

sub stdout_isnt(&$;$) {
	my ($code, $expected, $name) = @_;
	my ($stdout, $stderr) = _capture(sub { $code->() });
	return isnt($stdout, $expected, $name);
}

sub stdout_like(&$;$) {
	my ($code, $regex, $name) = @_;
	my ($stdout, $stderr) = _capture(sub { $code->() });
	return like($stdout, $regex, $name);
}

sub stdout_unlike(&$;$) {
	my ($code, $regex, $name) = @_;
	my ($stdout, $stderr) = _capture(sub { $code->() });
	return unlike($stdout, $regex, $name);
}

sub stderr_is(&$;$) {
	my ($code, $expected, $name) = @_;
	my ($stdout, $stderr) = _capture(sub { $code->() });
	return is($stderr, $expected, $name);
}

sub stderr_isnt(&$;$) {
	my ($code, $expected, $name) = @_;
	my ($stdout, $stderr) = _capture(sub { $code->() });
	return isnt($stderr, $expected, $name);
}

sub stderr_like(&$;$) {
	my ($code, $regex, $name) = @_;
	my ($stdout, $stderr) = _capture(sub { $code->() });
	return like($stderr, $regex, $name);
}

sub stderr_unlike(&$;$) {
	my ($code, $regex, $name) = @_;
	my ($stdout, $stderr) = _capture(sub { $code->() });
	return unlike($stderr, $regex, $name);
}

sub combined_is(&$;$) {
	my ($code, $expected, $name) = @_;
	my ($stdout, $stderr) = _capture(sub { $code->() });
	return is($stdout . $stderr, $expected, $name);
}

sub combined_isnt(&$;$) {
	my ($code, $expected, $name) = @_;
	my ($stdout, $stderr) = _capture(sub { $code->() });
	return isnt($stdout . $stderr, $expected, $name);
}

sub combined_like(&$;$) {
	my ($code, $regex, $name) = @_;
	my ($stdout, $stderr) = _capture(sub { $code->() });
	return like($stdout . $stderr, $regex, $name);
}

sub combined_unlike(&$;$) {
	my ($code, $regex, $name) = @_;
	my ($stdout, $stderr) = _capture(sub { $code->() });
	return unlike($stdout . $stderr, $regex, $name);
}

sub output_is(&$$;$) {
	my ($code, $expected_out, $expected_err, $name) = @_;
	my ($stdout, $stderr) = _capture(sub { $code->() });
	my $ok = 1;
	$ok &&= is($stdout, $expected_out, "$name (stdout)");
	$ok &&= is($stderr, $expected_err, "$name (stderr)");
	return $ok;
}

sub output_isnt(&$$;$) {
	my ($code, $expected_out, $expected_err, $name) = @_;
	my ($stdout, $stderr) = _capture(sub { $code->() });
	my $ok = 1;
	$ok &&= isnt($stdout, $expected_out, "$name (stdout)");
	$ok &&= isnt($stderr, $expected_err, "$name (stderr)");
	return $ok;
}

sub output_like(&$$;$) {
	my ($code, $regex_out, $regex_err, $name) = @_;
	my ($stdout, $stderr) = _capture(sub { $code->() });
	my $ok = 1;
	$ok &&= like($stdout, $regex_out, "$name (stdout)");
	$ok &&= like($stderr, $regex_err, "$name (stderr)");
	return $ok;
}

sub output_unlike(&$$;$) {
	my ($code, $regex_out, $regex_err, $name) = @_;
	my ($stdout, $stderr) = _capture(sub { $code->() });
	my $ok = 1;
	$ok &&= unlike($stdout, $regex_out, "$name (stdout)");
	$ok &&= unlike($stderr, $regex_err, "$name (stderr)");
	return $ok;
}

1;

__END__

=head1 NAME

Test::Output - Minimal stub for Test::Output

=head1 DESCRIPTION

This is a minimal implementation of Test::Output for basic testing.

=cut
