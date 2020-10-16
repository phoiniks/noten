#!/usr/bin/perl
use autodie;
use Log::Log4perl;
use Modern::Perl;
use POSIX qw( ceil floor modf round strftime trunc );
use Redis;
use Tie::IxHash;

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

print "Bitte Gesamtpunktzahl eingeben: ";
chomp( my $punktzahl = <STDIN> );

print "Bitte Fach eingeben: ";
chomp( my $fach = <STDIN> );

my %zuordnung;
tie %zuordnung, "Tie::IxHash";
%zuordnung = (
    0 => [0..19],
    1 => [20..26],
    2 => [27..32],
    3 => [33..39],
    4 => [40..44],
    5 => [45..49],
    6 => [50..54],
    7 => [55..59],
    8 => [60..64],
    9 => [65..69],
    10 => [70..74],
    11 => [75..79],
    12 => [80..84],
    13 => [85..89],
    14 => [90..94],
    15 => [95..100],
    );

my @notenbereiche;
while ( my ( $key, $values ) = each %zuordnung ){
    my @values = map { (modf ($_ * $punktzahl/100))[1] } @$values;
    @values = reverse( @values );
    $zuordnung{ $key } = \@values;
    $log->info( $key . ": " . "$values[0]" );
    push @notenbereiche, $values[0];
}

$log->info( "@notenbereiche" );

$log->info( "LETZTER WERT IN LISTE: " . $notenbereiche[-1] );

my $ergebnis = intervalle( \@notenbereiche );

my %ergebnis = %$ergebnis;

my $csv_datei = "Noten_" . $fach . "_" . $lokalzeit . ".csv";
my $tex_datei = "Noten_" . $fach . "_" . $lokalzeit . ".tex";
open my $csv, ">", $csv_datei;
my $notenpunkte = 0;
my %punkte;
tie %punkte, "Tie::IxHash";

print $csv sprintf "Datum: %s Uhr\n", strftime "%A, %d %B %Y, %H:%M", localtime;
print $csv sprintf "Fach: %s\n", $fach;
print $csv sprintf "Gesamtpunktzahl: %d\n\n", $punktzahl;

my $punkte;
for my $key ( sort { $a <=> $b } keys %ergebnis ){
    printf "Note: %d, Anfang: %d, Ende: %d\n", $notenpunkte, $key, $ergebnis{ $key };
    $log->info( sprintf "Anfang: %d, Ende: %d, Note: %d", $key, $ergebnis{ $key }, $notenpunkte );

    print $csv sprintf "%d bis %d: %d Punkte\n", $key, $ergebnis{ $key }, $notenpunkte;

    my $next = range( $key, $ergebnis{ $key }, 0.5 );

    my $ende = $ergebnis{ $key };

    while ( $punkte = $next->() ){
	$punkte = sprintf "%.1f", $punkte;
	$log->info( $punkte );
	$punkte{ $punkte } = $notenpunkte; 
	# $log->info( $notenpunkte . ": " . $punkte );
    }

    $punkte{ sprintf "%.1f", $ergebnis{ $key } } = $notenpunkte;

    $log->info( $ende );
    
    $notenpunkte++;
}

$log->info( Dumper( \%punkte ) );

print $csv "\n\n\n";

my $punkte_real;
while ( 1 ){
    print "Schüler/-in: ";
    chomp( my $schueler = <STDIN> );

    if ( !$schueler ){
	last;
    }

    print "Punkte: ";
    chomp( $punkte_real = <STDIN> );

    if ( $punkte_real > $punktzahl || $punkte_real < 0 ){
	print "*******************************************************************************\n";
	print "****** Eingabe jenseits des zulässigen Bereichs. Bitte erneut versuchen! ******\n";
	print "*******************************************************************************\n";	
	next;
    }

    print $csv sprintf "Schüler/in: %s, ", $schueler;

    $punkte = round $punkte_real;
    my $note = $punkte{ sprintf "%.1f", round $punkte };
    
    print $csv sprintf "Notenpunkte: %d, Punktzahl: %.1f\n", $note, $punkte_real; 
}

`csv2latex $csv_datei > $tex_datei`;

sleep 5;

`pdflatex $tex_datei`;

$log->info( "ENDE" );
