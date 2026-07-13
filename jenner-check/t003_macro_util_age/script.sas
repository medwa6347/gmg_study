%macro util_age(varname=Age, From_Dt=, To_Dt=);
 /*-----------------------------------------------------------------*\
 | MACRO TO CALCULATE EXACT AGE IN YEARS                             |
 | Author: Felix Friedman 2013-08-19                                 |
 |                                                                   |
 | USE THIS MACRO WITHIN A DATA STEP WHICH CONTAINS DATE VARS TO     |
 | CALCULATE AGE FROM.  THIS IS AN EXAMPLE OF USING THIS MACRO:      |
 |    %age(varname=Age, From_Dt=DOB, To_Dt=today());                 |
 \*-----------------------------------------------------------------*/
   length &varname 3;
   &varname = int((
                   intck('month', &From_Dt, &To_Dt)-(day(&To_Dt)<min(day(&From_Dt),
                   day(intnx('month',&To_Dt, 1)-1)))
                  )/12);
%mend;

/* caller exercising %util_age exactly as its header documents:
   compute exact age in years from a date-of-birth variable */
data patient_ages;
  input dob :date9. asof :date9.;
  format dob asof date9.;
  %util_age(varname=Age, From_Dt=dob, To_Dt=asof);
  datalines;
15AUG1970 01JAN2018
31DEC1985 01JAN2018
29FEB2000 28FEB2018
01NOV1955 01JAN2018
15NOV2010 01JAN2018
;
run;

proc print data=patient_ages; run;
