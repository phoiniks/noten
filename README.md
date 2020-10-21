# noten
Anwendung für die Berechnung von Zensuren in der gymnasialen Oberstufe unter Debian.

Damit das Skript funktioniert, benötigen Sie legen Sie einige Bibliotheken, darunter:

csv2pdf, nach dem Sie per apt-cache (apt-cache search csv2pdf) suchen. Die fehlenden

Perl-Module ermitteln Sie so lange mit Hilfe von perl -c noten.pl, bis Ihnen keine

mehr fehlen (Wenn ich in nächster Zukunft Zeit habe, könnten Sie sich vielleicht bald

an den Segnungen einer anständigen Installationsroutine erfreuen, das kann allerdings

noch etwas dauern. Falls noch nicht geschehen, legen Sie bitte in Ihrem

Home-Verzeichnis /home/{user} ein bin-Verzeichnis an, in das sie den Ordner NOTEN

kopieren. Würden Sie sich im Verzeichnis /home/phoiniks befinden müssten Folgendes

tun:


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