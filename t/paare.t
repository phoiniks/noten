use Test::More tests => 4;
use Test::Differences;
use FindBin qw( $Bin );

use lib "$Bin/Paar";
use lib "Paar";

use Paar qw( paar paare intervalle );

my $anfang = 1;
my $ende = 10;
my $resultat = paar( $anfang, $ende );
eq_or_diff( $resultat, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] );

my $liste = [ 0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 ];
my $erwartet = [ [0, 10], [11, 20], [21, 30], [31, 40], [41, 50], [51, 60], [61, 70], [71, 80], [81, 90], [91, 100] ];
my $ergebnis = paare( $liste );
eq_or_diff( $ergebnis, $erwartet );

$liste = $erwartet;
$erwartet = [ [0..10], [11..20], [21..30], [31..40], [41..50], [51..60], [61..70], [71..80], [81..90], [91..100] ];
$ergebnis = intervalle( $liste );
eq_or_diff( $ergebnis, $erwartet );

$liste = [ [0, 19], [20, 26], [27, 32],[33, 39], [40, 44], [45, 49], [50, 54], [55, 59], [60, 64], [65, 69], [70, 74], [75, 79], [80, 84], [85, 89], [90, 94], [95, 100] ];
$erwartet = [ [0..19], [20..26], [27..32],[33..39], [40..44], [45..49], [50..54], [55..59], [60..64], [65..69], [70..74], [75..79], [80..84], [85..89], [90..94], [95..100] ];
$ergebnis = intervalle( $liste );
eq_or_diff( $ergebnis, $erwartet );