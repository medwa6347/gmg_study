 /*----------------------------------------------------------------*\
 | MACRO TO CLEAR NHI SPOOL SPACE																		|
 |	HTTP://DMO.OPTUM.COM/PRODUCTS/NHI.HTML													|
 | AUTHOR: MICHAEL EDWARDS 2018-02-21 AMDG                          |
 \*----------------------------------------------------------------*/													
/**/

%macro util_nhi_clear_spool;

/*-----------------------------------------------------------------*/
/*---> NHI : CLEAR SPOOL SPACE <-----------------------------------*/
/**/

/*-----------------------------------------------------------------*/
/*---> DEFINE NHI OPTIONS <----------------------------------------*/
%local nhi_sbox nhi_view nhi_specs mcr_enrc;
%let NHI_Specs = user="&un_unix." password="&pw_unix." server="NHIProd";
%let nhi_sbox = NHIPDHMMSandbox;
%let nhi_view = zip3view;

%put Clearing NHI spool space...;
%put ;
* CONNECT/DISCONNECT TO CLEAR NHI SPOOL SPACE; 										
proc sql noerrorstop;
   *----------------------------------------------------------------*;
   *---> DEFINE CONNECTIONS TO NHI DATABASE;
   connect to teradata as nhi_sbox(&NHI_Specs schema="&nhi_sbox" mode=teradata);
   connect to teradata as nhi_view(&NHI_Specs schema="&nhi_view" mode=teradata);
   *----------------------------------------------------------------*;
   *---> * CONNECT/DISCONNECT TO CLEAR NHI SPOOL SPACE; 										
   disconnect from nhi_sbox;
   disconnect from nhi_view;
quit;

%let nhi_view = stateview;

* EXTRACT CONSUMER PROFILE DATA; 										
proc sql noerrorstop;
   *----------------------------------------------------------------*;
   *---> DEFINE CONNECTIONS TO NHI DATABASE;
   connect to teradata as nhi_sbox(&NHI_Specs schema="&nhi_sbox" mode=teradata);
   connect to teradata as nhi_view(&NHI_Specs schema="&nhi_view" mode=teradata);
   *----------------------------------------------------------------*;
   *---> * CONNECT/DISCONNECT TO CLEAR NHI SPOOL SPACE; 										
   disconnect from nhi_sbox;
   disconnect from nhi_view;
quit;

%exit:;
%mend;




