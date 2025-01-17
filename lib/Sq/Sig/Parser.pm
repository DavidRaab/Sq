package Sq::Sig::Parser;
use 5.036;
use Sq;
use Sq::Type;
use Sq::Signature;

my $parser  = t_sub;
my $parsers = t_array(t_of $parser);
my $split   = t_or(t_str, t_regex);

sig ('Sq::Parser::p_run',        $parser, t_str,                    t_opt);
sig ('Sq::Parser::p_valid',      $parser, t_str,                   t_bool);
sig ('Sq::Parser::p_match',      t_regex,                         $parser);
sig ('Sq::Parser::p_matchf',     t_regex, t_sub,                  $parser);
sig ('Sq::Parser::p_matchf_opt', t_regex, t_sub,                  $parser);
sigt('Sq::Parser::p_map',        t_tuplev(t_sub, $parsers),       $parser);
sig ('Sq::Parser::p_bind',       $parser, t_sub,                  $parser);
sigt('Sq::Parser::p_and',        $parsers,                        $parser);
sigt('Sq::Parser::p_return',     t_array,                         $parser);
sigt('Sq::Parser::p_or',         $parsers,                        $parser);
sigt('Sq::Parser::p_maybe',      $parsers,                        $parser);
sig ('Sq::Parser::p_join',       t_str, $parser,                  $parser);
sigt('Sq::Parser::p_str',        t_array(t_min(1), t_of t_str),   $parser);
sigt('Sq::Parser::p_strc',       t_array(t_min(1), t_of t_str),   $parser);
sigt('Sq::Parser::p_many',       $parsers,                        $parser);
sigt('Sq::Parser::p_many0',      $parsers,                        $parser);
sig ('Sq::Parser::p_ignore',     $parser,                         $parser);
sig ('Sq::Parser::p_fail',                                        $parser);
sig ('Sq::Parser::p_qty',        t_int, t_int, $parser,           $parser);
sig ('Sq::Parser::p_choose',     $parser, t_sub,                  $parser);
sig ('Sq::Parser::p_repeat',     t_int, $parser,                  $parser);
sig ('Sq::Parser::p_keep',       $parser, t_sub,                  $parser);
sig ('Sq::Parser::p_split',      $split, $parser,                 $parser);
sig ('Sq::Parser::p_delay',      t_sub,                           $parser);
sig ('Sq::Parser::p_not',        $parser,                         $parser);
sig ('Sq::Parser::p_empty',                                       $parser);

1;