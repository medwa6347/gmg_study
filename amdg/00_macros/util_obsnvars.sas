 /*----------------------------------------------------------------*\
 | MACRO TO RETURN OBS AND VARS FROM DS									  |
 | AUTHOR: Felix Friedman 2013-02-05                          		  |
 | MODIFIED: Michael Edwards 2017-05-03									  |
  \*---------------------------------------------------------------*/													
/**/

%macro util_obsnvars(ds,req=);
%* 2013-02-05 Felix: this is a modified version of example from SAS
   v9.2 help file in %sysfunc chapter.;
%global dset nvars nobs ds_empty ds_exist;
%local wordvars wordobs;
%let dset=&ds;
%let dsid = %sysfunc(open(&dset));
%if &dsid %then %do;
   %let ds_exist = 1;
   %let nobs =%sysfunc(attrn(&dsid,NOBS));
   %let nvars=%sysfunc(attrn(&dsid,NVARS));
   %let rc = %sysfunc(close(&dsid));
   %*put &dset has &nvars variable(s) and &nobs observation(s).;
   %if &nvars=1 %then %let wordvars=variable; %else %let wordvars=variables;
   %if &nobs=1 %then %let wordobs=observation; %else %let wordobs=observations;
   %put NOTE: &dset has &nvars &wordvars and &nobs &wordobs..;
   %if &nobs>&req %then %let ds_empty = 0; %else %let ds_empty = 1;
   %end;
%else %do; %let ds_exist = 0; %let ds_empty = 1; %put WARNING: Open for data set &dset failed.; %end;
%mend;
/**
%obsnvars(sasuser.houses);
%obsnvars(sasuser.sasmbc);
/*------------------------------------------------------------------*/


