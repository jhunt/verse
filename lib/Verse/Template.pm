package Verse::Template;
use strict;
use warnings;

use Verse::Utils;
use POSIX qw/strftime/;
use base 'Exporter';
our @EXPORT = qw/
	template
/;

sub template
{
	my ($templates, $vars, $outfile) = @_;
	$templates = [$templates] if ref($templates) ne 'ARRAY';

	for my $template (reverse @$templates) {
		$vars->{content} = _evaluate(_read($template), $vars);
		chomp($vars->{content});
	}
	return $vars->{content} if !$outfile;

	open my $fh, ">", $outfile
		or die "failed to open $outfile for writing: $!\n";
	binmode $fh, ':utf8';
	print $fh "$vars->{content}\n";
	close $fh;
	return 1;
}

use constant {
	T_ERR     => 254,
	T_EOT     => 255,
	T_TEXT    => 0,
	T_OPEN    => 1, # [[
	T_CLOSE   => 2, # ]]
	T_FOR     => 3, # for
	T_IN      => 4, # in
	T_END     => 5, # end
	T_IF      => 6, # if
	T_UNLESS  => 7, # unless
	T_ELSE    => 8, # else
	T_IDENT   => 9,,
	T_REGEX   => 10,
	T_STRING  => 11,
	T_NUMBER  => 12,
	T_NOT     => 13, # !, not
	T_AND     => 14, # &&, and
	T_OR      => 15, # ||, or
	T_OPAR    => 16, # (
	T_CPAR    => 17, # )
	T_EQ      => 18, # ==
	T_NE      => 19, # !=
	T_GT      => 20, # >
	T_GE      => 21, # >=
	T_LT      => 22, # <
	T_LE      => 23, # <=
	T_LIKE    => 24, # =~
	T_UNLIKE  => 25, # !~
	T_ASSIGN  => 26, # =
	T_ADD     => 27, # +
	T_SUB     => 28, # -
	T_MUL     => 29, # *
	T_DIV     => 30, # /
	T_FILTER  => 31, # filter
	T_COMMA   => 32, # "," delimiter
	T_FUNCALL => 33, # <IDENT>(
};

my @NAMES = (
	'(text block)',
	'opening "[["',
	'closing "%]"',
	'"for" keyword',
	'"in" keyword',
	'"end" keyword',
	'"if" keyword',
	'"unless" keyword',
	'"else" keyword',
	'variable name',
	'regular expression',
	'string',
	'number',
	'"not" / "!" keyword',
	'"&&" / "and" keyword',
	'"||" / "or" keyword',
	'opening "(" parenthesis',
	'closing ")" parenthesis',
	'equality "==" operator',
	'inequality "!=" operator',
	'greater than ">" operator',
	'greater than or equal to ">=" operator',
	'less than "<" operator',
	'less than or equal to "<=" operator',
	'pattern match "=~" operator',
	'pattern un-match "!~" operator',
	'assignment "=" operator',
	'"+" addition operator',
	'"-" subtraction operator',
	'"*" multiplication operator',
	'"/" division operator',
	'"filter" keyword',
	'"," argument delimiter',
	'function call',
);

my %FILTERS = (
	collapse => sub {
		my (undef, $in) = @_;
		$in =~ s/\s+/ /g;
		$in =~ s/^\s|\s$//g;
		return $in;
	},

	cdata => sub {
		return "<![CDATA[".$_[1]."]]>";
	},
);

my %FUNCS = (
	format => sub {
		my (undef, $fmt, @args) = @_;
		return sprintf($fmt, @args);
	},

	replace => sub {
		my (undef, $s, $search, $replace) = @_;
		$s =~ s/$search/$replace/g;
		return $s;
	},

	strftime => sub {
		my (undef, $ts, $fmt) = @_;
		return strftime($fmt, localtime($ts || 0));
	},
);

sub _lex
{
	# operates on the following hash ($_[0]):
	# {
	#    lit => 0,     # are we in literal mode?
	#    src => "...", # raw template source
	#    idx => 6,     # current index into src
	#    len => 42,    # length of src (cached for perf)
	# }

	my $i = $_[0]{idx};
	if ($i == $_[0]{len}) {
		return [T_EOT];
	}

	if ($_[0]{lit}) {
		for (; $i < $_[0]{len}; $i++) {
			if (substr($_[0]{src}, $i, 1) eq '[') {
				$i++;
				last if $i >= $_[0]{len};

				if (substr($_[0]{src}, $i, 1) eq '%') {
					my $lit = substr($_[0]{src}, $_[0]{idx}, $i - $_[0]{idx} - 1);

					if (substr($_[0]{src}, $i+1, 1) eq '-') {
						$i++;
						$lit =~ s/\s+$//;
					}
					$_[0]{idx} = $i + 1;
					$_[0]{lit} = 0;
					return $lit ? ([T_TEXT, $lit], [T_OPEN])
					            :                  [T_OPEN];
				}
			}
		}

		# ran out of template; return remainder as T_TEXT
		$i = $_[0]{idx};
		$_[0]{idx} = $_[0]{len};
		return [T_TEXT, substr($_[0]{src}, $i)];
	}

	# eat whitespace
	for (; $i < $_[0]{len} && substr($_[0]{src}, $i, 1) =~ m/^\s/; $i++) {}
	$_[0]{idx} = $i;
	return [T_EOT] if $i >= $_[0]{len};

	# look for tokens
	my $c = substr($_[0]{src}, $i, 1);

	if ($c eq ',') {
		$_[0]{idx} = ++$i;
		return [T_COMMA];

	} elsif ($c eq '(') {
		$_[0]{idx} = ++$i;
		return [T_OPAR];

	} elsif ($c eq ')') {
		$_[0]{idx} = ++$i;
		return [T_CPAR];

	} elsif ($c eq '%') {
		$i++;
		if (substr($_[0]{src}, $i, 1) eq ']') {
			$_[0]{idx} = ++$i;
			$_[0]{lit} = 1;
			return [T_CLOSE];
		}
		$i--;

	} elsif ($c =~ m/[><]/) {
		$i++;
		if ($i < $_[0]{len} && substr($_[0]{src}, $i, 1) eq '=') {
			$i++; $_[0]{idx} = $i;
			return [$c eq '<' ? T_LE : T_GE];
		}
		$_[0]{idx} = $i;
		return [$c eq '<' ? T_LT : T_GT];

	} elsif ($c eq '+') { $i++; $_[0]{idx} = $i; return [T_ADD];
	} elsif ($c eq '/') { $i++; $_[0]{idx} = $i; return [T_DIV];
	} elsif ($c eq '*') { $i++; $_[0]{idx} = $i; return [T_MUL];

	# '-' might be the start of '-%]'...
	} elsif ($c eq '-') {
		$i++; $c = substr($_[0]{src}, $i, 1);
		if ($c ne '%') {
			$_[0]{idx} = $i;
			return [T_SUB];
		}

		$i++; $c = substr($_[0]{src}, $i, 1);
		return [T_ERR, 'malformed -%] sequence encountered'] unless $c eq ']';

		# eat whitespace
		for ($i++; $i < $_[0]{len} && substr($_[0]{src}, $i, 1) =~ m/^\s/; $i++) {}
		$_[0]{idx} = $i;
		$_[0]{lit} = 1;
		return [T_CLOSE];

	} elsif ($c eq '=') {
		$i++;
		return [T_ERR, 'ran out of code to parse'] if $i >= $_[0]{len};

		$c = substr($_[0]{src}, $i, 1);
		$i++; $_[0]{idx} = $i;
		return [T_EQ]   if $c eq '=';
		return [T_LIKE] if $c eq '~';

		$i--; $_[0]{idx} = $i;
		return [T_ASSIGN];

	} elsif ($c eq '!') {
		$i++; $_[0]{idx} = $i;
		return [T_NOT] if $i >= $_[0]{len};

		$c = substr($_[0]{src}, $i, 1);
		$i++; $_[0]{idx} = $i;
		return [T_NE]     if $c eq '=';
		return [T_UNLIKE] if $c eq '~';
		$i--; $_[0]{idx} = $i;
		return [T_NOT];

	} elsif ($c eq '&') {
		# FIXME: there are inf. loop edge cases here...
		$i++;
		return [T_ERR, 'ran out of code to parse'] if $i >= $_[0]{len};

		$c = substr($_[0]{src}, $i, 1);
		$i++; $_[0]{idx} = $i;
		return [T_AND] if $c eq '&';
		return [T_ERR, 'unrecognized AND operator'];


	} elsif ($c eq '|') {
		$i++;
		return [T_ERR, 'ran out of code to parse'] if $i >= $_[0]{len};

		$c = substr($_[0]{src}, $i, 1);
		$i++; $_[0]{idx} = $i;
		return [T_OR] if $c eq '|';
		return [T_ERR, 'unrecognized OR operator'];

	} elsif ($c eq '"' || $c eq "'" || ($c eq 'm' && substr($_[0]{src}, $i+1, 1) eq '/')) {
		if ($c eq 'm') {
			$i++;
			$c = substr($_[0]{src}, $i, 1);
		}
		my $q = $c;
		my @chunks;
		my $esc = 0;
		$i++; $_[0]{idx} = $i;
		for (; $i < $_[0]{len}; $i++) {
			$c = substr($_[0]{src}, $i, 1);
			if ($c eq $q && !$esc) {
				push @chunks, substr($_[0]{src}, $_[0]{idx}, $i - $_[0]{idx});
				$_[0]{idx} = $i + 1;
				return [$q eq '/' ? T_REGEX : T_STRING, join('', @chunks)];
			}
			if ($esc) {
				$esc = 0;
				$_[0]{idx} = $i;
				next;
			}

			if ($c eq '\\') {
				push @chunks, substr($_[0]{src}, $_[0]{idx}, $i - $_[0]{idx});
				$esc = 1;
			}
		}
		return [T_ERR, 'unterminated string literal'];
	} elsif ($c =~ m/[a-zA-Z_]/) {
		for (; $i < $_[0]{len} && substr($_[0]{src}, $i, 1) =~ m/^[a-zA-Z0-9_.-]/; $i++) {}
		my $lexeme = substr($_[0]{src}, $_[0]{idx}, $i - $_[0]{idx});
		if (substr($_[0]{src}, $i, 1) eq '(') {
			$_[0]{idx} = ++$i;
			return [T_FUNCALL, $lexeme];
		}

		$_[0]{idx} = $i;
		return [T_FOR]     if lc($lexeme) eq 'for';
		return [T_IN]      if lc($lexeme) eq 'in';
		return [T_END]     if lc($lexeme) eq 'end';
		return [T_IF]      if lc($lexeme) eq 'if';
		return [T_UNLESS]  if lc($lexeme) eq 'unless';
		return [T_ELSE]    if lc($lexeme) eq 'else';
		return [T_NOT]     if lc($lexeme) eq 'not';
		return [T_AND]     if lc($lexeme) eq 'and';
		return [T_OR]      if lc($lexeme) eq 'or';
		return [T_FILTER]  if lc($lexeme) eq 'filter';
		return [T_IDENT, $lexeme];

	} elsif ($c =~ m/[0-9]/) {
		$i++;
		for (; $i < $_[0]{len} && substr($_[0]{src}, $i, 1) =~ m/[0-9.]/; $i++) {}
		my $lexeme = substr($_[0]{src}, $_[0]{idx}, $i - $_[0]{idx});
		$_[0]{idx} = $i;
		return [T_NUMBER, $lexeme];

	}

	return [T_ERR, 'unrecognized token ('.substr($_[0]{src}, $_[0]{idx}, 5).'...)'];
}

sub _tokenize
{
	my ($src) = @_;

	my @tok;
	my $lexer = {
		lit => 1,
		src => $src,
		idx => 0,
		len => length($src),
	};
	TOKEN:
	for (;;) {
		for my $t (_lex($lexer)) {
			_fail({ current => 'FIXME' }, $t->[1]) if $t->[0] == T_ERR;
			push @tok, $t;
			last TOKEN if $t->[0] == T_EOT;
		}
	}

	return \@tok;
}

sub _next
{
	$_[0]{token} = shift @{$_[0]{tokens}};
}

sub _at
{
	return $_[0]{token}[0] == $_[1];
}

sub _eat
{
	_unexpected($_[0], $_[2]) if !_at($_[0], $_[1]);
	_next($_[0]);
}

sub _argn
{
	return $_[0]{token}[$_[1]+1];
}

sub _i2pf
{
	my (%prec, @out, @ops);
	$prec{$_} = 5 for ((T_OPAR, T_CPAR));
	$prec{$_} = 4 for ((T_NOT));
	$prec{$_} = 3 for ((T_MUL, T_DIV));
	$prec{$_} = 2 for ((T_ADD, T_SUB));
	$prec{$_} = 1 for ((T_EQ, T_NE, T_LIKE, T_UNLIKE, T_GT, T_GE, T_LT, T_LE));
	$prec{$_} = 0 for ((T_AND, T_OR));

	my $nest = 0;
	for (;;) {
		if (_at($_[0], T_IDENT)
		 || _at($_[0], T_NUMBER)
		 || _at($_[0], T_REGEX)
		 || _at($_[0], T_STRING)) {
			push @out, $_[0]{token};
			_next($_[0]); next;
		}

		if (_at($_[0], T_OPAR)) {
			push @ops, $_[0]{token};
			$nest++; _next($_[0]); next;
		}
		if (_at($_[0], T_CPAR)) {
			last unless $nest;
			while (@ops && $ops[@ops - 1][0] != T_OPAR) {
				push @out, pop(@ops);
			}
			pop(@ops);
			$nest--; _next($_[0]); next;
		}

		if (_at($_[0], T_AND)
		 || _at($_[0], T_OR)
		 || _at($_[0], T_NOT)
		 || _at($_[0], T_EQ)
		 || _at($_[0], T_NE)
		 || _at($_[0], T_GT)
		 || _at($_[0], T_GE)
		 || _at($_[0], T_LT)
		 || _at($_[0], T_LE)
		 || _at($_[0], T_LIKE)
		 || _at($_[0], T_UNLIKE)
		 || _at($_[0], T_ADD)
		 || _at($_[0], T_SUB)
		 || _at($_[0], T_MUL)
		 || _at($_[0], T_DIV)) {

			while (@ops && $prec{$ops[@ops - 1][0]} > $prec{$_[0]{token}[0]}) {
				last if $ops[@ops - 1][0] == T_OPAR;
				push(@out, pop(@ops));
			}
			push @ops, $_[0]{token};
			_next($_[0]); next;
		}

		last
	}

	while (@ops) {
		push(@out, pop(@ops));
	}
	return @out;
}

sub _expr1
{
	die "runtime error in Verse::Template; (expr1) stack underflowed.\n"
		unless @{$_[0]};

	my $t = pop(@{$_[0]});
	return ['value',   $t->[1]]   if $t->[0] == T_STRING;
	return ['value',   $t->[1]+0] if $t->[0] == T_NUMBER;
	return ['pattern', $t->[1]]   if $t->[0] == T_REGEX;
	return ['ref',     $t->[1]]   if $t->[0] == T_IDENT;

	return ['not', _expr1($_[0])] if $t->[0] == T_NOT;

	my $l = _expr1($_[0]);
	my $r = _expr1($_[0]);

	return ['+', $r, $l] if $t->[0] == T_ADD;
	return ['-', $r, $l] if $t->[0] == T_SUB;
	return ['/', $r, $l] if $t->[0] == T_DIV;
	return ['*', $r, $l] if $t->[0] == T_MUL;

	return         ['eq',   $r, $l]  if $t->[0] == T_EQ;
	return ['not', ['eq',   $r, $l]] if $t->[0] == T_NE;
	return         ['le',   $r, $l]  if $t->[0] == T_LE;
	return ['not', ['ge',   $r, $l]] if $t->[0] == T_LT;
	return         ['ge',   $r, $l]  if $t->[0] == T_GE;
	return ['not', ['le',   $r, $l]] if $t->[0] == T_GT;
	return         ['like', $r, $l]  if $t->[0] == T_LIKE;
	return ['not', ['like', $r, $l]] if $t->[0] == T_UNLIKE;
	return         ['or',   $r, $l]  if $t->[0] == T_OR;
	return         ['and',  $r, $l]  if $t->[0] == T_AND;

	die "runtime error in Verse::Template; (expr1) was given a bad token to tree-ify (T=$t->[0]).\n";
}

sub _expr
{
	return _expr1([_i2pf($_[0])]);
}

sub _fail
{
	my ($vm, $e) = @_;
	my $f = $vm->{current} || '(unknown file)';
	$e ||= 'an unknown error has occurred';
	die "$f: $e.\n";
}

sub _unexpected
{
	my ($vm, $wanted) = @_;
	_fail($vm, "unexpected $NAMES[$vm->{token}[0]], wanted $wanted");
}

sub _if
{
	my $if = ['IF', $_[1] ?          _expr($_[0])
	                      : [ 'not', _expr($_[0]) ],
	                ['NOOP'],  # consequent
	                ['NOOP']]; # alternate
	if (!_at($_[0], T_CLOSE)) {
		_unexpected($_[0], 'a closing "%]"');
	}
	_next($_[0]);

	$if->[2] = _seq($_[0]);
	if (_at($_[0], T_END)) {
		_next($_[0]); _eat($_[0], T_CLOSE, 'a closing "%]"');
		return $if;
	}

	if (_at($_[0], T_ELSE)) {
		_next($_[0]);
		if (_at($_[0], T_CLOSE)) {
			_next($_[0]);
			$if->[3] = _seq($_[0]);
			if (_at($_[0], T_END)) {
				_next($_[0]); _eat($_[0], T_CLOSE, 'a closing "%]"');
				return $if;
			}
			_unexpected($_[0], 'a closing "%]"');
		}

		if (_at($_[0], T_IF)) {
			_next($_[0]);
			$if->[3] = _if($_[0], 1);
			return $if;
		}

		if (_at($_[0], T_UNLESS)) {
			_next($_[0]);
			$if->[3] = _if($_[0], 0);
			return $if;
		}
	}

	_unexpected($_[0], 'an "[% end %]" directive, or the "else" keyword');
}

sub _for
{
	my $for = ['FOR'];
	if (!_at($_[0], T_IDENT)) {
		_unexpected($_[0], 'a variable name for iteration');
	}
	push @$for, _argn($_[0], 0);
	_next($_[0]); _eat($_[0], T_IN, 'the "in" keyword');
	if (!_at($_[0], T_IDENT)) { # FIXME: support expressions?
		_unexpected($_[0], 'the name of the list variable to iterate over');
	}
	push @$for, _argn($_[0], 0);
	_next($_[0]); _eat($_[0], T_CLOSE, 'a closing "%]"');
	push @$for, _seq($_[0]);

	_eat($_[0], T_END, 'a "[% end %]" directive');
	_eat($_[0], T_CLOSE, 'a closing "%]"');
	return $for;
}

sub _filter
{
	my $filter = ['FILTER'];
	if (!_at($_[0], T_IDENT)) {
		_unexpected($_[0], 'a filter name, like "collapse"');
	}
	my $f = lc(_argn($_[0], 0));
	_fail($_[0], "undefined filter '$f'") unless $FILTERS{$f};

	push @$filter, $f;
	_next($_[0]); _eat($_[0], T_CLOSE, 'a closing "%]"');
	push @$filter, _seq($_[0]);

	_eat($_[0], T_END, 'a "[% end %]" directive');
	_eat($_[0], T_CLOSE, 'a closing "%]"');
	return $filter;
}

sub _apply
{
	my $fn = ['APPLY'];
	my $f = lc(_argn($_[0], 0));
	_fail($_[0], "undefined function '$f'") unless $FUNCS{$f};
	push @$fn, $f;

	_next($_[0]);
	for (;;) {
		push @$fn, _expr($_[0]);
		if (_at($_[0], T_CPAR))  { _next($_[0]); last; }
		if (_at($_[0], T_COMMA)) { _next($_[0]); next; }
		_unexpected($_[0], 'a comma (argument delimiter) or a closing parenthesis');
	}
	_eat($_[0], T_CLOSE, 'a closing "%]"'); # FIXME: prohibits nesting functions
	return $fn;
}

sub _stmt
{
	my $stmt = ['NOOP'];
	if (_at($_[0], T_IDENT)) {
		my $var = _argn($_[0], 0);
		_next($_[0]);
		if (_at($_[0], T_CLOSE)) {
			$stmt = ['DEREF', $var];
			_next($_[0]);

		} elsif (_at($_[0], T_ASSIGN)) {
			_next($_[0]);
			$stmt = ['LET', $var, _expr($_[0])];
			if (!_at($_[0], T_CLOSE)) {
				_unexpected($_[0], 'a closing "%]"');
			}
			_next($_[0]);

		} else {
			_unexpected($_[0], 'a closing "%]" or an assignment operator "="');
		}

	} elsif (_at($_[0], T_FUNCALL)) {
		$stmt = _apply($_[0]);

	} elsif (_at($_[0], T_IF)) {
		_next($_[0]);
		$stmt = _if($_[0], 1);

	} elsif (_at($_[0], T_UNLESS)) {
		_next($_[0]);
		$stmt = _if($_[0], 0);

	} elsif (_at($_[0], T_FOR)) {
		_next($_[0]);
		$stmt = _for($_[0]);

	} elsif (_at($_[0], T_FILTER)) {
		_next($_[0]);
		$stmt = _filter($_[0]);

	} else {
		_unexpected($_[0], "a variable name, or a control construct like if, unless, or for");
	}

	return $stmt;
}

sub _seq
{
	my $seq = ['SEQ'];
	while (!_at($_[0], T_EOT)) {
		if (_at($_[0], T_TEXT)) {
			push @$seq, ['ECHO', _argn($_[0], 0)];
			_next($_[0]);
			next;
		}

		if (_at($_[0], T_OPEN)) {
			_next($_[0]);
			# if we hit an [% end %] block, return early
			return $seq if _at($_[0], T_END)
			            or _at($_[0], T_ELSE);

			# otherwise, treat this as a statement opener
			push @$seq, _stmt($_[0]);
			next;
		}

		die "invalid token type\n";
	}
	return $seq;
}

sub _parse
{
	my $parser = {
		tokens => $_[0],
		token  => undef,
	};
	_next($parser);
	return _seq($parser);
}

sub _read
{
	my ($template) = @_;
	my $src = slurp($template); defined $src
		or die "failed to parse $template: $!\n";
	return _parse(_tokenize($src));
}

sub _get
{
	my @keys = split(/\./, $_[1]);
	for (my $i = scalar(@{$_[0]{env}}) - 1; $i >= 0; $i--) {
		my $o = $_[0]{env}[$i];
		my $ok = 1;
		return $o->{$_[1]}, 1 if exists $o->{$_[1]};
		for (my $j = 0; $j < @keys; $j++) {
			if (ref($o) eq 'HASH') {
				if (exists $o->{$keys[$j]}) {
					$o = $o->{$keys[$j]};
					next;
				}

			} elsif (ref($o) eq 'ARRAY') {
				# handle array.size
				if ($keys[$j] eq 'size' && $j == @keys - 1) {
					return scalar @$o, 1;
				}

				if ($keys[$j] =~ m/^[0-9]+$/ && exists $o->[$keys[$j]+0]) {
					$o = $o->[$keys[$j]+0];
					next;
				}

			} elsif (ref($o) && ref($o) =~ m/^Verse::Object::/) t{
				my $method = $keys[$j];
				$o = $o->can($method) ? $o->$method() : $o->{$method};
				next;
			}

			$ok = 0;
			last;
		}
		return $o, 1 if $ok;
	}

	return undef, 0;
}

sub _set
{
	my @keys = split(/\./, $_[1]);
	my $o = $_[0]{env}[0];
	my $last = pop @keys;
	for my $k (@keys) {
		$o->{$k} ||= {};
		$o = $o->{$k};
	}
	$o->{$last} = $_[2];
}

sub _ev1
{
	if ($_[1][0] eq 'value') {
		return $_[1][1];
	}

	if ($_[1][0] eq 'pattern') {
		return qr/$_[1][1]/;
	}

	if ($_[1][0] eq 'ref') {
		my ($v, $ok) = _get($_[0], $_[1][1]);
		return $ok ? $v : undef;
	}

	if ($_[1][0] eq 'not') {
		return !_ev1($_[0], $_[1][1]);
	}

	if ($_[1][0] eq 'or') {
		my $v = _ev1($_[0], $_[1][1]);
		return $v ? $v : _ev1($_[0], $_[1][2]);
	}

	if ($_[1][0] eq 'and') {
		my $v = _ev1($_[0], $_[1][1]);
		return !$v ? $v : _ev1($_[0], $_[1][2]);
	}

	if ($_[1][0] eq 'eq') {
		return _ev1($_[0], $_[1][1])  # lhs
		    eq _ev1($_[0], $_[1][2]); # rhs
	}

	if ($_[1][0] eq 'like') {
		my $p = _ev1($_[0], $_[1][2]);
		$p = qr/\Q$p\E/ if ref($p) ne 'Regexp';
		return _ev1($_[0], $_[1][1]) =~ $p;
	}

	if ($_[1][0] eq 'le') {
		return _ev1($_[0], $_[1][1])+0  # lhs
		    <= _ev1($_[0], $_[1][2])+0; # rhs
	}

	if ($_[1][0] eq 'ge') {
		return _ev1($_[0], $_[1][1])+0  # lhs
		    >= _ev1($_[0], $_[1][2])+0; # rhs
	}

	if ($_[1][0] eq '+') {
		return _ev1($_[0], $_[1][1])    # lhs
		     + _ev1($_[0], $_[1][2]);   # rhs
	}

	if ($_[1][0] eq '-') {
		return _ev1($_[0], $_[1][1])    # lhs
		     - _ev1($_[0], $_[1][2]);   # rhs
	}

	if ($_[1][0] eq '*') {
		return _ev1($_[0], $_[1][1])    # lhs
		     * _ev1($_[0], $_[1][2]);   # rhs
	}

	if ($_[1][0] eq '/') {
		return _ev1($_[0], $_[1][1])    # lhs
		     / _ev1($_[0], $_[1][2]);   # rhs
	}

	die "bad expr $_[1][0]";
}

sub _eval
{
	my $vm = $_[0];
	my ($op, @args) = @{$_[1]};

	if ($op eq 'NOOP') {
		return;
	}

	if ($op eq 'SEQ') {
		_eval($vm, $_) for @args;
		return;
	}

	if ($op eq 'ECHO') {
		$vm->{out} .= $args[0];
		return;
	}

	if ($op eq 'DEREF') {
		my ($v, $ok) = _get($_[0], $args[0]);
		$vm->{out} .= $v if $ok;
		return;
	}

	if ($op eq 'FILTER') {
		my $out = $vm->{out};
		$vm->{out} = '';
		_eval($vm, $args[1]);
		$vm->{out} = $out.$FILTERS{$args[0]}->($vm, $vm->{out});
		return;
	}

	if ($op eq 'APPLY') {
		# FIXME: precludes nesting fun calls; need ['PRINT', ['APPLY' ...]]
		my $fn = $args[0]; shift @args;
		$vm->{out} .= $FUNCS{$fn}->($vm, map { _ev1($vm, $_) } @args);
		return;
	}

	if ($op eq 'FOR') {
		push @{$_[0]{env}}, {};
		my ($v, $ok) = _get($_[0], $args[1]);
		$v = [] unless $ok;

		if (ref($v) eq 'ARRAY') {
			my ($i, $n) = (0, scalar @$v);
			_set($_[0], 'loop.n', $n);
			for my $x (@$v) {
				_set($_[0], 'loop.i', $i);
				_set($_[0], 'loop.first', $i == 0      ? 1 : 0);
				_set($_[0], 'loop.last',  $i == $n - 1 ? 1 : 0);
				_set($_[0], $args[0], $x);
				_eval($vm, $args[2]);
				$i++;
			}
			pop @{$_[0]{env}};
			return;
		}

		if (ref($v) eq 'HASH') {
			for my $k (sort keys %$v) {
				_set($_[0], $args[0].'.key',        $k);
				_set($_[0], $args[0].'.value', $v->{$k});
				_eval($vm, $args[2]);
			}
			pop @{$_[0]{env}};
			return;
		}

		_fail($vm, "cannot iterate over non-list / non-hash values");
	}

	if ($op eq 'IF') {
		return _eval($vm, !! _ev1($_[0], $args[0]) ? $args[1] : $args[2]);
	}

	if ($op eq 'LET') {
		_set($_[0], $args[0], _ev1($vm, $args[1]));
		return;
	}

	die "semantic error (unhandled op '$op')";
}

sub _evaluate
{
	my ($ast, $vars) = @_;
	my $vm = {
		current => '{unknown}',
		out => '',
		env => [$vars || {}],
	};
	_eval($vm, $ast);
	return $vm->{out};
}

1;

=head1 NAME

Verse::Template - Verse's Templating Engine

=head1 DESCRIPTION

Verse themes rely on templating for most of their display.  After all, a
static site generator that can't sub in values to a tempalte isn't much use.

Verse's templating syntax is straightfoward.  Code goes inside of C<[% ... %]>
and everything outside of that is considered a literal text block:

    This gets printed verbatim
    var1 = [% var1 %]

It also supports conditionals:

    [% if is.on %]
    it is so on
    [% end %]

All the usual comparison operators are available:

    [% if x >  2 %] ... [% end %]
    [% if x >= 2 %] ... [% end %]
    [% if x <  2 %] ... [% end %]
    [% if x <= 2 %] ... [% end %]
    [% if x == 2 %] ... [% end %]
    [% if x != 2 %] ... [% end %]

Text comparison is also supported:

    [% if s == "test" %] ... [% end %]
    [% if s != "test" %] ... [% end %]
    [% if s =~ /test/ %] ... [% end %]
    [% if s !~ /test/ %] ... [% end %]

Finally, looping via the C<for ... in ...> construct works:

    [% for x in some.list %] ... [% end %]

Inside of loops, additional, meta-variables exist:

=over

=item C<loop.n>

The total number of items to iterate over.

=item C<loop.i>

The current index (zero-based).

=item C<loop.first>

Set to true if this is the first iteration of the loop.

=item C<loop.last>

Set to true if this is the last iteration of the loop.

=back

=head1 FUNCTIONS

=head2 template(\@templates, \%vars, [$outfile])

Render a template, given a hierarchy of nested templates and a
set of variables and their values.  If the optional C<$outfile>
parameter isn't passed, the rendered output will be returned to
the caller.  Otherwise, the specified file will be created and
populated with the output.

=head1 AUTHOR

James Hunt, C<< <james at niftylogic.com> >>

=cut
