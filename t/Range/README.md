# Range
Die Subroutine range aus dem Paket Range erzeugt einen Iterator für numerische Intervalle.

Anwendungsbeispiel:

my $next = range( BEGINN, ENDE, SCHRITTWEITE );<br>
while ( my $wert = $next->() ){<br>
&nbsp;printf "%.1f\n", $wert;<br>
}

Warum github das Modul als Raku einordnet, ist mir schleierhaft. Es handelt sich um ganz
ordinäres Perl.