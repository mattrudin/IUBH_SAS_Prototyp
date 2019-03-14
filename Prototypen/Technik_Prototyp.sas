*********************************************************;
*		Vorbereitungen									*;
*********************************************************;
%let outpath=/home/matthiasrudin0/Pumpwerk GmbH;



*********************************************************;
*		Schritt 1: Access Data							*;
*********************************************************;

********** JSON import **********************;
filename techjs "&outpath/technik_static.json";
libname technik JSON fileref=techjs;

*********************************************************;
*		Schritt 2: Explore and Validating Data			*;
*********************************************************;

*Frequenz-Tabelle für die MACHINE_NAME und CONDITION Spalte;
proc freq data=technik.root;
	tables CONDITION MACHINE_NAME;
run;

*********************************************************;
*		Schritt 3: Preparing Data						*;
*********************************************************;

*Formatierung der Daten;
data technik_prep;
	set technik.root;
	if CONDITION = "AU" then Zustand="Ausfall";
	if CONDITION = "WA" then Zustand="Wartung";
	if CONDITION = "IB" then Zustand="Betrieb";
	if MACHINE_NAME = "KD" then Maschine="Konventionelle Drehbank";
	if MACHINE_NAME = "CD" then Maschine="CNC Drehbank";
	if MACHINE_NAME = "KF" then Maschine="Konventionelle Fräse";
	if MACHINE_NAME = "CF" then Maschine="CNC Fräse";
	if MACHINE_NAME = "SW1" then Maschine="Schweissmaschine 1";
	if MACHINE_NAME = "SW2" then Maschine="Schweissmaschine 2";
	keep DAYS Zustand Maschine;
run;

*Filtern der Daten nach Maschinentyp und Erstellung von Tabellen für Schritt 4;
*Konventionelle Drehbank;
data technik_kon_drehB;
	set technik_prep;
	where Maschine = "Konventionelle Drehbank";
	keep DAYS Zustand;
run;

*Schweissmaschine 1;
data technik_schweiss1;
	set technik_prep;
	where Maschine = "Schweissmaschine 1";
	keep DAYS Zustand;
run;

*********************************************************;
*		Schritt 4: Analyzing and Reporting on Data		*;
*							&							*;
*				Schritt 5: Export Results				*;
*********************************************************;

*Berichterstellung der in Schritt 3 formatierten Daten und Ausgabe in verschiedenen Dateiformaten;
************************ Häufigkeit der Zustände als PDF *****************************;
************************ Für Firmeninterne und -externe Zwecke *****************************;
*Einzelner Bericht für die Häufigkeit von Tagen im gegebenen Zustand beider Konventionellen Drehbank;
ods pdf file="&outpath/Berichte/Zustand_Konventionelle_Drehbank.pdf" startpage=no style=journal pdftoc=1;
ods escapechar='^';
ods graphics on;
ods noproctitle;

title1 '^S={preimage="&outpath/Logo/PumpWerk_Logo.png"}';
title2 "Häufigkeit an Tagen im gegebenen Zustand";
title3 "Maschine: Konventionelle Drehbank";
footnote "Schutzvermerk ISO 16016 beachten.";

proc freq data=technik_kon_drehB;
	tables Zustand;
run;

title1;
title2;
title3;

ods graphics / reset width=15cm height=10cm imagemap;

proc sort data=technik_kon_drehB out=_HistogramTaskData;
	by Zustand;
run;

proc sgplot data=_HistogramTaskData;
	by Zustand;
	histogram DAYS / nbins=10;
	density DAYS;
	xaxis label="Tage im Zustand";
	yaxis grid label="Prozent aller Tage im Zustand";
run;

ods graphics / reset;

proc datasets library=WORK noprint;
	delete _HistogramTaskData;
run;

footnote;
ods pdf close;

*Einzelner Bericht für die Häufigkeit von Tagen im gegebenen Zustand beider Konventionellen Drehbank;
ods pdf file="&outpath/Berichte/Zustand_Schweissmaschine_1.pdf" startpage=no style=journal pdftoc=1;
ods escapechar='^';
ods graphics on;
ods noproctitle;

title1 '^S={preimage="&outpath/Logo/PumpWerk_Logo.png"}';
title2 "Häufigkeit an Tagen im gegebenen Zustand";
title3 "Maschine: Schweissmaschine 1";
footnote "Schutzvermerk ISO 16016 beachten.";

proc freq data=technik_schweiss1;
	tables Zustand;
run;

title1;
title2;
title3;

ods graphics / reset width=15cm height=10cm imagemap;

proc sort data=technik_schweiss1 out=_HistogramTaskData;
	by Zustand;
run;

proc sgplot data=_HistogramTaskData;
	by Zustand;
	histogram DAYS / nbins=10;
	density DAYS;
	xaxis label="Tage im Zustand";
	yaxis grid label="Prozent aller Tage im Zustand";
run;

ods graphics / reset;

proc datasets library=WORK noprint;
	delete _HistogramTaskData;
run;

footnote;
ods pdf close;


************************ Häufigkeit der Zustände als Präsentation *****************************;
*Einzelne Präsentation für die Häufigkeit von Tagen im gegebenen Zustand beider Konventionellen Drehbank;
ods powerpoint file="&outpath/Berichte/Zustand_Konventionelle_Drehbank.pptx" style=style;
ods escapechar='^';
ods graphics on;
ods noproctitle;

title1 '^S={preimage="&outpath/Logo/PumpWerk_Logo.png"}';
title2 "Häufigkeit an Tagen im gegebenen Zustand";
title3 "Maschine: Konventionelle Drehbank";
footnote "Schutzvermerk ISO 16016 beachten.";

proc freq data=technik_kon_drehB;
	tables Zustand;
run;

title1;
title2;
title3;

ods graphics / reset width=15cm height=10cm imagemap;

proc sort data=technik_kon_drehB out=_HistogramTaskData;
	by Zustand;
run;

proc sgplot data=_HistogramTaskData;
	by Zustand;
	histogram DAYS / nbins=10;
	density DAYS;
	xaxis label="Tage im Zustand";
	yaxis grid label="Prozent aller Tage im Zustand";
run;

ods graphics / reset;

proc datasets library=WORK noprint;
	delete _HistogramTaskData;
run;

footnote;
ods powerpoint close;
*********************************************************;
*		Aufräumarbeiten									*;
*********************************************************;

*Clear libnames;
libname technik clear;
