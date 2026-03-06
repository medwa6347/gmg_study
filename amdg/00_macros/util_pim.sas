%macro util_pim(fn=,rng=,out_tmp=);
 /*-----------------------------------------------------------------*\
 | MACRO TO EXECUTE PROC IMPORT .XLSX WITH GIVEN SPECIFICATIONS	   	 |
 | Author: Michael W. Edwards 01-23-2017                             |
 |                                                                   |
 | DESCRIPTION OF MACRO PARAMETERS:                                  |
 |    FN    	: REQUIRED. EXCEL FILE TO EVALUATE      							 |
 |		RNG 	 	: REQUIRED. RANGE TO EVALUATE.  FORMAT = Sheet$Range	 |
 |    OUT_TMP	: REQUIRED. DSN TO OUTPUT TO												 	 |
 |		DTFLD	 	: REQUIRED. DATE FIELD TO EVALUATE 										 |
 |                                                                   |
 | UPDATE HISTORY:                                                   |
 \*-----------------------------------------------------------------*/

data _null_;
rng=%unquote(%str(%'&rng%'));
call symput("r",rng);
run;

proc import	
		datafile="&fn."
		dbms=xlsx
		replace
		out=&out_tmp.;
  	range="&r";
  	getnames=yes;
quit;
%mend;

