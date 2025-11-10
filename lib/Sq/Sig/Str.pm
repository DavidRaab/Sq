package Sq::Sig::Str;
use 5.036;
use Sq::Type;
use Sq::Signature;

my $str  = t_str;
my $int  = t_int;
my $num  = t_num;
my $bool = t_bool;
my $sub  = t_sub;
my $pint = t_int(t_min 1);

sig('Sq::Core::Str::length',      $str, t_int);
sig('Sq::Core::Str::lc',          $str, $str);
sig('Sq::Core::Str::uc',          $str, $str);
sig('Sq::Core::Str::chomp',       $str, $str);
sig('Sq::Core::Str::chop',        $str, $str);
sig('Sq::Core::Str::reverse',     $str, $str);
sig('Sq::Core::Str::ord',         $str, $int);
sig('Sq::Core::Str::chr',         $int, $str);
sig('Sq::Core::Str::hex',         $str, $int);
sig('Sq::Core::Str::trim',        $str, $str);
sig('Sq::Core::Str::collapse',    $str, $str);
sig('Sq::Core::Str::nospace',     $str, $str);
sig('Sq::Core::Str::escape_html', $str, $str);
sig('Sq::Core::Str::repeat',      $str, $num, $str);
sig('Sq::Core::Str::starts_with', $str, $str, $bool);
sig('Sq::Core::Str::ends_with',   $str, $str, $bool);
sig('Sq::Core::Str::contains',    $str, $str, $bool);
sig('Sq::Core::Str::chunk',       $str, $pint, t_array);
sig('Sq::Core::Str::map',         $str, $sub,  $str);
# sig('Sq::Core::Str::keep',        $str, $sub,  $str);
sig('Sq::Core::Str::remove',      $str, $sub,  $str);
sig('Sq::Core::Str::split',       $str, t_regex, $str);
sig('Sq::Core::Str::to_array',    $str, t_array);
sig('Sq::Core::Str::is_empty',    $str, $str);

1;