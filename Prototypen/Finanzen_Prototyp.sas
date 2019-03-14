*********************************************************;
*		Vorbereitungen									*;
*********************************************************;
%let outpath=/home/matthiasrudin0/Pumpwerk GmbH;



*********************************************************;
*		Schritt 1: Access Data							*;
*********************************************************;

********** EXCEL import **********************;
options validvarname=v7;
libname finanzen xlsx "&outpath/Finanzen_static.xlsx";



*********************************************************;
*		Schritt 2: Explore and Validating Data			*;
*********************************************************;

*Grobe Analyse der in Schritt 1 importierten Daten;
*Einfache numerische Statistik für PRICE Spalte;
proc means data=finanzen.sheet1;
	var PRICE;
run;

*Erweiterte numerische Statistik für PRICE Spalte;
proc univariate data=finanzen.sheet1;
	var PRICE;
run;

*Sortiere nach EXPENSE_TYPE und DATE, anschliessend generiere neue Tabelle für weitere Anwendung;
proc sort data=finanzen.sheet1 out=finanzen_sort;
	by EXPENSE_TYPE DATE;
run;


*********************************************************;
*		Schritt 3: Preparing Data						*;
*********************************************************;

*Formatierung der sortierten Tabelle aus Schritt 2;
data finanzen_prep;
	set finanzen_sort;
	format PRICE euro10.;
	if EXPENSE_TYPE = "RM" then Aufwendung="Rohmaterial";
	if EXPENSE_TYPE = "ZK" then Aufwendung="Zukaufteile";
	if EXPENSE_TYPE = "SA" then Aufwendung="Salär";
	if EXPENSE_TYPE = "GE" then Aufwendung="Garantien";
	if EXPENSE_TYPE = "UI" then Aufwendung="Unterhalt";
	if EXPENSE_TYPE = "SO" then Aufwendung="Sonstiges";
	drop EXPENSE_TYPE;
run;

*Filtern der Daten nach Aufwand-Typ und Erstellung von Tabellen für Schritt 4;
data finanzen_rohmaterial;
	set finanzen_sort;
	where EXPENSE_TYPE EQ "RM";
	drop EXPENSE_TYPE;
	format PRICE euro10.;
run;

data finanzen_gehalt;
	set finanzen_sort;
	where EXPENSE_TYPE EQ "SA";
	drop EXPENSE_TYPE;
	format PRICE euro10.;
run;



*********************************************************;
*		Schritt 4: Analyzing and Reporting on Data		*;
*							&							*;
*				Schritt 5: Export Results				*;
*********************************************************;

*Berichterstellung der in Schritt 3 formatierten Daten und Ausgabe in verschiedenen Dateiformaten;

************************ Häufigkeit von Aufwendungen als PDF *****************************;
************************ Für Firmeninterne und -externe Zwecke *****************************;
*Einzelner Bericht für die Häufigkeit von Aufwendungen;

ods pdf file="&outpath/Berichte/Aufwendung_Haeufigkeitbericht.pdf" startpage=no style=journal pdftoc=1;
ods escapechar='^';
ods graphics on;
ods noproctitle;

title1 '^S={preimage="&outpath/Logo/PumpWerk_Logo.png"}';
title2 "Häufigkeitsbericht für Aufwendungen";
footnote "Schutzvermerk ISO 16016 beachten.";
proc freq data=finanzen_prep;
	*Häufigkeit pro Aufwendung;
	tables Aufwendung DATE/ nocum plots=freqplot;
	*Häufigkeit aller Aufwendungen pro Jahr;
	format DATE year.;
	label DATE="Jahr";
run;
title1;
title2;
footnote;

ods pdf close;

************************ Statistik pro Aufwendungen als PDF *****************************;
************************ Für Firmeninterne und -externe Zwecke *****************************;
*Einzelner Bericht für die Statistik pro Aufwendung;

ods pdf file="&outpath/Berichte/Aufwendung_Statistik.pdf" startpage=no style=journal pdftoc=1;
ods escapechar='^';

title1 '^S={preimage="&outpath/Logo/PumpWerk_Logo.png"}';
title2 "Statistik pro Aufwendung";
footnote "Schutzvermerk ISO 16016 beachten.";
proc means data=finanzen_prep mean median min max maxdec=0;
	var PRICE;
	class Aufwendung;
	output out=finanzen_stat;
run;

*Box plot Grafik für "Statistik pro Aufwendung";
ods graphics / reset width=12cm height=10cm imagemap;

proc sgplot data=WORK.FINANZEN_STAT;
	title height=14pt "Häufigkeit für Preis pro Aufwendung";
	vbox PRICE / category=Aufwendung;
	yaxis grid label="Preis in €" type=log;
run;

ods graphics / reset;
title;
title1;
title2;
footnote;

ods pdf close;


*Bericht über den Salär;
ods pdf file="&outpath/Berichte/Salaer_Statistik.pdf" startpage=no style=journal pdftoc=1;
ods escapechar='^';

title1 '^S={preimage="&outpath/Logo/PumpWerk_Logo.png"}';
title2 "Statistik für Salär";
footnote "Schutzvermerk ISO 16016 beachten.";

*Korrelationsanalyse;
title3 "Korrelationsanalyse";
ods noproctitle;
ods graphics / imagemap=on;

proc corr data=WORK.FINANZEN_GEHALT pearson nosimple noprob plots=none;
	var PRICE;
	with DATE;
run;

title1;
title2;
title3;
footnote;

*Scatterplot darstellung;
title4 "Scatterplot mit LOESS und Regressionskurve";
ods graphics / reset width=15cm height=10cm imagemap;

proc sgplot data=WORK.FINANZEN_GEHALT;
	reg x=DATE y=PRICE / nomarkers;
	loess x=DATE y=PRICE / nomarkers;
	scatter x=DATE y=PRICE /;
	xaxis grid;
	yaxis grid label="Gehalt in €";
run;

ods graphics / reset;

title4;

ods pdf close;


*Bericht über die Rohmaterialausgaben über die Zeit;
ods pdf file="&outpath/Berichte/Rohmaterialausgabe_Liste.pdf" startpage=no style=journal pdftoc=1;
ods escapechar='^';

title1 '^S={preimage="&outpath/Logo/PumpWerk_Logo.png"}';
title2 "Pumpwerk Gmbh: Rohmaterialausgaben von 2000 bis 2019";
footnote "Schutzvermerk ISO 16016 beachten.";
proc print data=finanzen_rohmaterial label noobs;
	label DATE="Datum"
		PRICE="Preis in Euro";
run;
title1;
title2;
footnote;

ods pdf close;

************************ Output der Tabellen als EXCEL*****************************;
************************ Für weitere Firmeninterne Bearbeitung *****************************;
*Export der Rohmaterialientabelle;
proc export data=finanzen_rohmaterial
	outfile="&outpath/Output/rohmaterial_tabelle.xlsx"
	dbms=xlsx replace;
run;

*Export der Salärtabelle;
proc export data=finanzen_gehalt
	outfile="&outpath/Output/gehalt_tabelle.xlsx"
	dbms=xlsx replace;
run;

************************ Output der Tabellen als CSV*****************************;
*Export aller Aufwendungen als Textdatei;
proc export data=finanzen_prep
	outfile="&outpath/Output/aufwendungen.txt"
	dbms=csv replace;
run;

*********************************************************;
*		Aufräumarbeiten									*;
*********************************************************;

*Clear libnames;
libname finanzen clear;

