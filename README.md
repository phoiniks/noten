# noten

Anwendung für die Berechnung von Zensuren in der gymnasialen Oberstufe.

Damit das Skript funktioniert, benötigen Sie einige Bibliotheken, darunter:

csv2pdf, nach dem Sie per apt-cache (apt-cache search csv2pdf) suchen. Sie könnten

allerdings auch das cpan (Comprehensive Perl Archive Network) wie folgt verwenden:

cpan LaTeX::Table. Die sonst noch fehlenden Perl-Module ermitteln Sie so lange mit

Hilfe von perl -c noten.pl, bis Ihnen keine mehr fehlen (Wenn ich in nächster Zukunft

Zeit habe, könnten Sie sich vielleicht bald der Segnungen einer anständigen

Installationsroutine erfreuen, das kann allerdings noch etwas dauern.) Falls noch

nicht geschehen, legen Sie bitte in Ihrem Home-Verzeichnis /home/{user} ein bin-Verzeichnis

an, in das sie den Ordner NOTEN kopieren. Würden Sie sich im Verzeichnis /home/phoiniks

befinden, müssten Sie Folgendes tun:


cp -r NOTEN bin


Dann begeben Sie sich per cd nach bin/NOTEN:


cd bin/NOTEN


Von dort aus kopieren Sie die Datei statistiken.r nach bin in Ihrem Home-Verzeichnis:


cp statistiken.r ../


(Natürlich geht das alles auch anders, aber ich habe einfach mal die leichteste Variante
aufgeschrieben...)


Dann sourcen Sie die Datei .profile:


cd ~/

source .profile


Am besten legen Sie in /home/{user}/bin einen symbolischen Link auf bin/NOTEN/noten.pl

an, den Sie vielleicht noten nennen möchten:


ln -s /home/{user}/bin/NOTEN/noten.pl noten


Jetzt sourcen Sie wieder Ihre .profile-Datei:


cd ~/

source .profile


und können nun über einen einfachen Aufruf von noten mit der Eingabe beginnen.


Ach, ja, ehe ichs vergesse: Wenn Sie ein Diagramm mit R erzeugen wollen, brauchen Sie R

und die im Skript statistiken.r im Kopf angegebenen Module. Legen Sie bitte im Verzeichnis

/home/{user}/bin mit ln -s NOTEN/statistiken.r statistik den im Perl-Skript verwendeten

symbolischen Link an. Brauchen Sie das mit dem R-Skript erzeugte Diagramm nicht, so

kommentieren Sie die entsprechende Zeile am Ende des Perl-Skripts einfach aus mit einem

Hash-Zeichen (#) aus.


PS: Wenn Sie Fragen haben, wenden Sie sich vertrauensvoll an mich: phoiniks@grellopolis.de.

ich helfe Ihnen dann gern weiter. Ich arbeite übrigens momentan an einer Verschlankung des

Codes in Richtung Objektorientierung mit Moose sowie an einer Installationsroutine.