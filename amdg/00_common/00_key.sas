/*	MASTER KEY 																													*/
/*	MASTER CREDENTIALS 																									*/
/*	MICHAEL EDWARDS 2018-01-03 AMDG																			*/

/*	MASTER SERVER USER																									*/
%let u = medwa53;

/*	DEFINE CODE AND PARAMATER LOCATIONS																	*/
%let udir = /home;
%let pwdir = &udir./&u.;

/*	MASTER PASSWORDS 																										*/
%include "&om_common./pw.sas";
*%include "&pwdir./pw.sas";

