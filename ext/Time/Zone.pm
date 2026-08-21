package Time::Zone;

# Alias for Time::Timezone
require Time::Timezone;

our @ISA = qw(Time::Timezone);
our @EXPORT = @Time::Timezone::EXPORT;
our $VERSION = $Time::Timezone::VERSION;

# Re-export everything from Time::Timezone
*tz_offset = \&Time::Timezone::tz_offset;
*tz_local_offset = \&Time::Timezone::tz_local_offset;
*tz_name = \&Time::Timezone::tz_name;

1;
