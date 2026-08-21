package Test::Deep;

use strict;
use warnings;
use Test::More;
use Data::Dumper;

use base 'Exporter';
our @EXPORT = qw(
	cmp_deeply
	cmp_set
	cmp_bag
	ignore
	re
	superhashof
	subhashof
	set
	bag
	array_each
);

# Simple deep comparison - not as sophisticated as real Test::Deep
# but sufficient for basic testing
sub cmp_deeply {
	my ($got, $expected, $name) = @_;

	local $Data::Dumper::Sortkeys = 1;
	local $Data::Dumper::Terse = 1;
	local $Data::Dumper::Indent = 0;

	my $got_dump = Dumper($got);
	my $expected_dump = Dumper($expected);

	return is($got_dump, $expected_dump, $name);
}

# Compare sets (unordered arrays)
sub cmp_set {
	my ($got, $expected, $name) = @_;

	return fail($name) unless ref($got) eq 'ARRAY' && ref($expected) eq 'ARRAY';
	return fail($name) unless @$got == @$expected;

	my %got_items = map { $_ => 1 } @$got;
	my %expected_items = map { $_ => 1 } @$expected;

	for my $item (@$expected) {
		unless (exists $got_items{$item}) {
			return fail($name);
		}
	}

	for my $item (@$got) {
		unless (exists $expected_items{$item}) {
			return fail($name);
		}
	}

	return pass($name);
}

# Stub functions - not implemented but prevent errors
sub cmp_bag { goto &cmp_set; }
sub ignore { return bless {}, 'Test::Deep::Ignore'; }
sub re { my $re = shift; return bless { re => $re }, 'Test::Deep::Regexp'; }
sub superhashof { my $hash = shift; return bless { hash => $hash }, 'Test::Deep::SuperHash'; }
sub subhashof { my $hash = shift; return bless { hash => $hash }, 'Test::Deep::SubHash'; }
sub set { return [@_]; }
sub bag { return [@_]; }
sub array_each { my $check = shift; return bless { check => $check }, 'Test::Deep::ArrayEach'; }

1;

__END__

=head1 NAME

Test::Deep - Minimal stub for Test::Deep

=head1 DESCRIPTION

This is a minimal implementation of Test::Deep for basic testing.
It is not a complete replacement but provides enough functionality
for Verse's test suite to run.

=cut
