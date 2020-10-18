#!/usr/bin/perl
use autodie;
use DBI;
use Log::Log4perl;
use Modern::Perl;
use POSIX qw( round strftime );
use Tie::IxHash;
use YAML qw( LoadFile );

BEGIN {
    use FindBin qw( $Bin );
    use lib "$Bin/Paar";
    use lib "$Bin/Range";
}

use Paar qw( paar intervalle );
use Range qw( range );

Log::Log4perl::init( 'log4perl.conf' );

my $log = Log::Log4perl->get_logger();

my $lokalzeit = strftime "%A_%d_%B_%Y_%H:%M:%S", localtime;

$log->info( "BEGINN" );
$log->info( $lokalzeit );

my $dbh = DBI->connect( "dbi:SQLite:dbname=:memory:", "", "", { PrintError => 1 } );

print "Bitte Gesamtpunktzahl eingeben: ";
chomp( my $punktzahl = <STDIN> );

print "Bitte Fach eingeben: ";
chomp( my $fach = <STDIN> );

my ( $configFile ) = glob( "*.yml" );

my $config = LoadFile( $configFile );

my %zuordnung;
tie %zuordnung, "Tie::IxHash";
%zuordnung = map { $_ => $config->{ $_ } } sort { $a <=> $b } keys %$config;

# %zuordnung = (
#     0 => [0..19],
#     1 => [20..26],
#     2 => [27..32],
#     3 => [33..39],
#     4 => [40..44],
#     5 => [45..49],
#     6 => [50..54],
#     7 => [55..59],
#     8 => [60..64],
#     9 => [65..69],
#     10 => [70..74],
#     11 => [75..79],
#     12 => [80..84],
#     13 => [85..89],
#     14 => [90..94],
#     15 => [95..100],
#     );

# DumpFile( "zuordnung.yml", \%zuordnung );

my @notenbereiche;
while ( my ( $schluessel, $werte ) = each %zuordnung ){
    my @werte = map { (modf ($_ * $punktzahl/100))[1] } @$werte;
    @werte = reverse( @werte );
    $zuordnung{ $schluessel } = \@werte;
    $log->info( $schluessel . ": " . "$werte[0]" );
    push @notenbereiche, $werte[0];
}

$log->info( "@notenbereiche" );

$log->info( "LETZTER WERT IN LISTE: " . $notenbereiche[-1] );

unshift @notenbereiche, '0';

my $ergebnis = intervalle( \@notenbereiche );

my %ergebnis = %$ergebnis;

my $csv_datei = "Noten_" . $fach . "_" . $lokalzeit . ".csv";

open my $csv, ">", $csv_datei;
my $notenpunkte = 0;
my %punkte;
tie %punkte, "Tie::IxHash";

print $csv sprintf "Datum: %s Uhr\n", strftime "%A, %d %B %Y, %H:%M", localtime;
print $csv sprintf "Fach: %s\n", $fach;
print $csv sprintf "Gesamtpunktzahl: %d\n\n", $punktzahl;

my $punkte;
for my $schluessel ( sort { $a <=> $b } keys %ergebnis ){
    printf "Note: %d, Anfang: %d, Ende: %d\n", $notenpunkte, $schluessel, $ergebnis{ $schluessel };
    $log->info( sprintf "Noten: %d, Anfang: %d, Ende: %d, Note: %d", $notenpunkte, $schluessel, $ergebnis{ $schluessel } );

    print $csv sprintf "Zensur: %d, %d bis %d\n", $notenpunkte, $schluessel, $ergebnis{ $schluessel };

    my $next = range( $schluessel, $ergebnis{ $schluessel }, 0.5 );

    my $ende = $ergebnis{ $schluessel };

    while ( $punkte = $next->() ){
	$punkte = sprintf "%.1f", $punkte;
	$log->info( $punkte );
	$punkte{ $punkte } = $notenpunkte; 
	# $log->info( $notenpunkte . ": " . $punkte );
    }

    $punkte{ sprintf "%.1f", $ergebnis{ $schluessel } } = $notenpunkte;

    $log->info( $ende );
    
    $notenpunkte++;
}

print $csv "\n\n\n";

my $table = $fach;

my $create = "CREATE TABLE IF NOT EXISTS $table(id INTEGER PRIMARY KEY, schueler TEXT, zensur INTEGER, punkte REAL, zeit DATE DEFAULT (DATETIME('NOW', 'LOCALTIME')))";

my $rv = $dbh->do( $create );

my $insert = "INSERT INTO $table (schueler, zensur, punkte) VALUES( ?, ?, ? )";
my $sth = $dbh->prepare( $insert );

my $punkte_real;
while ( 1 ){
    print "Schüler/-in: ";
    chomp( my $schueler = <STDIN> );

    if ( !$schueler ){
	last;
    }

    print "Punkte: ";
    chomp( $punkte_real = <STDIN> );

    if ( $punkte_real > $punktzahl || $punkte_real < 0 || $punkte_real =~ m/\,/g ){
	print "*******************************************************************************\n";
	print "***************************** Unzulässige Eingabe! ****************************\n";
	print "*******************************************************************************\n";	
	next;
    }

    print $csv sprintf "Schüler/in: %s, ", $schueler;

    $punkte = round $punkte_real;
    my $zensur = $punkte{ sprintf "%.1f", round $punkte };

    $sth->execute( $schueler, $zensur, $punkte );
    
    print $csv sprintf "Zensur: %d, Punktzahl: %.1f\n", $zensur, $punkte_real;
}

print $csv "\n\nNotenverteilung in der Klausur\n\n";

my $select = "SELECT zensur FROM $fach";

my %vorkommen;

$sth = $dbh->prepare( $select );
$sth->execute();
while( my @row = $sth->fetchrow_array ){
    $vorkommen{ $row[0] }++;
}


for my $schluessel ( sort { $a <=> $b } keys %vorkommen ){
    print $csv sprintf "Zensur %.1f, %d\n", $schluessel, $vorkommen{ $schluessel };
    printf "Zensur %.1f, %d\n", $schluessel, $vorkommen{ $schluessel };
    $log->info( sprintf "Zensur %.1f, %d", $schluessel, $vorkommen{ $schluessel } );
}

$select = "SELECT AVG(zensur) FROM $fach";

my ( $durchschnitt ) = $dbh->selectrow_array( $select );

print $csv sprintf "\n\nDurchschnitt: %.1f\n", $durchschnitt;

`csv2pdf --in $csv_datei --latex_encode --theme Redmond`;

$log->info( "ENDE" );
