*********************************************************;
*		Vorbereitungen									*;
*********************************************************;
%let outpath=/home/matthiasrudin0/Pumpwerk GmbH;



*********************************************************;
*		Schritt 1: Access Data							*;
*********************************************************;

********** CSV import **********************;
proc import datafile="&outpath/Marketing_static.csv" dbms=csv
	out=mrketing replace;
run;


*********************************************************;
*		Schritt 2: Explore and Validating Data			*;
*********************************************************;

*Frequenz-Tabelle für die ENDCUSTOMER_CONTINENT Spalte;
proc freq data=mrketing;
	tables ENDCUSTOMER_CONTINENT;
run;

*Einfache numerische Statistik für PRICE Spalte;
proc means data=mrketing;
	var PRICE_PER_PUMP;
run;

*Sortiere nach ENDCUSTOMER_CONTINENT und DATE, anschliessend generiere neue Tabelle für weitere Anwendung;
proc sort data=mrketing out=mrketing_sort;
	by ENDCUSTOMER_CONTINENT DATE;
run;


*********************************************************;
*		Schritt 3: Preparing Data						*;
*********************************************************;

*Formatierung der sortierten Tabelle aus Schritt 2;
data mrketing_prep;
	set mrketing_sort;
	Total = NO_OF_PUMPS * PRICE_PER_PUMP;
	format Total euro10.;
	if ENDCUSTOMER_CONTINENT = "AF" then Kontinent="Afrika";
	if ENDCUSTOMER_CONTINENT = "AS" then Kontinent="Asien";
	if ENDCUSTOMER_CONTINENT = "EU" then Kontinent="Europa";
	if ENDCUSTOMER_CONTINENT = "NA" then Kontinent="Nord Amerika";
	if ENDCUSTOMER_CONTINENT = "OC" then Kontinent="Ozeanien";
	if ENDCUSTOMER_CONTINENT = "SA" then Kontinent="Süd und Mittelamerika";
	keep Kontinent Total;
run;

*********************************************************;
*		Schritt 4: Analyzing and Reporting on Data		*;
*							&							*;
*				Schritt 5: Export Results				*;
*********************************************************;

*Berichterstellung der in Schritt 3 formatierten Daten und Ausgabe in verschiedenen Dateiformaten;

************************ Projektübersicht als PDF *****************************;
************************ Für Firmeninterne und -externe Zwecke *****************************;
*Einzelner Bericht für die Häufigkeit und Verkaufspreis von Projekten pro Kontinent;
ods pdf file="&outpath/Berichte/Projektuebersicht_Kontinente.pdf" startpage=no style=journal pdftoc=1;
ods escapechar='^';
ods graphics on;
ods noproctitle;

title1 '^S={preimage="&outpath/Logo/PumpWerk_Logo.png"}';
footnote "Schutzvermerk ISO 16016 beachten.";

proc means data=mrketing_prep mean median min max maxdec=0;
	var Total;
	class Kontinent;
	*output out=finanzen_stat;
run;
title1;

*Boxplot für Projektpreise pro Kontinent;
ods graphics / reset width=15cm height=15cm imagemap;

proc sgplot data=WORK.MRKETING_PREP;
	title2 height=14pt "Projektpreise pro Kontinent";
	vbox Total / category=Kontinent;
	yaxis grid label="Totalpreis pro Projekt in €" type=log;
run;

ods graphics / reset;
title2;

*Heat Map für Anzahl Projekte und Verkaufspreis pro Kontinent;
ods graphics / reset width=15cm height=10cm imagemap;

proc sgplot data=mrketing_prep;
	title3 height=14pt "Anzahl Projekte und Verkaufspreis pro Kontinent";
	heatmap x=Total y=Kontinent / name='HeatMap';
	gradlegend 'HeatMap';
	xaxis grid label="Verkaufspreis pro Projekt in €";
run;

ods graphics / reset;
title3;

footnote;
ods pdf close;

************************ Output der Tabellen als EXCEL*****************************;
************************ Für weitere Firmeninterne Bearbeitung *****************************;
*Export der vorbereiteten Marketing Tabelle;
proc export data=mrketing_prep
	outfile="&outpath/Output/marketing.xlsx"
	dbms=xlsx replace;
run;

************************ Output der Tabellen als CSV*****************************;
*Export der vorbereiteten Marketing Tabelle;
proc export data=mrketing_prep
	outfile="&outpath/Output/marketing.txt"
	dbms=csv replace;
run;

*********************************************************;
*		Aufräumarbeiten									*;
*********************************************************;

*Clear libnames;
*N/A
