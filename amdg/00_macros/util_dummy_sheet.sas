/*-----------------------------------------------------------------*/
/*---> DUMMY TABLE MULTI-SHEET FIX MACRO <-------------------------*/
/**/
* DUMMY TABLE FIX FOR MULTI-SHEET ODS EXCEL;
* NOTE: THIS CAN BE REMOVED ONCE ODS EXCEL MULTI-SHEET FUNCTIONALITY IS PROPERLY WORKING;
* https://communities.sas.com/t5/ODS-and-Base-Reporting/ODS-excel-amp-multiple-sheets/m-p/261953#U261953;

%macro util_dummy_sheet();

ods excel options(sheet_interval='table');
ods exclude all;
data _null_;
file print;
put _all_;
run;
ods select all;

%mend;