package Sq::Core::Date;
use 5.036;

# Don't know anymore why i put this here. Did i really meant a
# DateTime representation? I don't know anymore. But still makes sense
# because date/time manipulation is basically everyhwere. Also the
# need to parse Date/Time strings.
#
# So it really makes sense to have a core datatype for representing
# this kind of data. It doesn't need to be as complete like DateTime
# with all kinds of leap seconds implementation, just something
# that is better representation is the typical built-in like localtime()
# for example that just returns 9 values.
#
# Also could contain methids/function to easily convert to other systems
# like to DateTime or other DateTime modules when you need a more
# robust system.

1;