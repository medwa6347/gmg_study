 /*----------------------------------------------------------------*\
 | STANDALONE ADHOC PNH/aHUS/gMG ANALYSIS FOR ALEXICON - EHR				|
 |  HTTP://DMO.OPTUM.COM/PRODUCTS/NHI.HTML													|
 | AUTHOR: MICHAEL EDWARDS 2018-07-09 AMDG                          |
 \*----------------------------------------------------------------*/													
/**/
                     
* COMMAND LINE;								
/*
cd /hpsaslca/mwe/alexion/pnh_ahus_gmg_201806/amdg
sas_tws 0600_soliris_ehr.sas -autoexec /hpsaslca/mwe/alexion/pnh_ahus_gmg_201806/amdg/00_common/00_common.sas &                                                       
*/      

%macro data_ehr;
	
%local vz; %let vz = 2;

*COMMON - REDUNDANT, FOR EXECUTION ON SAS EG;
%include "/hpsaslca/mwe/alexion/pnh_ahus_gmg_201806/amdg/00_common/00_common.sas";
%include "&om_macros./util_dummy_sheet.sas";

/*-----------------------------------------------------------------*/
/*---> SOLIRIS PROCEDURES, NDC, DXS <------------------------------*/
/**/
%let market_prc_cds = 'J1300';
%let market_ndc_cds = '25682000101';
%let pnh_dxs 				= 'D595';
%let ahus_dxs 			= 'D593';
%let gmg_dxs 				= 'G7000','G7001';
%let all_dxs 				= 'D595','D593','G7000','G7001';

* PLACE-OF-SERVICE LU;
%include "&om_code./00_common/00_pos_lu.sas";

* GLOBAL FORMATS;
%include "&om_code./00_formats/fmt_reporting.sas";

/*-----------------------------------------------------------------*/
/*---> DEFINE NHI CONNECTION <-------------------------------------*/
/**/
%local nhi_sbox nhi_view nhi_specs u mcr mcr_cohort com com_cohort;
%let nhi_view = CCISTATEVIEW;
%let NHI_Specs = user="&un_unix." password="&pw_unix." server="NHIProd";
%let nhi_sbox = NHIPDHMMSandbox;
libname _sbox_ teradata &NHI_Specs schema="&nhi_sbox";
*DELETE ANY LEFTOVER NHI SANDBOX DATA;
proc datasets nolist library=_sbox_; delete t&vz.:; quit;  
proc datasets nolist library=_sbox_; delete td&vz.:; quit; 

*NHI FIELDS;
%include "&om_code./0601_ehr_flds.sas";

/*-----------------------------------------------------------------*/
/*---> SOLIRIS EHR ENCOUNTER DXS <---------------------------------*/
/**

*CLEAR OUT NHI SPOOL SPACE;
%util_nhi_clear_spool;

%put NOTE: Pulling Market EHR-Encounter Dx Data...;

%let dx_whr	=	where diagnosis_cd_nodecm in (&all_dxs.) and diag_date between '2018-01-01' and '2018-12-31';

%let dx = &dx_flds. &dx_from. &dx_whr.;

* NHI DATA PULL; 
%put EHR-Encounter Dx Data...;
%put ;
proc sql noerrorstop;
   *----------------------------------------------------------------*;
   *---> DEFINE CONNECTIONS TO NHI DATABASE;
   connect to teradata as nhi_sbox(&NHI_Specs schema="&nhi_sbox" mode=teradata);
   connect to teradata as nhi_view(&NHI_Specs schema="&nhi_view" mode=teradata);
   *----------------------------------------------------------------*;
   *---> EXTRACT MARKET MEMBERS;
   execute(
      create table &nhi_sbox..t&vz._mbr_admin_dx as (
         
				&dx.				
				  	      		
			) with data
   ) by nhi_sbox;       
   disconnect from nhi_sbox;
   disconnect from nhi_view;
quit;

*MBR DX TABLE FOR RX PULL;
data t&vz._mbr_admin_dx; set _sbox_.t&vz._mbr_admin_dx; run;
proc sort data=t&vz._mbr_admin_dx; by panther_id diag_date mbr_admin_dx; run;
proc print data=t&vz._mbr_admin_dx (obs=10); run;
data t&vz._mbr_dx; 
	set t&vz._mbr_admin_dx; 
	by panther_id diag_date; 
	length first_dx $7.;
	retain first_dx;
	if put(mbr_admin_dx,$dx_fmt.) not in ('Other') then first_dx = mbr_admin_dx;
	if last.panther_id and put(first_dx, $dx_fmt.) in ('PNH','aHUS','gMG') then output;	
	if last.panther_id and put(first_dx, $dx_fmt.) not in ('PNH','aHUS','gMG') then do; first_dx = 'Other'; output; end;
	keep panther_id first_dx;
run;
proc print data=t&vz._mbr_dx (obs=10); run;

* CREATE TEMPORARY MBR DX TABLE; 										
%put Creating temp mbr dx table for rx data...;
%put ;
proc sql; create table _sbox_.t&vz._mbr_dx (BULKLOAD=YES DBCOMMIT=0) as (select distinct panther_id, first_dx as mbr_admin_dx from t&vz._mbr_dx); quit;

/*-----------------------------------------------------------------*/
/*---> SOLIRIS EHR MED ADMINS <------------------------------------*/
/**

*CLEAR OUT NHI SPOOL SPACE;
%util_nhi_clear_spool;

%put NOTE: Pulling Market EHR-Med Admin Data...;

%let med_admin_whr = where (ndc in (&market_ndc_cds.) or drug_name like ('%SOLIRIS%') or generic_desc like ('%ECULIZUMAB%')) and (admin_date between '2018-01-01' and '2018-12-31'); 

%let med_admin = &med_admin_flds. &med_admin_from. &med_admin_whr.;

* NHI DATA PULL; 
%put EHR-Med Admin Data...;
%put ;
proc sql noerrorstop;
   *----------------------------------------------------------------*;
   *---> DEFINE CONNECTIONS TO NHI DATABASE;
   connect to teradata as nhi_sbox(&NHI_Specs schema="&nhi_sbox" mode=teradata);
   connect to teradata as nhi_view(&NHI_Specs schema="&nhi_view" mode=teradata);
   *----------------------------------------------------------------*;
   *---> EXTRACT MARKET MEMBERS;
   execute(
      create table &nhi_sbox..t&vz._med_admin as (
         
				&med_admin.				
				  	      		
			) with data
   ) by nhi_sbox;       
   disconnect from nhi_sbox;
   disconnect from nhi_view;
quit;

data inp.final_med_admin; length &med_admin_var_length.; set _sbox_.t&vz._med_admin; run;
proc datasets nolist library=_sbox_; delete t&vz._med_admin; quit; 

data inp.final_med_admin; 
	set inp.final_med_admin;
	dose = quantity_of_dose;
	if quantity_of_dose = . and strength ^= . then dose = strength / 10;
	format mbr_admin_dx $dx_fmt.;
run;
data inp.final_med_admin; 
	set inp.final_med_admin;
	dose = input(quantity_of_dose,4.);
run;

proc sort data=inp.final_med_admin; by panther_id admin_date; run;	

/*-----------------------------------------------------------------*/
/*---> SOLIRIS EHR PROCEDURES <------------------------------------*/
/**

*CLEAR OUT NHI SPOOL SPACE;
%util_nhi_clear_spool;

%put NOTE: Pulling Market EHR-Procedures Data...;

%let proc_whr = where proc_code_nodecm in (&market_prc_cds.) and admin_date between '2018-01-01' and '2018-12-31'; 

%let procs = &proc_flds. &proc_from. &proc_whr.;

* NHI DATA PULL; 
%put EHR-Procedures Data...;
%put ;
proc sql noerrorstop;
   *----------------------------------------------------------------*;
   *---> DEFINE CONNECTIONS TO NHI DATABASE;
   connect to teradata as nhi_sbox(&NHI_Specs schema="&nhi_sbox" mode=teradata);
   connect to teradata as nhi_view(&NHI_Specs schema="&nhi_view" mode=teradata);
   *----------------------------------------------------------------*;
   *---> EXTRACT MARKET MEMBERS;
   execute(
      create table &nhi_sbox..t&vz._procs as (
         
				&procs.				
				  	      		
			) with data
   ) by nhi_sbox;       
   disconnect from nhi_sbox;
   disconnect from nhi_view;
quit;

data inp.final_procs; length &proc_var_length.; set _sbox_.t&vz._procs; run;
proc datasets nolist library=_sbox_; delete t&vz._procs; quit; 

data inp.final_procs; 
	set inp.final_procs;
	dose = .;
	format mbr_admin_dx $dx_fmt.;
run;

proc sql; 
	create table inp.t&vz._procs_same_ma as (
	select pc.* 
	from inp.final_procs pc 
	inner join inp.final_med_admin ma 
		on ma.panther_id = pc.panther_id 
		and ma.admin_date = pc.admin_date 
	);
	create table inp.final_procs_no_ma as (
	select pc.* 
	from inp.final_procs pc 
	left join inp.t&vz._procs_same_ma ma 
		on ma.panther_id = pc.panther_id 
	where ma.panther_id is null
	);
quit;

proc sort data=inp.final_procs_no_ma; by panther_id admin_date; run;	

/*-----------------------------------------------------------------*/
/*---> SOLIRIS EHR RX <--------------------------------------------*/
/**

*CLEAR OUT NHI SPOOL SPACE;
%util_nhi_clear_spool;

%put NOTE: Pulling Market EHR-Rx Data...;

%let rx_whr = where (ndc in (&market_ndc_cds.) or drug_name like ('%SOLIRIS%') or generic_desc like ('%ECULIZUMAB%')) and (admin_date between '2018-01-01' and '2018-12-31'); 

%let rx = &rx_flds. &rx_from. &rx_whr.;

* NHI DATA PULL; 
%put EHR-Rx Data...;
%put ;
proc sql noerrorstop;
   *----------------------------------------------------------------*;
   *---> DEFINE CONNECTIONS TO NHI DATABASE;
   connect to teradata as nhi_sbox(&NHI_Specs schema="&nhi_sbox" mode=teradata);
   connect to teradata as nhi_view(&NHI_Specs schema="&nhi_view" mode=teradata);
   *----------------------------------------------------------------*;
   *---> EXTRACT MARKET MEMBERS;
   execute(
      create table &nhi_sbox..t&vz._rx as (
         
				&rx.				
				  	      		
			) with data
   ) by nhi_sbox;       
   disconnect from nhi_sbox;
   disconnect from nhi_view;
quit;

data inp.final_rx; length &rx_var_length.; set _sbox_.t&vz._rx; run;
proc datasets nolist library=_sbox_; delete t&vz._rx; quit; 

data inp.final_rx; 
	set inp.final_rx;
	dose = quantity_of_dose;
	if quantity_of_dose = . and strength ^= . then dose = strength / 10;
	format mbr_admin_dx $dx_fmt.;
run;
data inp.final_rx; 
	set inp.final_rx;
	dose = input(quantity_of_dose,4.);
run;

proc sort data=inp.final_rx; by panther_id admin_date; run;

*----------------------------------------------------------------*;
*---> STAGE REPORTING DATA <-------------------------------------*;	
/**

data inp.t&vz._member_dosage; 
	set inp.final_med_admin (keep= panther_id admin_date dose mbr_admin_dx)
			inp.final_rx	(keep= panther_id admin_date dose mbr_admin_dx)
			inp.final_procs_no_ma (keep= panther_id admin_date dose mbr_admin_dx);
run;
proc sort data=inp.t&vz._member_dosage; by panther_id admin_date; run;
	
/*-----------------------------------------------------------------*/
/*---> SOLIRIS EHR PATIENT OBS <-----------------------------------*/
/**

*CLEAR OUT NHI SPOOL SPACE;
%util_nhi_clear_spool;

%put NOTE: Pulling Market EHR-Patient Obs Data...;

%let pt_obs_whr = where obs_type in ('WT') and obs_date between '2014-01-01' and '2018-12-31'; 

%let mkt_join = inner join &nhi_sbox..t&vz._mkt_cohort mkt on po.panther_id = mkt.panther_id;	

%let pt_obs = &pt_obs_flds. &pt_obs_from. &mkt_join. &pt_obs_whr.;

* CREATE TEMPORARY COHORT TABLE; 										
%put Creating temp cohort table...;
%put ;
proc sql; create table _sbox_.t&vz._mkt_cohort (BULKLOAD=YES DBCOMMIT=0) as (select distinct panther_id from inp.t&vz._member_dosage); quit;

* NHI DATA PULL; 
%put EHR-Patient Obs Data...;
%put ;
proc sql noerrorstop;
   *----------------------------------------------------------------*;
   *---> DEFINE CONNECTIONS TO NHI DATABASE;
   connect to teradata as nhi_sbox(&NHI_Specs schema="&nhi_sbox" mode=teradata);
   connect to teradata as nhi_view(&NHI_Specs schema="&nhi_view" mode=teradata);
   *----------------------------------------------------------------*;
   *---> EXTRACT MARKET MEMBERS;
   execute(
      create table &nhi_sbox..t&vz._pt_obs as (
         
				&pt_obs.				
				  	      		
			) with data
   ) by nhi_sbox;       
   disconnect from nhi_sbox;
   disconnect from nhi_view;
quit;

data inp.final_pt_obs; 
	length &pt_obs_var_length.; 
	set _sbox_.t&vz._pt_obs; 
	pt_wt = input(obs_result,6.); 
	drop obs_result; 
run;
proc datasets nolist library=_sbox_; delete t&vz._pt_obs; quit;  

proc sort data=inp.final_pt_obs; by panther_id obs_date; run;


/*-----------------------------------------------------------------*/
/*---> PATIENT WEIGHT WINDOWS <------------------------------------*/
/**

data inp.final_pt_obs_windows(sortedby=panther_id window_start); 
	set inp.final_pt_obs; 
	by panther_id obs_date; 
	retain window_start window_end window_st_wt window_end_wt; 
	if first.panther_id and last.panther_id then do;
		window_start = '01Jan2014'd;
		window_end 	 = '31Dec2018'd;
		window_st_wt	= pt_wt;
		window_end_wt	= pt_wt;		
		output; end;
	if first.panther_id then do; 
		window_start = '01Jan2014'd;
		window_end	 = obs_date;
		window_st_wt = pt_wt;
		window_end_wt	 = pt_wt;
		output;
		end;
 	if lag(panther_id) = panther_id then do;  	
		window_start = window_end;
 		window_st_wt = window_end_wt;
 		window_end_wt = pt_wt;
 		window_end = obs_date;
 		output; 
 		end;
 if last.panther_id then do; 
		window_start = window_end;
		window_end 	 = '31Dec2018'd;
		window_st_wt	= pt_wt;
		window_end_wt	= pt_wt;		
 		output; end;
	keep panther_id window_start window_end window_st_wt window_end_wt;
	format window_start window_end mmddyy10. window_wt pt_wt_fmt.;
run;		

/*-----------------------------------------------------------------*/
/*---> ADMINS AND WEIGHT <-----------------------------------------*/
/**

proc sql; 
	create table t&vz._med_admin_wt_window_a as 
	select ad.*, win.* 
	from inp.t&vz._member_dosage ad 
	inner join inp.final_pt_obs_windows win 
		on ad.panther_id = win.panther_id; 
quit; 

data t&vz._med_admin_wt_window; 
	set t&vz._med_admin_wt_window_a; 
	if window_start <= admin_date <= window_end then output; 
run;

proc sort data=t&vz._med_admin_wt_window nodupkey; by panther_id admin_date; run;

data inp.final_med_admin_wt;
	set t&vz._med_admin_wt_window;	  
	if (admin_date - window_start) <= (window_end - admin_date) then pt_wt = window_st_wt; 
	if (admin_date - window_start) > (window_end - admin_date) then pt_wt = window_end_wt;
run;
proc sort data=inp.final_med_admin_wt; by panther_id admin_date; run;

*----------------------------------------------------------------*;
*---> SOLIRIS MEMBERS BY DX <------------------------------------*;
/**/
proc sql;
	create table inp.final_pnh as (select distinct panther_id, mbr_admin_dx from inp.final_med_admin_wt where put(mbr_admin_dx,$dx_fmt.) = 'PNH');
	create table inp.final_ahus as (select distinct panther_id, mbr_admin_dx from inp.final_med_admin_wt where put(mbr_admin_dx,$dx_fmt.) = 'aHUS');
	create table inp.final_gmg as (select distinct panther_id, mbr_admin_dx from inp.final_med_admin_wt where put(mbr_admin_dx,$dx_fmt.) = 'gMG');
	create table inp.t&vz._all_pnh_ahus_gmg_all as (select * from inp.final_pnh union all select * from inp.final_ahus union all select * from inp.final_gmg);
	create table inp.t&vz._all_pnh_ahus_gmg as (select distinct panther_id from inp.t&vz._all_pnh_ahus_gmg_all);
	create table inp.final_other as (
		select distinct dos.panther_id
				, "Other" as mbr_admin_dx 
				from inp.final_med_admin_wt dos 
				left join inp.t&vz._all_pnh_ahus_gmg al 
					on dos.panther_id = al.panther_id 
		where al.panther_id is null and put(mbr_admin_dx,$dx_fmt.) not in ('aHUS','gMG','PNH')
		); 
	create table inp.t&vz._member_dx as (
		select sd.*, mbr.mbr_admin_dx from inp.final_med_admin_wt sd inner join inp.final_pnh mbr on sd.panther_id = mbr.panther_id
		union all
		select sd.*, mbr.mbr_admin_dx from inp.final_med_admin_wt sd inner join inp.final_ahus mbr on sd.panther_id = mbr.panther_id
		union all
		select sd.*, mbr.mbr_admin_dx from inp.final_med_admin_wt sd inner join inp.final_gmg mbr on sd.panther_id = mbr.panther_id
		union all
		select sd.*, mbr.mbr_admin_dx from inp.final_med_admin_wt sd inner join inp.final_other mbr on sd.panther_id = mbr.panther_id
); 
quit;
data inp.final_med_admin_wt_dx; set inp.t&vz._member_dx; if missing(mbr_admin_dx) then mbr_admin_dx = "Other"; run;
proc sort data=inp.final_med_admin_wt_dx; by panther_id admin_date; run;

/*-----------------------------------------------------------------*/
/*---> ALL MEMBER DEMOGRAPHICS <-----------------------------------*/
/**

*CLEAR OUT NHI SPOOL SPACE;
%util_nhi_clear_spool;

%put NOTE: Pulling Market EHR-Patient Data...;

%let pt_whr = ; 

%let mkt_join = inner join &nhi_sbox..t&vz._mkt_cohort mkt on p.panther_id = mkt.panther_id;	

%let pt = &pt_flds. &pt_from. &mkt_join. &pt_whr.;

* CREATE TEMPORARY COHORT TABLE; 										
%put Creating temp cohort table...;
%put ;
proc sql; create table _sbox_.t&vz._mkt_cohort (BULKLOAD=YES DBCOMMIT=0) as (select distinct panther_id from inp.t&vz._member_dx); quit;

* NHI DATA PULL; 
%put EHR-Patient Data...;
%put ;
proc sql noerrorstop;
   *----------------------------------------------------------------*;
   *---> DEFINE CONNECTIONS TO NHI DATABASE;
   connect to teradata as nhi_sbox(&NHI_Specs schema="&nhi_sbox" mode=teradata);
   connect to teradata as nhi_view(&NHI_Specs schema="&nhi_view" mode=teradata);
   *----------------------------------------------------------------*;
   *---> EXTRACT MARKET MEMBERS;
   execute(
      create table &nhi_sbox..t&vz._pt as (
         
				&pt.				
				  	      		
			) with data
   ) by nhi_sbox;       
   disconnect from nhi_sbox;
   disconnect from nhi_view;
quit;

data inp.t&vz._pt; 
	set _sbox_.t&vz._pt; 
run;

proc sort data=inp.t&vz._pt; by panther_id update_date; run;

data inp.t&vz._pt_a; set inp.t&vz._pt; by panther_id update_date; if last.panther_id then output; drop update_date; run;
 	
data inp.final_pt; 
	length &pt_var_length.; 
	set inp.t&vz._pt_a; 
	dob = mdy(1,1,year_of_birth);
	%util_age(varname=age, From_Dt=dob, To_Dt='31Dec2018'd);
	drop dob year_of_birth;
run;
proc datasets nolist library=_sbox_; delete t&vz._pt; quit;  

proc sort data=inp.final_pt; by panther_id; run;
       	

/*-----------------------------------------------------------------*/
/*---> SOLIRIS REPORTING OUTPUT <----------------------------------*/
/**/

%let rp_hcp 	= "&om_data./05_out_rep/Alexion_Soliris_EHR_Analysis_2016_18_dose_adjust.xls";

* GRAPHICS ON;
ods listing close;
ods listing gpath="&om_data./05_out_rep/";
ods output; ods graphics on;

%put Outputting Reporting...;

	/*-----------------------------------------------------------------*/
	/*---> REPORT: DOSAGE, GAPS, WT ANALYSIS <-------------------------*/
	/**/   
	
			* EXCEL REPORT;
			Ods excel file=&rp_hcp. style=XL&vz.sansPrinter
					options
					(
						sheet_name="Soliris_Therapy_and_Dosage"
						sheet_interval='none'
						embedded_titles='yes'
					);
				
				data inp.final_member_dosage_gaps_dtl; 
					set inp.final_med_admin_wt_dx; 
					if '01Jan2016'd <= admin_date <= '31Dec2018'd;
					by panther_id admin_date; 
					retain first_min_admin_date min_admin_date admin_thru_date max_admin_date initial_dosage maint_dose initial_wt maint_wt therapy_gap gap; 
					admin_thru_date = lag(admin_date);
					if first.panther_id and last.panther_id then do;
						min_admin_date = admin_date;
						max_admin_date = admin_date;
						initial_dosage = dose;
						maint_dose = dose;
						initial_wt = pt_wt;
						maint_wt = pt_wt;
						continuous_therapy_length = max_admin_date - min_admin_date; 
						gap = 0;
						output; end;
					if first.panther_id then do; 
						first_min_admin_date = admin_date; 
						min_admin_date = admin_date; 
						initial_dosage = dose; 
						initial_wt = pt_wt;
						end;
			  	if admin_date- admin_thru_date > 16 and lag(panther_id) = panther_id then do;  	
			  		max_admin_date = admin_thru_date;
			  		therapy_gap = admin_date- admin_thru_date;
			  		gap = 1;
			  		continuous_therapy_length = admin_thru_date - min_admin_date;  
			  		output; 
			  		min_admin_date = admin_date;
			  		therapy_gap = 0;
			  		continuous_therapy_length = 0;
			  		gap = 0;
			  		end;
			  if last.panther_id then do; 
			  		max_admin_date = admin_date; 
			  		maint_dose = dose; 
						maint_wt = pt_wt;
			  		continuous_therapy_length = admin_date- min_admin_date; 
			  		total_therapy_length = admin_date- first_min_admin_date;
			  		gap = 0;
			  		output; end;
					keep panther_id min_admin_date max_admin_date continuous_therapy_length total_therapy_length therapy_gap gap initial_dosage maint_dose initial_wt maint_wt mbr_admin_dx;
					format initial_dosage maint_dose dose_fmt. min_admin_date max_admin_date mmddyy10.;
				run;
				data inp.t&vz._member_dosage_gaps_summary_a; 
					set inp.final_member_dosage_gaps_dtl;
					by panther_id; 
					retain initial_dose last_maint_dose initial_pt_wt last_maint_pt_wt;
					if first.panther_id then do; initial_dose = initial_dosage; initial_pt_wt = initial_wt; end;
					if last.panther_id then do;
						last_maint_dose = maint_dose;
						last_maint_pt_wt = maint_wt;
						output;
						end;
					keep panther_id initial_dose last_maint_dose initial_pt_wt last_maint_pt_wt mbr_admin_dx;
				run;
				proc sql; create table inp.t&vz._member_dosage_gaps_summary_b as 
					select panther_id
					, min(min_admin_date) as min_admin_date
					, max(max_admin_date) as max_admin_date
					, max(total_therapy_length) as total_therapy_length
					, sum(continuous_therapy_length) as total_continuous_therapy_length
					, mean(continuous_therapy_length) as mean_continuous_therapy_length
					, median(continuous_therapy_length) as median_continuous_therapy_length
					, sum(continuous_therapy_length) / max(total_therapy_length) as percent_continuous_therapy
					, sum(gap) as total_gaps
					, mean(therapy_gap) as mean_therapy_gap
					, median(therapy_gap) as median_therapy_gap
					from inp.final_member_dosage_gaps_dtl
					group by 1;
				quit;
				proc sort data=inp.t&vz._member_dosage_gaps_summary_a; by panther_id; run;
				proc sort data=inp.t&vz._member_dosage_gaps_summary_b; by panther_id; run;					
				data inp.final_member_dosage_gaps_summary; merge inp.t&vz._member_dosage_gaps_summary_a inp.t&vz._member_dosage_gaps_summary_b; by panther_id; 
					if total_therapy_length = 0 then delete; if put(mbr_admin_dx,$dx_fmt.) not in ('PNH','aHUS','gMG') then delete;
					if 20 <= median_therapy_gap <= 22 and initial_dose > 90  then initial_dose = initial_dose*(3/4); 
					if 20 <= median_therapy_gap <= 22 and last_maint_dose > 90  then last_maint_dose = last_maint_dose*(3/4);
					if 27 <= median_therapy_gap <= 29 and initial_dose > 90  then initial_dose = initial_dose*(1/2); 
					if 27 <= median_therapy_gap <= 29 and last_maint_dose > 90  then last_maint_dose = last_maint_dose*(1/2);
					format initial_dose last_maint_dose dose_fmt. initial_pt_wt last_maint_pt_wt pt_wt_fmt. min_admin_date max_admin_date mmddyy10. mbr_admin_dx $dx_fmt.;
					run;
				proc summary
				data=inp.final_member_dosage_gaps_summary maxdec=1;
					var total_therapy_length total_continuous_therapy_length mean_continuous_therapy_length percent_continuous_therapy total_gaps mean_therapy_gap;
					class mbr_admin_dx;
					output out=t&vz._a (rename=(_freq_ = Patients));				
				run;	
				data t&vz._b; 
					set t&vz._a (where = (_stat_ not in ('N','STD'))); 
					if _type_ = 3; 
					drop _type_; 
					format total_therapy_length total_continuous_therapy_length comma9. 
						mean_continuous_therapy_length total_gaps mean_therapy_gap comma9.1 
						percent_continuous_therapy percent9.2; 
				run;
				proc sort data=inp.final_member_dosage_gaps_summary; by panther_id; run;	

				*---> BEGIN REPORTING GROUP LOOP <-------------------------------*
				%let admin_dx_types = PNH | aHUS | gMG;
				%let rg=1; 
				%let admin_dx_type 			= %scan(&admin_dx_types.,&rg,|);
				%do %while (&admin_dx_type ne);	

				title;
				title "Soliris Frequency of Patients: Initial Dosage";
				title2 "January 1st, 2016 - March 31st, 2018, &admin_dx_type. Diagnosis";				

				proc freq data=inp.final_member_dosage_gaps_summary order=formatted; tables initial_dose; where put(mbr_admin_dx,$dx_fmt.) = "&admin_dx_type."; run;

					data t&vz._aa; merge inp.final_member_dosage_gaps_summary(keep=panther_id initial_dose initial_pt_wt mbr_admin_dx) inp.final_pt; by panther_id; if put(mbr_admin_dx,$dx_fmt.) = "&admin_dx_type." and initial_dose ^= ' '; run;	
					data t&vz._bb; merge inp.final_member_dosage_gaps_summary(keep=panther_id initial_dose initial_pt_wt mbr_admin_dx) inp.final_pt; by panther_id; if put(mbr_admin_dx,$dx_fmt.) = "&admin_dx_type." and initial_dose = ' '; run;				
					data t&vz._aabb; 
						merge inp.final_member_dosage_gaps_summary(keep=panther_id initial_dose mbr_admin_dx) inp.final_pt; 
						by panther_id; 
						if put(mbr_admin_dx,$dx_fmt.) = "&admin_dx_type." and initial_dose ^= ' ' then initial_dose_data = "with_initial_dose_data";
						if put(mbr_admin_dx,$dx_fmt.) = "&admin_dx_type." and initial_dose = ' ' then initial_dose_data = "without_initial_dose_data"; 
						if gender = 'FEMALE' then percent_female = 1; 
						if gender = 'MALE' then percent_female = 0; 
					run;		
							
					/*CHI-SQUARED*
					proc means data=t&vz._aa maxdec=0 noprint; class age gender race region initial_pt_wt; var age; output out=t&vz._aabbsums_with n=patients; format age age_test_fmt. initial_pt_wt pt_wt_fmt. race $race_fmt.; run;
					data t&vz._aabbsums_with; set t&vz._aabbsums_with; test_group_nm = catx("_",put(age, age_test_fmt.),gender,put(race,$race_fmt.),region,put(initial_pt_wt,pt_wt_fmt.)); run;
					proc means data=t&vz._bb maxdec=0 noprint; class age gender race region initial_pt_wt; var age; output out=t&vz._aabbsums_wo n=patients; format age age_test_fmt. initial_pt_wt pt_wt_fmt. race $race_fmt.; run;
					data t&vz._aabbsums_wo; set t&vz._aabbsums_wo; test_group_nm = catx("_",put(age, age_test_fmt.),gender,put(race,$race_fmt.),region,put(initial_pt_wt,pt_wt_fmt.)); run;
					proc sql; 
						create table t&vz._aabbsums_all_with_wo as (
						select _type_ as test_number, test_group_nm, "With Intial Dose Data" as patient_category, patients from t&vz._aabbsums_with where _type_ > 0 
						union all
						select _type_ as test_number, test_group_nm, "Without Intial Dose Data" as patient_category, patients from t&vz._aabbsums_wo where _type_ > 0 
						); 
						quit;
						proc sort data=t&vz._aabbsums_all_with_wo; by test_number test_group_nm; run;
						proc freq data=t&vz._aabbsums_all_with_wo noprint; by test_number; tables test_group_nm*patient_category / expected cellchi2 norow nocol chisq; output out=t&vz._chissq n nmiss pchi lrchi; weight patients; run;
						title;
						title "Chi-Squared Results: N-Way Examination of Age Group, Race Group, Region, Initial Weight Group and Gender of Soliris Patients with and without Initial Dose Data";			
						title2 "January 1st, 2016 - March 31st, 2018, &admin_dx_type. Diagnosis";	
						proc print data=t&vz._chissq noobs; run;
							
					/*T-TEST*	
					title;
					title "Two-Sample T-Test: Age Distribution of Soliris Patients with and without Initial Dose Data";
					title2 "January 1st, 2016 - March 31st, 2018, &admin_dx_type. Diagnosis";	
					proc ttest data=t&vz._aabb plots(only)=summary; class initial_dose_data; var age; run;												 							 

				title;
				title "Soliris Frequency of Patients: Most Recent Maintenance Dosage";
				title2 "January 1st, 2016 - March 31st, 2018, &admin_dx_type. Diagnosis";	
				*/

				proc freq data=inp.final_member_dosage_gaps_summary order=formatted; tables last_maint_dose; where put(mbr_admin_dx,$dx_fmt.) = "&admin_dx_type."; run;

					data t&vz._aa; merge inp.final_member_dosage_gaps_summary(keep=panther_id initial_pt_wt last_maint_dose mbr_admin_dx) inp.final_pt; by panther_id; if put(mbr_admin_dx,$dx_fmt.) = "&admin_dx_type." and last_maint_dose ^= ' '; run;	
					data t&vz._bb; merge inp.final_member_dosage_gaps_summary(keep=panther_id initial_pt_wt last_maint_dose mbr_admin_dx) inp.final_pt; by panther_id; if put(mbr_admin_dx,$dx_fmt.) = "&admin_dx_type." and last_maint_dose = ' '; run;				
					data t&vz._aabb; merge inp.final_member_dosage_gaps_summary(keep=panther_id initial_pt_wt last_maint_dose mbr_admin_dx) inp.final_pt; by panther_id; if put(mbr_admin_dx,$dx_fmt.) = "&admin_dx_type." and last_maint_dose ^= ' ' then last_maint_dose_data = "with_last_maint_dose_data"; if put(mbr_admin_dx,$dx_fmt.) = "&admin_dx_type." and last_maint_dose = ' ' then last_maint_dose_data = "without_last_maint_dose_data"; if gender = 'FEMALE' then percent_female = 1; if gender = 'MALE' then percent_female = 0; run;				

					/*CHI-SQUARED*	
					proc means data=t&vz._aa maxdec=0 noprint; class age gender race region initial_pt_wt; var age; output out=t&vz._aabbsums_with n=patients; format age age_test_fmt. initial_pt_wt pt_wt_fmt. race $race_fmt.; run;
					data t&vz._aabbsums_with; set t&vz._aabbsums_with; test_group_nm = catx("_",put(age, age_test_fmt.),gender,put(race,$race_fmt.),region,put(initial_pt_wt,pt_wt_fmt.)); run;
					proc means data=t&vz._bb maxdec=0 noprint; class age gender race region initial_pt_wt; var age; output out=t&vz._aabbsums_wo n=patients; format age age_test_fmt. initial_pt_wt pt_wt_fmt. race $race_fmt.; run;
					data t&vz._aabbsums_wo; set t&vz._aabbsums_wo; test_group_nm = catx("_",put(age, age_test_fmt.),gender,put(race,$race_fmt.),region,put(initial_pt_wt,pt_wt_fmt.)); run;
					proc sql; 
						create table t&vz._aabbsums_all_with_wo as (
						select _type_ as test_number, test_group_nm, "With Most Recent Maintenance Dose Data" as patient_category, patients from t&vz._aabbsums_with where _type_ > 0 
						union all
						select _type_ as test_number, test_group_nm, "Without Most Recent Maintenance Dose Data" as patient_category, patients from t&vz._aabbsums_wo where _type_ > 0 
						); 
						quit;
						proc sort data=t&vz._aabbsums_all_with_wo; by test_number test_group_nm; run;			
						proc freq data=t&vz._aabbsums_all_with_wo noprint; by test_number; tables test_group_nm*patient_category / expected cellchi2 norow nocol chisq; output out=t&vz._chissq n nmiss pchi lrchi; weight patients; run;
						title;
						title "Chi-Squared Results: N-Way Examination of Age Group, Race Group, Region, Initial Weight Group and Gender of Soliris Patients with and without Initial Dose Data";			
						title2 "January 1st, 2016 - March 31st, 2018, All Patients";	
						proc print data=t&vz._chissq noobs; run;
							
					/*T-TEST*					
					title;
					title "Two-Sample T-Test: Age Distribution of Soliris Patients with and without Most Recent Maintenance Dose Data";
					title2 "January 1st, 2016 - March 31st, 2018, &admin_dx_type. Diagnosis";	
					proc ttest data=t&vz._aabb plots(only)=summary; class last_maint_dose_data; var age; run;												 									 
*/
				title;
				title "Soliris Cross-Tabular Frequency of Patients: Initial Dosage and Maintenance Dosage";
				title2 "January 1st, 2016 - March 31st, 2018, &admin_dx_type. Diagnosis";				
				proc freq data=inp.final_member_dosage_gaps_summary order=formatted; tables initial_dose*last_maint_dose / nopercent nocol nocum; where put(mbr_admin_dx,$dx_fmt.) = "&admin_dx_type."; run;
				title;
				title "Soliris Cross-Tabular Frequency of Patients: Initial Weight and Maintenance Weight";
				title2 "January 1st, 2016 - March 31st, 2018, &admin_dx_type. Diagnosis";				
				proc freq data=inp.final_member_dosage_gaps_summary order=formatted; tables initial_pt_wt*last_maint_pt_wt / nopercent nocol nocum; where put(mbr_admin_dx,$dx_fmt.) = "&admin_dx_type."; run;
				title;
				title "Soliris Cross-Tabular Frequency of Patients: Initial Dose and Initial Weight";
				title2 "January 1st, 2016 - March 31st, 2018, &admin_dx_type. Diagnosis";				
				proc freq data=inp.final_member_dosage_gaps_summary order=formatted; tables initial_pt_wt*initial_dose / nopercent nocol nocum; where put(mbr_admin_dx,$dx_fmt.) = "&admin_dx_type."; run;
				title;
				title "Soliris Cross-Tabular Frequency of Patients: Maintenance Dose and Maintenance Weight";
				title2 "January 1st, 2016 - March 31st, 2018, &admin_dx_type. Diagnosis";				
				proc freq data=inp.final_member_dosage_gaps_summary order=formatted; tables last_maint_pt_wt*last_maint_dose / nopercent nocol nocum; where put(mbr_admin_dx,$dx_fmt.) = "&admin_dx_type."; run;

				%let rg = %eval(&rg+1); 
				%let admin_dx_type 			= %scan(&admin_dx_types.,&rg,|);
				%end;	

				* ALL DIAGNOSES;
				/**/

				title;
				title "Soliris Frequency of Patients: Initial Dosage";
				title2 "January 1st, 2016 - March 31st, 2018, All Patients";				

				proc freq data=inp.final_member_dosage_gaps_summary order=formatted; tables initial_dose; run;

					data t&vz._aa; merge inp.final_member_dosage_gaps_summary(keep=panther_id initial_dose initial_pt_wt mbr_admin_dx) inp.final_pt; by panther_id; if put(mbr_admin_dx,$dx_fmt.) in ('PNH','aHUS','gMG') and initial_dose ^= ' '; run;	
					data t&vz._bb; merge inp.final_member_dosage_gaps_summary(keep=panther_id initial_dose initial_pt_wt mbr_admin_dx) inp.final_pt; by panther_id; if put(mbr_admin_dx,$dx_fmt.) in ('PNH','aHUS','gMG') and initial_dose = ' '; run;				
					data t&vz._aabb; merge inp.final_member_dosage_gaps_summary(keep=panther_id initial_dose initial_pt_wt mbr_admin_dx) inp.final_pt; by panther_id; if put(mbr_admin_dx,$dx_fmt.) in ('PNH','aHUS','gMG') and initial_dose ^= ' ' then initial_dose_data = "with_initial_dose_data"; if put(mbr_admin_dx,$dx_fmt.) in ('PNH','aHUS','gMG') and initial_dose = ' ' then initial_dose_data = "without_initial_dose_data"; if gender = 'FEMALE' then percent_female = 1; if gender = 'MALE' then percent_female = 0; run;				

					/*CHI-SQUARED*	
					proc means data=t&vz._aa maxdec=0 noprint; class age gender race region initial_pt_wt; var age; output out=t&vz._aabbsums_with n=patients; format age age_test_fmt. initial_pt_wt pt_wt_fmt. race $race_fmt.; run;
					data t&vz._aabbsums_with; set t&vz._aabbsums_with; test_group_nm = catx("_",put(age, age_test_fmt.),gender,put(race,$race_fmt.),region,put(initial_pt_wt,pt_wt_fmt.)); run;
					proc means data=t&vz._bb maxdec=0 noprint; class age gender race region initial_pt_wt; var age; output out=t&vz._aabbsums_wo n=patients; format age age_test_fmt. initial_pt_wt pt_wt_fmt. race $race_fmt.; run;
					data t&vz._aabbsums_wo; set t&vz._aabbsums_wo; test_group_nm = catx("_",put(age, age_test_fmt.),gender,put(race,$race_fmt.),region,put(initial_pt_wt,pt_wt_fmt.)); run;
					proc sql; 
						create table t&vz._aabbsums_all_with_wo as (
						select _type_ as test_number, test_group_nm, "With Initial Dose Data" as patient_category, patients from t&vz._aabbsums_with where _type_ > 0 
						union all
						select _type_ as test_number, test_group_nm, "Without Initial Dose Data" as patient_category, patients from t&vz._aabbsums_wo where _type_ > 0 
						); 
						quit;
						proc sort data=t&vz._aabbsums_all_with_wo; by test_number test_group_nm; run;			
						proc freq data=t&vz._aabbsums_all_with_wo noprint; by test_number; tables test_group_nm*patient_category / expected cellchi2 norow nocol chisq; output out=t&vz._chissq n nmiss pchi lrchi; weight patients; run;
						title;
						title "Chi-Squared Results: N-Way Examination of Age Group, Race Group, Region, Initial Weight Group and Gender of Soliris Patients with and without Initial Dose Data";			
						title2 "January 1st, 2016 - March 31st, 2018, &admin_dx_type. Diagnosis";	
						proc print data=t&vz._chissq noobs; run;
							
					/*T-TEST*	
					title;
					title "Two-Sample T-Test: Age Distribution of Soliris Patients with and without Initial Dose Data";
					title2 "January 1st, 2016 - March 31st, 2018, All Patients";	
					proc ttest data=t&vz._aabb plots(only)=summary; class initial_dose_data; var age; run;												 
*/
				title;
				title "Soliris Frequency of Patients: Initial Patient Weight";
				title2 "January 1st, 2016 - March 31st, 2018, All Patients";				

				title;
				title "Soliris Frequency of Patients: Most Recent Maintenance Dosage";
				title2 "January 1st, 2016 - March 31st, 2018, All Patients";				

				proc freq data=inp.final_member_dosage_gaps_summary order=formatted; tables last_maint_dose; run;

					data t&vz._aa; merge inp.final_member_dosage_gaps_summary(keep=panther_id initial_pt_wt last_maint_dose mbr_admin_dx) inp.final_pt; by panther_id; if put(mbr_admin_dx,$dx_fmt.) in ('PNH','aHUS','gMG') and last_maint_dose ^= ' '; run;	
					data t&vz._bb; merge inp.final_member_dosage_gaps_summary(keep=panther_id initial_pt_wt last_maint_dose mbr_admin_dx) inp.final_pt; by panther_id; if put(mbr_admin_dx,$dx_fmt.) in ('PNH','aHUS','gMG') and last_maint_dose = ' '; run;				
					data t&vz._aabb; merge inp.final_member_dosage_gaps_summary(keep=panther_id initial_pt_wt last_maint_dose mbr_admin_dx) inp.final_pt; by panther_id; if put(mbr_admin_dx,$dx_fmt.) in ('PNH','aHUS','gMG') and last_maint_dose ^= ' ' then last_maint_dose_data = "with_last_maint_dose_data"; if put(mbr_admin_dx,$dx_fmt.) in ('PNH','aHUS','gMG') and last_maint_dose = ' ' then last_maint_dose_data = "without_last_maint_dose_data"; if gender = 'FEMALE' then percent_female = 1; if gender = 'MALE' then percent_female = 0; run;				

					/*CHI-SQUARED*	
					proc means data=t&vz._aa maxdec=0; class age gender race region initial_pt_wt; var age; output out=t&vz._aabbsums_with n=patients; format age age_test_fmt. initial_pt_wt pt_wt_fmt. race $race_fmt.; run;
					proc print data=t&vz._aabbsums_with noobs; run;
					data t&vz._aabbsums_with; set t&vz._aabbsums_with; test_group_nm = catx("_",put(age, age_test_fmt.),gender,put(race,$race_fmt.),region,put(initial_pt_wt,pt_wt_fmt.)); run;
					proc means data=t&vz._bb maxdec=0 noprint; class age gender race region initial_pt_wt; var age; output out=t&vz._aabbsums_wo n=patients; format age age_test_fmt. initial_pt_wt pt_wt_fmt. race $race_fmt.; run;
					data t&vz._aabbsums_wo; set t&vz._aabbsums_wo; test_group_nm = catx("_",put(age, age_test_fmt.),gender,put(race,$race_fmt.),region,put(initial_pt_wt,pt_wt_fmt.)); run;
					proc sql; 
						create table t&vz._aabbsums_all_with_wo as (
						select _type_ as test_number, test_group_nm, "With Most Recent Maintenance Dose Data" as patient_category, patients from t&vz._aabbsums_with where _type_ > 0 
						union all
						select _type_ as test_number, test_group_nm, "Without Most Recent Maintenance Dose Data" as patient_category, patients from t&vz._aabbsums_wo where _type_ > 0 
						); 
						quit;
						proc sort data=t&vz._aabbsums_all_with_wo; by test_number test_group_nm; run;			
						proc freq data=t&vz._aabbsums_all_with_wo noprint; by test_number; tables test_group_nm*patient_category / expected cellchi2 norow nocol chisq; output out=t&vz._chissq n nmiss pchi lrchi; weight patients; run;
						title;
						title "Chi-Squared Results: N-Way Examination of Age Group, Race Group, Region, Initial Weight Group and Gender of Soliris Patients with and without Initial Dose Data";			
						title2 "January 1st, 2016 - March 31st, 2018, All Patients";	
						proc print data=t&vz._chissq noobs; run;
							
					/*T-TEST*	
					title;
					title "Two-Sample T-Test: Age Distribution of Soliris Patients with and without Most Recent Maintenance Dose Data";
					title2 "January 1st, 2016 - March 31st, 2018, All Patients";	
					proc ttest data=t&vz._aabb plots(only)=summary; class last_maint_dose_data; var age; run;												 
*/
				title;
				title "Soliris Cross-Tabular Frequency of Patients: Initial Dosage and Maintenance Dosage";
				title2 "January 1st, 2016 - March 31st, 2018, All Patients";				
				proc freq data=inp.final_member_dosage_gaps_summary order=formatted; tables initial_dose*last_maint_dose / nopercent nocol nocum; run;
				title;
				title "Soliris Cross-Tabular Frequency of Patients: Initial Weight and Maintenance Weight";
				title2 "January 1st, 2016 - March 31st, 2018, All Patients";				
				proc freq data=inp.final_member_dosage_gaps_summary order=formatted; tables initial_pt_wt*last_maint_pt_wt / nopercent nocol nocum; run;
				title;
				title "Soliris Cross-Tabular Frequency of Patients: Initial Dose and Initial Weight";
				title2 "January 1st, 2016 - March 31st, 2018, All Patients";				
				proc freq data=inp.final_member_dosage_gaps_summary order=formatted; tables initial_pt_wt*initial_dose / nopercent nocol nocum; run;
				title;
				title "Soliris Cross-Tabular Frequency of Patients: Maintenance Dose and Maintenance Weight";
				title2 "January 1st, 2016 - March 31st, 2018, All Patients";				
				proc freq data=inp.final_member_dosage_gaps_summary order=formatted; tables last_maint_pt_wt*last_maint_dose / nopercent nocol nocum; run;

/*------> END REPORTING OUTPUT <-----------------------------------------*/

*GRAPHICS OFF;
ods graphics off;

*END EXCEL OUTPUT;
ods excel close;

*DELETE ANY LEFTOVER DATA;
proc datasets nolist; delete t&vz.:; quit;
proc datasets nolist library=inp; delete t&vz.:; quit;  
proc datasets nolist library=inp; delete td&vz.:; quit; 
x rm -rf "&om_data./05_out_rep/*.png";
 
%mend;

/*-----------------------------------------------------------------*/
/*---> EXECUTE <---------------------------------------------------*/
/**/ 

%data_ehr;
