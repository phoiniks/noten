#!/usr/bin/perl
use autodie;
use DBI;
use Encode qw( decode encode );
use Log::Log4perl;
use Modern::Perl;
use POSIX qw( modf round strftime );
use Tie::IxHash;
use YAML qw( LoadFile );

BEGIN {
    use FindBin qw( $Bin );
    use lib "$Bin/Paar";
    use lib "$Bin/Range";
}

use Paar qw( intervalle );
use Range qw( range );

my $home = $ENV{ HOME };

Log::Log4perl::init( $home . "/bin/NOTEN/log4perl.conf" );
my $log = Log::Log4perl->get_logger();
my $lokalzeit = strftime "%A_%d_%B_%Y_%H:%M:%S", localtime;

$log->info( "BEGINN" );
$log->info( $lokalzeit );


my %Deutsch_Dekodierung = (
    'Ä' => 'Ae', 'ä' => 'ae',
    'Ö' => 'Oe', 'ö' => 'oe',
    'Ü' => 'Ue', 'ü' => 'ue',
    'ß' => 'ss', 'ñ' => 'nh',
    'á' => 'a', 'é' => 'e',
    'í' => 'i', 'ó' => 'o',
    'ú' => 'u'
    );


sub utf8_zu_ascii{
    my ( $deutsch ) = @_;

    $deutsch =~ s/([ÄäÖöÜüß]+)/$Deutsch_Dekodierung{$1}/eg;

    return $deutsch;
}


my $dbh = DBI->connect( "dbi:SQLite:dbname=noten.db",
			"", "", { PrintError => 1 } );

print "Bitte erreichbare Gesamtpunktzahl eingeben: ";
chomp( my $gesamtpunktzahl = <STDIN> );

print "Bitte Fach eingeben: ";
chomp( my $fach = <STDIN> );
$log->info( $fach );
my $fach_dekodiert = utf8_zu_ascii( $fach );
$log->info( sprintf "dekodiert: %s", $fach_dekodiert );
my $titel = $fach;
my $titel_dekodiert = utf8_zu_ascii( $titel );
$log->info( sprintf "Titel dekodiert: %s", $titel_dekodiert );
$fach = lc $fach;

print "Bitte Klasse eingeben: ";
chomp( my $klasse = <STDIN> );

my $datenbank = $fach_dekodiert . "_" . $klasse . "_" . $lokalzeit . ".db";

my $config = LoadFile( $home . "/bin/NOTEN/zuordnung.yml" );

my %zuordnung;
tie %zuordnung, "Tie::IxHash";
%zuordnung = map { $_ => $config->{ $_ } } sort { $a <=> $b } keys %$config;

my @notenbereiche;
while ( my ( $schluessel, $werte ) = each %zuordnung ){
    my @werte = map { (modf ($_ * $gesamtpunktzahl/100))[1] } @$werte;
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

my $csv_datei = "Noten_" . $titel_dekodiert . "_" . $lokalzeit . ".csv";

open my $csv, ">", $csv_datei;
my $notenpunkte = 0;

print $csv sprintf "Datum: %s Uhr\n", strftime "%A, %d %B %Y, %H:%M", localtime;
print $csv sprintf "Fach: %s\n", $titel;
print $csv sprintf "Klasse: %s\n", $klasse;
print $csv sprintf "Erreichbare Gesamtpunktzahl: %d\n\n", $gesamtpunktzahl;

my %punkte;
tie %punkte, "Tie::IxHash";

my $punkte;
for my $schluessel ( sort { $a <=> $b } keys %ergebnis ){
    printf "Zensur: %d, Anfang: %d, Ende: %d\n",
	    $notenpunkte, $schluessel, $ergebnis{ $schluessel };
    $log->info( sprintf "Zensur: %d, Anfang: %d, Ende: %d",
 			 $notenpunkte, $schluessel, $ergebnis{ $schluessel } );

    print $csv sprintf "Zensur: %d, %d bis %d\n",
			$notenpunkte, $schluessel, $ergebnis{ $schluessel };

    my $next = range( $schluessel, $ergebnis{ $schluessel }, 0.5 );

    my $ende = $ergebnis{ $schluessel };

    while ( $punkte = $next->() ){
	$punkte = sprintf "%.1f", $punkte;
	$log->info( $punkte );
	$punkte{ $punkte } = $notenpunkte; 
    }

    $punkte{ sprintf "%.1f", $ergebnis{ $schluessel } } = $notenpunkte;

    $log->info( $ende );
    
    $notenpunkte++;
}

print $csv "\n\n\n";

my $table = $fach_dekodiert;

my $create = "CREATE TABLE IF NOT EXISTS $table(id INTEGER PRIMARY KEY,
	      schueler TEXT, zensur INTEGER, punkte REAL, zeit DATE DEFAULT
              (DATETIME('NOW', 'LOCALTIME')))";

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

    $log->info( sprintf "Schüler/in: %s", $schueler );
    
    print "Punkte: ";
    chomp( $punkte_real = <STDIN> );

    if ( !$punkte_real ){
	$punkte_real = "0.0";
    }

    if ( $punkte_real > $gesamtpunktzahl || $punkte_real < 0 
	|| $punkte_real =~ m/\,/g || !$punkte_real ) {
	print "*" x 70;
	print "\n";
	print "*" x 28;
	print " Unzulässige Eingabe! ";
	print "*" x 28;
	print "\n";
	print "*" x 70;
	print "\n";
	next;
    }

    print $csv sprintf "Schüler/in: %s, ", $schueler;

    $punkte = round $punkte_real;
    my $zensur = $punkte{ sprintf "%.1f", $punkte };

    $sth->execute( $schueler, $zensur, $punkte );

    $log->debug( sprintf "Zensur: %d, Punktzahl: %.1f\n",
			  $zensur, $punkte_real );
    print $csv sprintf "Zensur: %d, Punktzahl: %.1f\n", 
			$zensur, $punkte_real;
}

print $csv "\n\nNotenverteilung in der Klausur\n\n";

my $select = "SELECT zensur, COUNT(zensur) FROM $table GROUP BY zensur";

my $notenverteilung = $dbh->selectall_arrayref( $select );

$select = "SELECT AVG(zensur) FROM $table";

my ( $durchschnitt ) = $dbh->selectrow_array( $select );

print $csv "\n";
print "\n";

for my $row ( @$notenverteilung ){
    printf "Zensur: %d, %d-mal\n", $row->[0], $row->[1];
    print $csv sprintf "Zensur: %d, %d-mal\n", $row->[0], $row->[1];
    $log->info( sprintf "Zensur: %d, %d-mal\n", $row->[0], $row->[1] );
}

printf "\nDurchschnitt: %.1f\n", $durchschnitt;
$log->info( sprintf "Durchschnitt: %.1f", $durchschnitt );
print $csv sprintf "Durchschnitt: %.1f\n", $durchschnitt;

`csv2pdf --in $csv_datei --latex_encode --theme Redmond`;

`statistiken.r $table $titel`;

$log->info( "ENDE" );
