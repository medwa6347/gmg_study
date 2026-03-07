 /*----------------------------------------------------------------*\
 | STANDALONE ADHOC PNH/aHUS/gMG ANALYSIS FOR ALEXION - CLAIMS			|
 |  HTTP://DMO.OPTUM.COM/PRODUCTS/NHI.HTML													|
 | AUTHOR: MICHAEL EDWARDS 2018-06-28 AMDG                          |
 \*----------------------------------------------------------------*/													
/**/
                     
* COMMAND LINE;								
/*
cd /hpsaslca/mwe/alexion/pnh_ahus_gmg_201806/amdg
sas_tws 0500_soliris_claims.sas -autoexec /hpsaslca/mwe/alexion/pnh_ahus_gmg_201806/amdg/00_common/00_common.sas &                                                       
*/      

%macro data_claims;
	
%local vz; %let vz = 1;

*COMMON - REDUNDANT, FOR EXECUTION ON SAS EG;
%include "/hpsaslca/mwe/alexion/pnh_ahus_gmg_201806/amdg/00_common/00_common.sas";
%include "&om_macros./util_dummy_sheet.sas";

* PLACE-OF-SERVICE LU;
%include "&om_code./00_common/00_pos_lu.sas";

/*-----------------------------------------------------------------*/
/*---> SOLIRIS PROCEDURES, NDC, DXS <------------------------------*/
/**/
%let market_prc_cds = 'J1300';
%let market_ndc_cds = '25682000101';
%let pnh_dxs 			= 'D595';
%let ahus_dxs 		= 'D593';
%let gmg_dxs 			= 'G7000','G7001';

*NHI MX, RX CLAIM FIELDS;
%include "&om_code./0501_claims_flds.sas";

/*-----------------------------------------------------------------*/
/*---> DEFINE NHI CONNECTION <-----------------------------------------*/
/**
%local nhi_sbox nhi_view nhi_specs u mcr mcr_cohort com com_cohort;
%let NHI_Specs = user="&un_unix." password="&pw_unix." server="NHIProd";
%let nhi_sbox = NHIPDHMMSandbox;
%let nhi_view = STATEVIEW;
libname _sbox_ teradata &NHI_Specs schema="&nhi_sbox";
*DELETE ANY LEFTOVER NHI SANDBOX DATA;
proc datasets nolist library=_sbox_; delete t&vz.:; quit;  
proc datasets nolist library=_sbox_; delete td&vz.:; quit; 

/*-----------------------------------------------------------------*/
/*---> SOLIRIS MX CLAIMS <-----------------------------------------*/
/**

*CLEAR OUT NHI SPOOL SPACE;
%util_nhi_clear_spool;

%put NOTE: Pulling Market Claims...;

%let mx_tbl =  facility_claim;
%include "&om_code./0501_claims_flds.sas";

%let mx_claims_whr = 
         where (service_procedure_code in (&market_prc_cds.) 
         	 or mx.ndc_code in (&market_ndc_cds.)) 
         	 and mx.service_from_date between '2015-01-01' and '2015-12-31'; 

%let phy_flds = , ndc_unit_of_msr_cd as ndc_unit_of_msr_cd , nat_drg_cd_qty as nat_drg_cd_qty;

%let mx_claims = &mx_claims_flds. &mx_claims_from. &mx_claims_whr.;

* CREATE TEMPORARY MARKET MEMBERS TABLE IN NHI SANDBOX; 
%put Facility Claims...;
%put ;
proc sql noerrorstop;
   *----------------------------------------------------------------*;
   *---> DEFINE CONNECTIONS TO NHI DATABASE;
   connect to teradata as nhi_sbox(&NHI_Specs schema="&nhi_sbox" mode=teradata);
   connect to teradata as nhi_view(&NHI_Specs schema="&nhi_view" mode=teradata);
   *----------------------------------------------------------------*;
   *---> EXTRACT MARKET MEMBERS;
   execute(
      create table &nhi_sbox..t&vz._fac_claims as (
         
				&mx_claims.				
				  	      		
			) with data
   ) by nhi_sbox;       
   disconnect from nhi_sbox;
   disconnect from nhi_view;
quit;

data inp.t&vz._fac_claims; set _sbox_.t&vz._fac_claims; run;
proc datasets nolist library=_sbox_; delete t&vz._fac_claims; quit;  

*CLEAR OUT NHI SPOOL SPACE;
%util_nhi_clear_spool;

%let mx_tbl =  physician_claim;
%include "&om_code./0501_claims_flds.sas";
%let mx_claims = &mx_claims_flds. &phy_flds. &mx_claims_from. &mx_claims_whr.;

* CREATE TEMPORARY MARKET MEMBERS TABLE IN NHI SANDBOX; 
%put Physician claims...;
%put ;
proc sql noerrorstop;
   *----------------------------------------------------------------*;
   *---> DEFINE CONNECTIONS TO NHI DATABASE;
   connect to teradata as nhi_sbox(&NHI_Specs schema="&nhi_sbox" mode=teradata);
   connect to teradata as nhi_view(&NHI_Specs schema="&nhi_view" mode=teradata);
   *----------------------------------------------------------------*;
   *---> EXTRACT MARKET MEMBERS;
   execute(
      create table &nhi_sbox..t&vz._phy_claims  as (
				
				&mx_claims.
				  	      		
			) with data
   ) by nhi_sbox;       
   disconnect from nhi_sbox;
   disconnect from nhi_view;
quit; 

data inp.t&vz._phy_claims; set _sbox_.t&vz._phy_claims; run;
proc datasets nolist library=_sbox_; delete t&vz._phy_claims; quit;  

data inp.final_soliris_mx_claims_2015;
	length &mx_var_length.; 
	set inp.t&vz._fac_claims 
			inp.t&vz._phy_claims;  
run;
proc sort data=inp.final_soliris_mx_claims_2015; by individual_id service_from_date claim_id; run;

data inp.final_soliris_mx_claims;
	set inp.final_soliris_mx_claims; 
	if missing(srvc_unit_cnt) then srvc_unit_cnt = quantity_units;
	if srvc_unit_cnt = ' ' then srvc_unit_cnt = quantity_units; 
run;

data inp.final_soliris_mx_claims_2015;
	set inp.final_soliris_mx_claims_2015; 
	if missing(srvc_unit_cnt) then srvc_unit_cnt = quantity_units;
	if srvc_unit_cnt = ' ' then srvc_unit_cnt = quantity_units; 
run;
proc sort data=inp.final_soliris_mx_claims; by individual_id service_from_date claim_id; run;
proc sort data=inp.final_soliris_mx_claims_2015; by individual_id service_from_date claim_id; run;

/*-----------------------------------------------------------------*/
/*---> SOLARIS RX CLAIMS <-----------------------------------------*/
/**

	%let rx_com_claims = 
         select distinct
				   	rx.nhi_individual_id														as individual_id    					
				  , rx.nhi_claim_nbr 			  												as claim_nbr                    
				  , rx.fill_date                             				as fill_date                      
				  , ndc.code                              					as ndc                          
				  , rx.count_days_supply                     				as days_supply    
				  , rx.quantity_drug_units													as quantity_drug_units                
  				, pj.specialty_category_code 											as rx_prov_sp_code
				  , rx.amt_copay+rx.amt_deductible           				as copay_rx                     
				  , rx.amt_paid                              				as tot_allowed_rx               
				  , rx.specialty_phmcy                     					as specialty_ind           
				  , case when 
				  		rx.mail_order_ind in ('Y') 
				  			then 'M' 
				  		when rx.retail_phmcy	in ('Y') 
				  			then 'R' 
				  			else 'O' end 																as rx_location
				  , ndc.generic_ind																	as generic_ind
				  , case when 
				  		ndc.generic_ind = 1 
				  			then 'G' 
				  			else 'B'	end																as generic_desc
				  , ndc.ahfs_therapeutic_class_desc									as ahfs_class_desc
				  , ndc.brand_name																	as brand_name
				  , ndc.generic_name																as generic_name
           from &nhi_view..pharmacy_claim 									rx 
				 inner join member_coverage_month										mbr
    			 on rx.nhi_member_system_id=mbr.nhi_member_system_id
				 inner join 																				ndc 																									
				 	on rx.ndc_key = ndc.ndc_key
 		 		 left outer join provider 														pj 
					on rx.prescribing_provider_key = pj.provider_key
    		 where rx.ndc_code in (&market_ndc_cds.)
    		 	 and rx.fill_date between '2015-01-01' and '2015-12-31'; 

%let rx_mcr_claims = 
       	 select distinct 
				   	rx.nhi_individual_id														as individual_id    					
				  , rx.nhi_claim_nbr 			  												as claim_nbr                    
				  , rx.fill_date                             				as fill_date                      
				  , ndc.code                              					as ndc                          
				  , rx.count_days_supply                     				as days_supply                    
				  , rx.quantity_drug_units													as quantity_drug_units                
  				, pj.specialty_category_code 											as rx_prov_sp_code
				  , rx.amt_copay+rx.amt_deductible           				as copay_rx                     
				  , rx.amt_paid                              				as tot_allowed_rx               
				  , rx.specialty_phmcy                     					as specialty_ind           
				  , case when 
				  		rx.mail_order_ind in ('Y') 
				  			then 'M' 
				  		when rx.retail_phmcy	in ('Y') 
				  			then 'R' 
				  			else 'O' end 																as rx_location
				  , ndc.generic_ind																	as generic_ind
				  , case when 
				  		ndc.generic_ind = 1 
				  			then 'G' 
				  			else 'B'	end																as generic_desc
				  , ndc.ahfs_therapeutic_class_desc									as ahfs_class_desc
				  , ndc.brand_name																	as brand_name
				  , ndc.generic_name																as generic_name				  
         from &nhi_view..pharmacy_claim_partd 							rx 
				 inner join member_coverage_month_partd							mbr
    			 on rx.nhi_member_system_id=mbr.nhi_member_system_id
				 inner join 																				ndc 																									
				 	on rx.ndc_key = ndc.ndc_key
 		 		 left outer join provider 													pj 
					on rx.prescribing_provider_key = pj.provider_key
    		 where rx.ndc_code in (&market_ndc_cds.)
    		   and rx.fill_date between '2018-01-01' and '2018-03-31'; 

* EXTRACT RX CLAIM DATA; 		
%put Extracting Commercial rx claim data...;
proc sql noerrorstop;
   *----------------------------------------------------------------*;
   *---> DEFINE CONNECTIONS TO NHI DATABASE;
   connect to teradata as nhi_sbox(&NHI_Specs schema="&nhi_sbox" mode=teradata);
   connect to teradata as nhi_view(&NHI_Specs schema="&nhi_view" mode=teradata);
   *----------------------------------------------------------------*;
   *---> CREATE RX CLAIM FILE;
   execute(
      create table &nhi_sbox..t&vz._in_rx_q_com as (
				
				&rx_com_claims
				
			) with data
   ) by nhi_sbox;  
   disconnect from nhi_sbox;
   disconnect from nhi_view;
quit;

data inp.t&vz._in_rx_q_com; length &rx_var_length.; set _sbox_.t&vz._in_rx_q_com;       

* EXTRACT RX CLAIM DATA; 		
proc sql noerrorstop;
   *----------------------------------------------------------------*;
   *---> DEFINE CONNECTIONS TO NHI DATABASE;
   connect to teradata as nhi_sbox(&NHI_Specs schema="&nhi_sbox" mode=teradata);
   connect to teradata as nhi_view(&NHI_Specs schema="&nhi_view" mode=teradata);
   *----------------------------------------------------------------*;
   *---> CREATE RX CLAIM FILE;
   execute(
      create table &nhi_sbox..t&vz._in_rx_q_mcr as (

				&rx_mcr_claims

			) with data
   ) by nhi_sbox;  
   disconnect from nhi_sbox;
   disconnect from nhi_view;
quit;  

data inp.t&vz._in_rx_q_mcr; length &rx_var_length.; set _sbox_.t&vz._in_rx_q_mcr;               

data inp.t&vz._soliris_rx_claims_2015;
	length &rx_var_length.; 
	set inp.t&vz._in_rx_q_com 
			inp.t&vz._in_rx_q_mcr;  
run;
proc sort data=inp.t&vz._soliris_rx_claims_2015; by individual_id fill_date ndc; run;
/*	
* ASSIGN DX INFORMATION TO UNIQUE RX ADMIN PATIENTS;
* ONLY FOR THOSE RX PATIENTS WHO ARE NOT ALLREADY IN MX DATA;
 
* CREATE TEMPORARY COHORT TABLE; 										
%put Creating temp cohort table...;
%put ;
proc sql; create table _sbox_.t&vz._mkt_cohort (BULKLOAD=YES DBCOMMIT=0) 
	as (select distinct rx.individual_id 
			from inp.t&vz._soliris_rx_claims rx 
			left join inp.final_soliris_mx_claims mx 
				on rx.individual_id = mx.individual_id 
			where mx.individual_id is null); 
quit;

%let mx_tbl =  facility_claim;
%include "&om_code./0501_claims_flds.sas";
%let mkt_join = inner join &nhi_sbox..t&vz._mkt_cohort mkt on mx.nhi_individual_id = mkt.individual_id;	
%let mx_claims_whr = where mx.service_from_date between '2018-01-01' and '2018-03-31';
%let mx_claims = &mx_claims_flds. &mx_claims_from. &mkt_join. &mx_claims_whr.;

* CREATE TEMPORARY MARKET MEMBERS TABLE IN NHI SANDBOX; 
%put Facility Claims...;
%put ;
proc sql noerrorstop;
   *----------------------------------------------------------------*;
   *---> DEFINE CONNECTIONS TO NHI DATABASE;
   connect to teradata as nhi_sbox(&NHI_Specs schema="&nhi_sbox" mode=teradata);
   connect to teradata as nhi_view(&NHI_Specs schema="&nhi_view" mode=teradata);
   *----------------------------------------------------------------*;
   *---> EXTRACT MARKET MEMBERS;
   execute(
      create table &nhi_sbox..t&vz._fac_claims as (
         
				&mx_claims				
				  	      		
			) with data
   ) by nhi_sbox;       
   disconnect from nhi_sbox;
   disconnect from nhi_view;
quit;

data inp.t&vz._fac_claims; set _sbox_.t&vz._fac_claims; run;
proc datasets nolist library=_sbox_; delete t&vz._fac_claims; quit;  

*CLEAR OUT NHI SPOOL SPACE;
%util_nhi_clear_spool;

%let mx_tbl =  physician_claim;
%include "&om_code./0501_claims_flds.sas";
%let mx_claims = &mx_claims_flds. &phy_flds. &mx_claims_from. &mkt_join. &mx_claims_whr.;

* CREATE TEMPORARY MARKET MEMBERS TABLE IN NHI SANDBOX; 
%put Physician claims...;
%put ;
proc sql noerrorstop;
   *----------------------------------------------------------------*;
   *---> DEFINE CONNECTIONS TO NHI DATABASE;
   connect to teradata as nhi_sbox(&NHI_Specs schema="&nhi_sbox" mode=teradata);
   connect to teradata as nhi_view(&NHI_Specs schema="&nhi_view" mode=teradata);
   *----------------------------------------------------------------*;
   *---> EXTRACT MARKET MEMBERS;
   execute(
      create table &nhi_sbox..t&vz._phy_claims  as (
				
				&mx_claims
				  	      		
			) with data
   ) by nhi_sbox;       
   disconnect from nhi_sbox;
   disconnect from nhi_view;
quit; 

data inp.t&vz._phy_claims; set _sbox_.t&vz._phy_claims; run;
proc datasets nolist library=_sbox_; delete t&vz._phy_claims; quit;  

data inp.t&vz._soliris_rx_claims_find_dx;
	length &mx_var_length.; 
	set inp.t&vz._fac_claims 
			inp.t&vz._phy_claims;  
run;
proc sort data=inp.t&vz._soliris_rx_claims_find_dx; by individual_id service_from_date claim_id; run;	

/*-----------------------------------------------------------------*/
/*---> TAG DIAGNOSES <---------------------------------------------*/
/**

* TAG SOLIRIS CLAIMS;
data inp.t&vz._soliris_rx_claims_find_dx; 
	set inp.t&vz._soliris_rx_claims_find_dx; 
	by individual_id service_from_date claim_id;  
	array diag{9} dx1-dx9;
	 	do i=1 to 9;
   		if diag{i} in (&pnh_dxs) then mbr_admin_dx = "PNH";
   		if diag{i} in (&ahus_dxs) then mbr_admin_dx = "aHUS";
   		if diag{i} in (&gmg_dxs) then mbr_admin_dx = "gMG";  		
   	end; * <=== END DO BLOCK FOR DIAGNOSIS CODES;
run;
proc sql; create table inp.t&vz._find_dx_mbrs_a as select distinct individual_id, mbr_admin_dx from inp.t&vz._soliris_rx_claims_find_dx; quit;
proc print data=inp.t&vz._find_dx_mbrs_a noobs; run;
proc sql; create table inp.t&vz._find_dx_mbrs as select distinct individual_id, max(mbr_admin_dx) as mbr_admin_dx from inp.t&vz._find_dx_mbrs_a group by 1; quit;
proc print data=inp.t&vz._find_dx_mbrs noobs; run;

/*-----------------------------------------------------------------*/
/*---> FINALIZE RX CLAIMS <----------------------------------------*/
/**
data inp.final_soliris_rx_claims;
	merge inp.t&vz._soliris_rx_claims
				inp.t&vz._find_dx_mbrs (keep = individual_id mbr_admin_dx);
	by individual_id;
	if days_supply < 0 then delete;
run;

data inp.final_soliris_rx_claims;
	set inp.final_soliris_rx_claims;
	fill_thru_date = fill_date + days_supply;
run;

data inp.final_soliris_rx_claims_2015;
	set inp.final_soliris_rx_claims_2015;
	fill_thru_date = fill_date + days_supply;
run;
 
*------------------------------------------------------------------*;
*---> 2ND-PASS MX CLAIMS <-----------------------------------------*;	
/**

proc datasets nolist library=_sbox_; delete t&vz.:; quit; 	
* CREATE TEMPORARY COHORT TABLE; 										
%put Creating temp cohort table...;
%put ;
proc sql; create table _sbox_.t&vz._mkt_cohort (BULKLOAD=YES DBCOMMIT=0) 
	as (select distinct individual_id from (select individual_id from inp.final_soliris_mx_claims union all select individual_id from inp.final_soliris_rx_claims)); 
quit;

%let mx_tbl =  facility_claim;
%include "&om_code./0501_claims_flds.sas";
%let mx_claims = &mx_claims_flds. &mx_claims_from. &mkt_join. &mx_claims_whr.;

* CREATE TEMPORARY MARKET MEMBERS TABLE IN NHI SANDBOX; 
%put Facility Claims...;
%put ;
proc sql noerrorstop;
   *----------------------------------------------------------------*;
   *---> DEFINE CONNECTIONS TO NHI DATABASE;
   connect to teradata as nhi_sbox(&NHI_Specs schema="&nhi_sbox" mode=teradata);
   connect to teradata as nhi_view(&NHI_Specs schema="&nhi_view" mode=teradata);
   *----------------------------------------------------------------*;
   *---> EXTRACT MARKET MEMBERS;
   execute(
      create table &nhi_sbox..t&vz._fac_claims as (
         
				&mx_claims				
				  	      		
			) with data
   ) by nhi_sbox;       
   disconnect from nhi_sbox;
   disconnect from nhi_view;
quit;

data inp.t&vz._fac_claims; set _sbox_.t&vz._fac_claims; run;
proc datasets nolist library=_sbox_; delete t&vz._fac_claims; quit; 

*CLEAR OUT NHI SPOOL SPACE;
%util_nhi_clear_spool;

%let mx_tbl =  physician_claim;
%include "&om_code./0501_claims_flds.sas";
%let mx_claims = &mx_claims_flds. &phy_flds. &mx_claims_from. &mkt_join. &mx_claims_whr.;

* CREATE TEMPORARY MARKET MEMBERS TABLE IN NHI SANDBOX; 
%put Physician claims...;
%put ;
proc sql noerrorstop;
   *----------------------------------------------------------------*;
   *---> DEFINE CONNECTIONS TO NHI DATABASE;
   connect to teradata as nhi_sbox(&NHI_Specs schema="&nhi_sbox" mode=teradata);
   connect to teradata as nhi_view(&NHI_Specs schema="&nhi_view" mode=teradata);
   *----------------------------------------------------------------*;
   *---> EXTRACT MARKET MEMBERS;
   execute(
      create table &nhi_sbox..t&vz._phy_claims  as (
				
				&mx_claims
				  	      		
			) with data
   ) by nhi_sbox;       
   disconnect from nhi_sbox;
   disconnect from nhi_view;
quit; 

data inp.t&vz._phy_claims; set _sbox_.t&vz._phy_claims; run;
proc datasets nolist library=_sbox_; delete t&vz._phy_claims; quit;  

data inp.final_soliris_all_claims;
	length &mx_var_length.; 
	set inp.t&vz._fac_claims 
			inp.t&vz._phy_claims;  
run;
proc sort data=inp.final_soliris_all_claims; by individual_id service_from_date claim_id; run;	

/*-----------------------------------------------------------------*/
/*---> TAG DIAGNOSES <---------------------------------------------*/
/**

* TAG 2ND PASS CLAIMS;
data inp.final_soliris_all_claims; 
	set inp.final_soliris_all_claims; 
	by individual_id service_from_date claim_id;  
  if service_procedure_code in (&market_prc_cds.) and ndc in (&market_ndc_cds.) then soliris_admin = "Y";
run;						 

*----------------------------------------------------------------*;
*---> ENROLLMENT COVERAGE DATA <---------------------------------*;	
/**

proc datasets nolist library=_sbox_; delete t&vz.:; quit; 	
* CREATE TEMPORARY COHORT TABLE; 										
%put Creating temp cohort table...;
%put ;
proc sql; create table _sbox_.t&vz._mkt_cohort (BULKLOAD=YES DBCOMMIT=0) 
	as (select distinct individual_id from (select individual_id from inp.final_soliris_mx_claims union all select individual_id from inp.final_soliris_rx_claims)); 
quit;

%put Extracting enrollment coverage data...;
%put ;
* EXTRACT ENROLLMENT COVERAGE DATA; 										
proc sql noerrorstop;
   *----------------------------------------------------------------*;
   *---> DEFINE CONNECTIONS TO NHI DATABASE;
   connect to teradata as nhi_sbox(&NHI_Specs schema="&nhi_sbox" mode=teradata);
   connect to teradata as nhi_view(&NHI_Specs schema="&nhi_view" mode=teradata);
   *----------------------------------------------------------------*;
   *---> CREATE ENROLLMENT COVERAGE DATA FILE;
   execute(
      create table &nhi_sbox..t&vz._in_cov as (
         select distinct
				   cov.nhi_individual_id															as individual_id
				 , cov.eff_date																				as cov_eff_date
				 , cov.end_date																				as cov_end_date
				 , cov.Medical_Coverage_Ind                           as med_cov_ind
         , cov.Pharmacy_Coverage_Ind													as pharm_cov_ind
         from &nhi_view..member_coverage_month								cov
 			 	 inner join &nhi_sbox..t&vz._mkt_cohort								mkt
				 	 on cov.nhi_individual_id = mkt.individual_id	
				 where eff_date > '2015-01-01'
				 
				 union all
				 
				 select distinct 
				   cov.nhi_individual_id															as individual_id
				 , cov.eff_date																				as cov_eff_date
				 , cov.end_date																				as cov_end_date
				 , cov.Medical_Coverage_Ind                           as med_cov_ind
         , cov.Pharmacy_Coverage_Ind													as pharm_cov_ind
         from &nhi_view..member_coverage_month_partd					cov
 			 	 inner join &nhi_sbox..t&vz._mkt_cohort								mkt
				 	 on cov.nhi_individual_id = mkt.individual_id	
				 where eff_date > '2015-01-01'				 
			) with data
   ) by nhi_sbox;     
   disconnect from nhi_sbox;
   disconnect from nhi_view;
quit;

* CREATE MEMBER COHORT COVERAGE LU TABLE; 
data inp.t&vz._in_cov; set _sbox_.t&vz._in_cov; run;
proc datasets nolist library=_sbox_; delete t&vz._in_cov:; quit;

proc sort nodupkey data=inp.t&vz._in_cov; by individual_id cov_eff_date; run;
data inp.final_memcov(sortedby=individual_id); 
	set inp.t&vz._in_cov;
	where med_cov_ind in ('Y') and pharm_cov_ind in ('Y','P'); 
	by individual_id; 
	retain min_cov_date cov_thru_date max_cov_date; 
	cov_thru_date = lag(cov_end_date);
	if first.individual_id and last.individual_id then do;
		 min_cov_date = cov_eff_date;
		 max_cov_date = cov_end_date;
		 output; end;
	if first.individual_id then min_cov_date = cov_eff_date;
  if lag(individual_id) = individual_id and
  	cov_eff_date - cov_thru_date > 2 then do;  	
  	max_cov_date = cov_thru_date; 
  	output; 
  	min_cov_date = cov_eff_date;
  	end;
  if last.individual_id then do;
  	if cov_end_date ne max_cov_date then do;
 		max_cov_date = cov_end_date; output; end;
  end;
  keep individual_id min_cov_date max_cov_date;
  format min_cov_date max_cov_date mmddyy10.;
run;

*----------------------------------------------------------------*;
*---> STAGE REPORTING DATA <-------------------------------------*;	
/**/

data inp.t&vz._member_dosage_a_lb; 
	set inp.final_soliris_mx_claims (
			keep= individual_id service_from_date service_thru_date nodup_chg_amt_mx srvc_unit_cnt mbr_admin_dx pos_cd 
			rename=(service_from_date = admin_date service_thru_date = admin_bill_thru_date srvc_unit_cnt = admin_cnt nodup_chg_amt_mx = admin_allowed)
			)
			inp.final_soliris_rx_claims	(
			keep= individual_id fill_date fill_thru_date tot_allowed_rx quantity_drug_units mbr_admin_dx rx_location 
			rename=(fill_date = admin_date fill_thru_date = admin_bill_thru_date quantity_drug_units = admin_cnt tot_allowed_rx = admin_allowed)
			)
	 		inp.final_soliris_mx_claims_2015 (
			keep= individual_id service_from_date service_thru_date nodup_chg_amt_mx srvc_unit_cnt pos_cd 
			rename=(service_from_date = admin_date service_thru_date = admin_bill_thru_date srvc_unit_cnt = admin_cnt nodup_chg_amt_mx = admin_allowed)
			)
			inp.final_soliris_rx_claims_2015 (
			keep= individual_id fill_date fill_thru_date tot_allowed_rx quantity_drug_units rx_location 
			rename=(fill_date = admin_date fill_thru_date = admin_bill_thru_date quantity_drug_units = admin_cnt tot_allowed_rx = admin_allowed)
			);
run;
proc sort data=inp.t&vz._member_dosage_a_lb; by individual_id admin_date; run;

data inp.t&vz._member_dosage_a; 
	set inp.final_soliris_mx_claims (
			keep= individual_id service_from_date service_thru_date nodup_chg_amt_mx srvc_unit_cnt mbr_admin_dx pos_cd 
			rename=(service_from_date = admin_date service_thru_date = admin_bill_thru_date srvc_unit_cnt = admin_cnt nodup_chg_amt_mx = admin_allowed)
			)
			inp.final_soliris_rx_claims	(
			keep= individual_id fill_date fill_thru_date tot_allowed_rx quantity_drug_units mbr_admin_dx rx_location 
			rename=(fill_date = admin_date fill_thru_date = admin_bill_thru_date quantity_drug_units = admin_cnt tot_allowed_rx = admin_allowed)
			);
run;
proc sort data=inp.t&vz._member_dosage_a; by individual_id admin_date; run;

*----------------------------------------------------------------*;
*---> SOLIRIS ADMINS, DOSAGE, ALLOWED DATA STAGING <-------------*;	
/**/
data inp.t&vz._member_dosage_b; set inp.t&vz._member_dosage_a; run;

data inp.t&vz._member_dosage; 
	set inp.t&vz._member_dosage_b;		 
	by individual_id admin_date;
	mbr_admin_year = year(admin_date);
	if first.admin_date then do; 
		sum_allowed = 0;
		first_admin_date = admin_date;  
		end;
	sum_allowed+admin_allowed;
	if last.admin_date then do; sum_dosage = admin_cnt; output; end;
	keep individual_id first_admin_date admin_date admin_bill_thru_date sum_allowed sum_dosage mbr_admin_year mbr_admin_dx pos_cd rx_location;
	format admin_date first_admin_date mmddyy10. sum_allowed dollar9.2;
run;

*----------------------------------------------------------------*;
*---> ESTABLISH CLEAN PATIENTS <---------------------------------*;	
/**/
data inp.t&vz._member_dosage_first; set inp.t&vz._member_dosage; keep individual_id first_admin_date; run;
proc sort data=inp.t&vz._member_dosage_first nodupkey; by individual_id; run;
data inp.t&vz._member_dosage_a_lb_clean_a; 
	merge inp.t&vz._member_dosage_a_lb (keep=individual_id admin_date) inp.t&vz._member_dosage_first inp.final_memcov; 
	by individual_id; 
run; 
data inp.final_member_dosage_a_lb_clean(sortedby=individual_id); 
	set inp.t&vz._member_dosage_a_lb_clean_a; 
	by individual_id;
	if first.individual_id then do; clean = 0; dirty = 0; end;
	if first_admin_date - 365 <= admin_date < first_admin_date then dirty = 1;
	if min_cov_date + 365 <= first_admin_date and clean = 0 and dirty = 0 then do; clean = 1; output; end;
	keep individual_id clean; 
run;  	
 
*----------------------------------------------------------------*;
*---> SOLIRIS MEMBERS BY DX <------------------------------------*;
/**/
proc sql;
	create table inp.final_pnh as (select distinct individual_id, mbr_admin_dx from inp.t&vz._member_dosage where mbr_admin_dx = 'PNH');
	create table inp.final_ahus as (select distinct individual_id, mbr_admin_dx from inp.t&vz._member_dosage where mbr_admin_dx = 'aHUS');
	create table inp.final_gmg as (select distinct individual_id, mbr_admin_dx from inp.t&vz._member_dosage where mbr_admin_dx = 'gMG');
	create table inp.t&vz._all_pnh_ahus_gmg_all as (select * from inp.final_pnh union all select * from inp.final_ahus union all select * from inp.final_gmg);
	create table inp.t&vz._all_pnh_ahus_gmg as (select distinct individual_id from inp.t&vz._all_pnh_ahus_gmg_all);
	create table inp.final_other as (
		select distinct dos.individual_id
				, "Other" as mbr_admin_dx 
				from inp.t&vz._member_dosage dos 
				left join inp.t&vz._all_pnh_ahus_gmg al 
					on dos.individual_id = al.individual_id 
		where al.individual_id is null and mbr_admin_dx not in ('aHUS','gMG','PNH')
		); 
	create table inp.final_member_dosage_dx_a as (
		select sd.*, mbr.mbr_admin_dx from inp.t&vz._member_dosage sd inner join inp.final_pnh mbr on sd.individual_id = mbr.individual_id
		union all
		select sd.*, mbr.mbr_admin_dx from inp.t&vz._member_dosage sd inner join inp.final_ahus mbr on sd.individual_id = mbr.individual_id
		union all
		select sd.*, mbr.mbr_admin_dx from inp.t&vz._member_dosage sd inner join inp.final_gmg mbr on sd.individual_id = mbr.individual_id
		union all
		select sd.*, mbr.mbr_admin_dx from inp.t&vz._member_dosage sd inner join inp.final_other mbr on sd.individual_id = mbr.individual_id
); 
quit;
data inp.final_member_dosage_dx_b; set inp.final_member_dosage_dx_a; if missing(mbr_admin_dx) then mbr_admin_dx = "Other"; if '01Jan2018'd <= admin_date <= '31Mar2018'd; run;
proc sql; create table inp.final_member_dosage_dx as (
	select dos.*, cln.clean 
	from inp.final_member_dosage_dx_b dos 
	left outer join inp.final_member_dosage_a_lb_clean cln 
		on dos.individual_id = cln.individual_id); 
quit;

*----------------------------------------------------------------*;
*---> SOLIRIS PLACE-OF-SERVICE ANALYSIS <------------------------*;	
/**
proc sql;
create table inp.final_pos_soliris as (
   select 
   	mx.mbr_admin_dx
   , mx.mbr_admin_year
   , lu.mx_index_pos_desc 			 as pos_desc 
   from inp.final_member_dosage_dx mx 
   inner join inp.r&vz._pos2desc_lu lu 
   	on mx.pos_cd = lu.pos
   where pos_cd is not null
   	union all
   select 
   rx.mbr_admin_dx
   , rx.mbr_admin_year
   , case when rx.rx_location in ('R') then "Retail Pharmacy" 
   				when rx.rx_location in ('O') then "Other Pharmacy" 
   																		 else "Other Pharmacy" 
   												  end as pos_desc
   from inp.final_member_dosage_dx rx
   where rx_location is not null
);   			          
quit; 

*----------------------------------------------------------------*;
*---> SOLIRIS SAME-DAY SERVICES ANALYSIS <-----------------------*;	
/**
data inp.t&vz._same_mx_day_claims; 
	merge inp.final_soliris_all_claims(in=a drop=mbr_admin_dx)
				inp.final_soliris_all_claims(where=(soliris_admin in ('Y')) keep=individual_id service_from_date soliris_admin in=b);
	by individual_id service_from_date;  
	if b;
run;
	
proc sql; 
	create table inp.final_same_mx_day_claims as (
		select sd.*, mbr.mbr_admin_dx from inp.t&vz._same_mx_day_claims sd inner join inp.final_pnh mbr on sd.individual_id = mbr.individual_id
		union all
		select sd.*, mbr.mbr_admin_dx from inp.t&vz._same_mx_day_claims sd inner join inp.final_ahus mbr on sd.individual_id = mbr.individual_id
		union all
		select sd.*, mbr.mbr_admin_dx from inp.t&vz._same_mx_day_claims sd inner join inp.final_gmg mbr on sd.individual_id = mbr.individual_id
		union all
		select sd.*, mbr.mbr_admin_dx from inp.t&vz._same_mx_day_claims sd inner join inp.final_other mbr on sd.individual_id = mbr.individual_id
); 
quit;

 /*-----------------------------------------------------------------*/
 /*---> SOLIRIS REPORTING OUTPUT <----------------------------------*/
/**/

%let rp_hcp 	= "&om_data./05_out_rep/Alexion_Soliris_Claims_Analysis_2016_18_initial_cleanpats_dose_adjust_v2_2018_only.xls";

* GLOBAL FORMATS;
%include "&om_code./00_formats/fmt_reporting.sas";

* GRAPHICS ON;
ods listing close;
ods listing gpath="&om_data./05_out_rep/";
ods output; ods graphics on;

%put Outputting Reporting...;

	/*-----------------------------------------------------------------*/
	/*---> REPORT: SOLIRIS MX CLAIMS DETAIL <--------------------------*/
	/**/   
	
			* EXCEL REPORT;
			Ods excel file=&rp_hcp. style=XL&vz.sansPrinter
					options
					(
						sheet_name="Soliris_Mx_Claim_Dtl"
						sheet_interval='none'
						embedded_titles='yes'
					);
					
				*proc print data=inp.final_soliris_mx_claims; run;	
					
				%util_dummy_sheet; 

	/*-----------------------------------------------------------------*/
	/*---> REPORT: SOLIRIS DOSAGE, ALLOWED ROLLUP DETAIL <-------------*/
	/**/   
	
			* EXCEL REPORT;
			Ods excel 
					options
					(
						sheet_name="Soliris_Dosage_Rollup_Dtl"
						sheet_interval='none'
						embedded_titles='yes'
					);
					
				*proc print data=inp.final_member_dosage_dx; run;
					
				%util_dummy_sheet; 
				
	/*-----------------------------------------------------------------*/
	/*---> REPORT: SOLIRIS ADMIN, ALLOWED SUMMARY <--------------------*/
	/**/    
	
			* EXCEL REPORT;
			Ods excel 
					options
					(
						sheet_name="Soliris_Admin_Allow"
						sheet_interval='none'
						embedded_titles='yes'
					);
					
					title "Solaris Administration and Allowed Summary";
					title2 "January 1st, 2018 - March 31st, 2018, by Patient Diagnosis and Administration Year";
					proc summary
					data=inp.final_member_dosage_dx maxdec=1;
						var sum_allowed;
						class mbr_admin_dx mbr_admin_year;
						output out=t&vz._a (drop=_freq_)
						sum=Solaris_Allowed n=Solaris_Admins mean=Avg_Solaris_Admin_Allowed median=Medn_Solaris_Admin_Allowed;				
					run;		
					data t&vz._b; 
						set t&vz._a; 
						where _type_ = 3; 
						drop _type_; 
						format Solaris_Admins comma9. Solaris_Allowed Avg_Solaris_Admin_Allowed Medn_Solaris_Admin_Allowed dollar12.2; 
					run;
					proc sql; 
						create table t&vz._dx_sum as 
						select mbr_admin_year
								 , mbr_admin_dx
								 , count(distinct individual_id) as Patients 
						from inp.final_member_dosage_dx 
						group by 1,2; 
					quit;
					proc sort data=t&vz._b; by mbr_admin_dx mbr_admin_year; run;
					proc sort data=t&vz._dx_sum; by mbr_admin_dx mbr_admin_year; run;
					data t&vz._c; 
						merge t&vz._b t&vz._dx_sum; 
						by mbr_admin_dx mbr_admin_year; 
						Avg_Solaris_Mbr_Allowed = Solaris_Allowed / Patients; 
						format Patients comma9. Avg_Solaris_Mbr_Allowed dollar12.2; 
					run;   
					proc print data=t&vz._c noobs; run;			
										
				%util_dummy_sheet; 

	/*-----------------------------------------------------------------*/
	/*---> REPORT: DOSAGE, GAPS ANALYSIS <-----------------------------*/
	/**/   
	
			* EXCEL REPORT;
			Ods excel 
					options
					(
						sheet_name="Soliris_Therapy_and_Dosage"
						sheet_interval='none'
						embedded_titles='yes'
					);
				
				proc sort data=inp.final_member_dosage_dx; by individual_id admin_date; run;
				data inp.final_member_dosage_gaps_dtl; 
					set inp.final_member_dosage_dx; 
					by individual_id admin_date; 
					retain first_min_admin_date min_admin_date admin_thru_date max_admin_date initial_dosage maint_dose therapy_gap gap; 
					admin_thru_date = lag(admin_date);
					if first.individual_id and last.individual_id then do;
						first_min_admin_date = admin_date;
						min_admin_date = admin_date;
						max_admin_date = admin_date;
						if admin_bill_thru_date - admin_date < 10 then initial_dosage = sum_dosage;
						if 10 <= admin_bill_thru_date - admin_date <= 25 then initial_dosage = sum_dosage;
						if admin_bill_thru_date - admin_date >= 26 then initial_dosage = sum_dosage/2;
						maint_dose = 0;
						continuous_therapy_length = admin_bill_thru_date - admin_date; 
						total_therapy_length = admin_bill_thru_date - admin_date;
						gap = 0;
						output; end;
					if first.individual_id then do; 
						first_min_admin_date = admin_date; 
						min_admin_date = admin_date;
						if admin_bill_thru_date - admin_date < 10 then initial_dosage = sum_dosage;
						if 10 <= admin_bill_thru_date - admin_date <= 25 then initial_dosage = sum_dosage;
						if admin_bill_thru_date - admin_date >= 26 then initial_dosage = sum_dosage/2;
						end;
			  	if admin_date- admin_thru_date > 16 and lag(individual_id) = individual_id then do;  	
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
			  if last.individual_id then do;
			  	  if admin_date - admin_thru_date < 10 then do;
			  			max_admin_date = admin_date; 
			  			maint_dose = sum_dosage; 
			  			continuous_therapy_length = admin_date- min_admin_date; 
			  			total_therapy_length = admin_date- first_min_admin_date;
			  			gap = 0;
			  			output; end;
			  	  if 10 <= admin_date - admin_thru_date <= 25 then do;
			  			max_admin_date = admin_date; 
			  			maint_dose = sum_dosage; 
			  			continuous_therapy_length = admin_date- min_admin_date; 
			  			total_therapy_length = admin_date- first_min_admin_date;
			  			gap = 0;
			  			output; end;
			  	  if admin_date - admin_thru_date >= 26 then do;
			  			max_admin_date = admin_date; 
			  			maint_dose = sum_dosage/2; 
			  			continuous_therapy_length = admin_date- min_admin_date; 
			  			total_therapy_length = admin_date- first_min_admin_date;
			  			gap = 0;
			  			output; end;
			  	end;			  			
					keep individual_id min_admin_date max_admin_date continuous_therapy_length total_therapy_length therapy_gap gap initial_dosage maint_dose clean;
					format min_admin_date max_admin_date mmddyy10.;
				run;
				data inp.t&vz._member_dosage_gaps_summary_a; 
					set inp.final_member_dosage_gaps_dtl;
					by individual_id; 
					retain initial_dose last_maint_dose;
					if first.individual_id then initial_dose = initial_dosage; 
					if last.individual_id then do;
						last_maint_dose = maint_dose;
						output;
						end;
					keep individual_id initial_dose last_maint_dose total_therapy_length clean;
				run;
				proc sql; create table inp.t&vz._member_dosage_gaps_summary_b as 
					select individual_id
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
				proc sort data=inp.t&vz._member_dosage_gaps_summary_a; by individual_id; run;
				proc sort data=inp.t&vz._member_dosage_gaps_summary_b; by individual_id; run;					
				data inp.t&vz._member_dosage_gaps_summary; merge inp.t&vz._member_dosage_gaps_summary_a inp.t&vz._member_dosage_gaps_summary_b; by individual_id; 
					if total_therapy_length = 0 then delete;
					/*if 20 <= median_therapy_gap <= 22 and initial_dose > 90  then initial_dose = initial_dose*(3/4); 
					if 20 <= median_therapy_gap <= 22 and last_maint_dose > 90  then last_maint_dose = last_maint_dose*(3/4);
					if 27 <= median_therapy_gap <= 29 and initial_dose > 90  then initial_dose = initial_dose*(1/2); 
					if 27 <= median_therapy_gap <= 29 and last_maint_dose > 90  then last_maint_dose = last_maint_dose*(1/2);*/
					format min_admin_date max_admin_date mmddyy10.;
					run;
				proc sql; 
						create table inp.final_member_dosage_gaps_summary as (
							select dg.*, mbr.mbr_admin_dx from inp.t&vz._member_dosage_gaps_summary dg inner join inp.final_pnh mbr on dg.individual_id = mbr.individual_id
							union all
							select dg.*, mbr.mbr_admin_dx from inp.t&vz._member_dosage_gaps_summary dg inner join inp.final_ahus mbr on dg.individual_id = mbr.individual_id
							union all
							select dg.*, mbr.mbr_admin_dx from inp.t&vz._member_dosage_gaps_summary dg inner join inp.final_gmg mbr on dg.individual_id = mbr.individual_id
							union all
							select dg.*, mbr.mbr_admin_dx from inp.t&vz._member_dosage_gaps_summary dg inner join inp.final_other mbr on dg.individual_id = mbr.individual_id
					); 
				quit;
				/*
				title "Solaris Claim Detail";
				title2 "January 1st, 2018 - March 31st, 2018";
				proc print data=inp.final_member_dosage_dx noobs; run;
				title "Solaris Days of Therapy Gap Detail";
				title2 "January 1st, 2018 - March 31st, 2018, by Patient Diagnosis";
				proc print data=inp.final_member_dosage_gaps_dtl noobs; run;
				title "Solaris Days of Therapy Gap Summary";
				title2 "January 1st, 2018 - March 31st, 2018, by Patient Diagnosis";
				proc print data=inp.final_member_dosage_gaps_summary noobs; run;					
				*/
				title "Solaris Days of Therapy Gap Summary";
				title2 "January 1st, 2018 - March 31st, 2018, by Patient Diagnosis";
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
				proc print data=t&vz._b noobs; run;	
				*---> BEGIN REPORTING GROUP LOOP <-------------------------------*
				%let admin_dx_types = PNH | aHUS | gMG ;
				%let rg=1; 
				%let admin_dx_type 			= %scan(&admin_dx_types.,&rg,|);
				%do %while (&admin_dx_type ne);	

				title "Solaris Frequency of Patients: Initial Dosage";
				title2 "January 1st, 2018 - March 31st, 2018, &admin_dx_type. Diagnosis";			
				title3 "NOTE: Naive Soliris Patients Only";	
				proc freq data=inp.final_member_dosage_gaps_summary order=formatted; tables initial_dose; where mbr_admin_dx = "&admin_dx_type." and clean=1; format initial_dose last_maint_dose dose_fmt.; run;
				title "Solaris Frequency of Patients: Maintenance Dosage";
				title2 "January 1st, 2018 - March 31st, 2018, &admin_dx_type. Diagnosis";			
				proc freq data=inp.final_member_dosage_gaps_summary order=formatted; tables last_maint_dose; where mbr_admin_dx = "&admin_dx_type." and total_therapy_length >= 30; format initial_dose last_maint_dose dose_fmt.; run;

				title "Solaris Cross-Tabular Frequency of Patients: Initial Dosage and Maintenance Dosage";
				title2 "January 1st, 2018 - March 31st, 2018, &admin_dx_type. Diagnosis";		
				title3 "NOTE: Naive Soliris Patients Only";	
				proc freq data=inp.final_member_dosage_gaps_summary order=formatted; tables initial_dose*last_maint_dose / nopercent nocol nocum; where mbr_admin_dx = "&admin_dx_type." and clean=1 and total_therapy_length >= 30; format initial_dose last_maint_dose dose_fmt.; run;

				%let rg = %eval(&rg+1); 
				%let admin_dx_type 			= %scan(&admin_dx_types.,&rg,|);
				%end;	
	
				title "Solaris Frequency of Patients: Initial Dosage";
				title2 "January 1st, 2018 - March 31st, 2018, All Patients";			
				title3 "NOTE: Naive Soliris Patients Only";	
				proc freq data=inp.final_member_dosage_gaps_summary order=formatted; tables initial_dose; where clean=1; format initial_dose last_maint_dose dose_fmt.; run;
				title "Solaris Frequency of Patients: Maintenance Dosage";
				title2 "January 1st, 2018 - March 31st, 2018, All Patients";			
				proc freq data=inp.final_member_dosage_gaps_summary order=formatted; tables last_maint_dose; where total_therapy_length >= 30; format initial_dose last_maint_dose dose_fmt.; run;

				title "Solaris Cross-Tabular Frequency of Patients: Initial Dosage and Maintenance Dosage";
				title2 "January 1st, 2018 - March 31st, 2018, All Patients";		
				title3 "NOTE: Naive Soliris Patients Only";	
				proc freq data=inp.final_member_dosage_gaps_summary order=formatted; tables initial_dose*last_maint_dose / nopercent nocol nocum; where clean=1 and total_therapy_length >= 30; format initial_dose last_maint_dose dose_fmt.; run;

%util_dummy_sheet; 				

	/*-----------------------------------------------------------------*/
	/*---> REPORT: POS <-----------------------------------------------*/
	/**    
	
			* EXCEL REPORT;
			Ods excel 
					options
					(
						sheet_name="Soliris_Place_of_Service"
						sheet_interval='none'
						embedded_titles='yes'
					);
				
				*---> BEGIN REPORTING GROUP LOOP <-------------------------------*
				%let admin_dx_types = PNH | aHUS | gMG ;
				%let rg=1; 
				%let admin_dx_type 			= %scan(&admin_dx_types.,&rg,|);
				%do %while (&admin_dx_type ne);	

				title "Distribution of Solaris Administration Place-of-Service";
				title2 "January 1st, 2018 - March 31st, 2018, by Administration Year, &admin_dx_type. Diagnosis";
				proc freq data=inp.final_pos_soliris order=freq; tables mbr_admin_year*pos_desc / nocol norow nocum; where mbr_admin_dx = "&admin_dx_type."; run;
				
				%let rg = %eval(&rg+1); 
				%let admin_dx_type 			= %scan(&admin_dx_types.,&rg,|);
				%end;

				title "Distribution of Solaris Administration Place-of-Service";
				title2 "January 1st, 2018 - March 31st, 2018, by Administration Year, All Patients";
				proc freq data=inp.final_pos_soliris order=formatted; tables mbr_admin_year*pos_desc / nocol norow nocum; run;
						
				%util_dummy_sheet; 			

	/*-----------------------------------------------------------------*/
	/*---> REPORT: SOLIRIS RX CLAIMS <---------------------------------*/
	/**/    
	
			* EXCEL REPORT;
			Ods excel
					options
					(
						sheet_name="Soliris_Rx_Claim_Dtl"
						sheet_interval='none'
						embedded_titles='yes'
					);
					
				*proc print data=inp.final_soliris_rx_claims; run;	
					
				%util_dummy_sheet; 

	/*-----------------------------------------------------------------*/
	/*---> REPORT: SAME-DAY CLAIMS ANALYSIS <--------------------------*/
	/**
	
			* EXCEL REPORT;
			Ods excel 
					options
					(
						sheet_name="Soliris_Same_Day_Procedures"
						sheet_interval='none'
						embedded_titles='yes'
					);
					
				*---> BEGIN REPORTING GROUP LOOP <-------------------------------*
				%let admin_dx_types = PNH | aHUS | gMG ;
				%let rg=1; 
				%let admin_dx_type 			= %scan(&admin_dx_types.,&rg,|);
				%do %while (&admin_dx_type ne);				

					* REPORT DATA STAGING; * BY ADMIN_DX_TYPE;
					proc sql; create table t&vz._sd_claims as (select distinct individual_id, put(service_procedure_code,$proc_cd_fmt.) as proc_cat, service_from_date from inp.final_same_mx_day_claims where mbr_admin_dx = "&admin_dx_type." and service_procedure_code is not null group by 1,2,3); quit;
					proc sql; create table t&vz._sd_pats as (select distinct individual_id, put(service_procedure_code,$proc_cd_fmt.) as proc_cat from inp.final_same_mx_day_claims where mbr_admin_dx = "&admin_dx_type." and service_procedure_code is not null group by 1,2); quit;	
					proc sql; create table t&vz._sd_cost as (select distinct put(service_procedure_code,$proc_cd_fmt.) as proc_cat, sum(nodup_chg_amt_mx) as proc_allowed from inp.final_same_mx_day_claims where mbr_admin_dx = "&admin_dx_type." and service_procedure_code is not null group by 1); quit;	
					proc freq data=t&vz._sd_claims noprint order=freq; tables proc_cat / out = t&vz._sd_claims; run;
					proc sort data=t&vz._sd_claims; by proc_cat; run;
					proc freq data=t&vz._sd_pats noprint order=freq; tables proc_cat / out = t&vz._sd_pats; run;
					proc sort data=t&vz._sd_pats; by proc_cat; run;	
					data t&vz._sd_rpt_a; 
						merge t&vz._sd_claims (in = a keep = proc_cat count rename=(count = claims)) 
									t&vz._sd_pats 	(in = b keep = proc_cat count rename=(count = patients))
									t&vz._sd_cost		(in = c);
						by proc_cat;
						if a and b and c;
					run;
					proc sort nodupkey data=t&vz._sd_rpt_a; by proc_cat; run;
					proc sql; create table t&vz._denoms as select max(patients) as d_pats, max(claims) as d_claims from t&vz._sd_rpt_a; quit;
					data _null_; set t&vz._denoms; call symput ("d_pats", d_pats); call symput ("d_claims", d_claims); run; 
					data t&vz._sd_rpt; set t&vz._sd_rpt_a; percent_patients = patients / &d_pats.; percent_claims = claims / &d_claims.; avg_claim = proc_allowed / claims; format percent_patients percent_claims percent9.2 claims patients comma9. proc_allowed avg_claim dollar12.2; run;
					proc sort data=t&vz._sd_rpt; by descending patients; run;
					* OUTPUT REPORT;
					title "Solaris Administrations: Same-Day Procedures Distribution, &admin_dx_type. Diagnosis";
					title2 ;
					proc print data=t&vz._sd_rpt noobs; run;					

				%let rg = %eval(&rg+1); 
				%let admin_dx_type 			= %scan(&admin_dx_types.,&rg,|);
				%end;	
				
				%util_dummy_sheet; 			

/*------> END REPORTING OUTPUT <-----------------------------------------*/

*GRAPHICS OFF;
ods graphics off;

*END EXCEL OUTPUT;
ods excel close;

 /*-----------------------------------------------------------------*/
 /*---> SOLIRIS PROC CODE REVIEW OUTPUT <---------------------------*/
/**

%let rp_hcp 	= "&om_data./05_out_rep/Alexion_Procedure_Code_Review_201803.xls";

* GRAPHICS ON;
ods listing close;
ods listing gpath="&om_data./05_out_rep/";
ods output; ods graphics on;

%put Outputting Procedure Code Review Output...;

	/*-----------------------------------------------------------------*/
	/*---> REPORT: SOLIRIS MX CLAIMS <---------------------------------*/
	/**
	
			* EXCEL REPORT;
			Ods excel file=&rp_hcp. style=XL&vz.sansPrinter
					options
					(
						sheet_name="Soliris_Proc_Code_Review"
						sheet_interval='none'
						embedded_titles='yes'
					);
					
				* OUTPUT REPORT;
				title "Solaris Administrations: Same-Day Procedures Distribution, All Patients";
				proc print data=t&vz._sd_rpt noobs; run;
				

/*------> END PROCEDURE CODE REVIEW OUTPUT <-----------------------*/
/**

*GRAPHICS OFF;
ods graphics off;

*END EXCEL OUTPUT;
ods excel close;

/*------> DELETE ANY LEFTOVER DATA <-------------------------------*/
/**/
*DELETE ANY LEFTOVER DATA;
proc datasets nolist; delete t&vz.:; quit;
proc datasets nolist library=inp; delete t&vz.:; quit;  
proc datasets nolist library=inp; delete td&vz.:; quit; 
 
%mend;

/*-----------------------------------------------------------------*/
/*---> EXECUTE <---------------------------------------------------*/
/**/ 

%data_claims;
