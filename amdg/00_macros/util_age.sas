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