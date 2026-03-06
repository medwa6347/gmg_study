/*-----------------------------------------------------------------*/
/*---> EHR LENGTH STMTS <------------------------------------------*/
/**/
															
%let med_admin_var_length = 	panther_id					$11 					
															encid               $15           
															drug_name           $25          
															ndc                 $11           
															admin_date          4             
															quantity_of_dose    $3           
															strength            $4           
															generic_desc        $10           
															dose								4
															mbr_admin_dx				$7;     
															
%let rx_var_length 				=		&med_admin_var_length.;			

%let proc_var_length 			= 	panther_id					$11 					
															encid               $15           
															admin_date          4             
															mbr_admin_dx				$7;    
														
%let pt_obs_var_length 		= 	panther_id				$11 													
                              encid             $15
                              obs_date          4  
                              obs_result        $10
                              obs_unit          $20
                              pt_wt							6; 

%let pt_var_length 			  = 	panther_id				$11 													
                              age					     	3  
                              race        			$20 
                              region          	$13
                              gender						$7
                              update_date				4; 

/*-----------------------------------------------------------------*/
/*---> EHR SQL GENERATION <----------------------------------------*/
/**/

%macro ehr_flds_define;
	
*EHR DX;
%global dx_flds dx_from;
%let dx_flds = select distinct panther_id, encid, diag_date, diagnosis_cd_nodecm as mbr_admin_dx;		 
%let dx_from = from &nhi_view..clnpntr_diagnosis; 

*EHR MED ADMINS;
%global med_admin_flds med_admin_from;
%let med_admin_flds = select distinct 
															ma.panther_id					
														, ma.encid               
														, ma.drug_name           
														, ma.ndc                 
														, ma.admin_date          
														, ma.quantity_of_dose    
														, ma.strength            
														, ma.generic_desc        
														, dx.mbr_admin_dx;			 
%let med_admin_from = from &nhi_view..clnpntr_med_admin ma left outer join &nhi_sbox..t&vz._mbr_admin_dx dx on ma.encid = dx.encid;

*EHR PROCEDURES;
%global proc_flds proc_from;
%let proc_flds = select distinct 
															pc.panther_id	
														, pc.encid      
														, pc.proc_date as admin_date;			 
%let proc_from = from &nhi_view..clnpntr_procedures pc left outer join &nhi_sbox..t&vz._mbr_admin_dx dx on pc.encid = dx.encid;

*EHR RX ADMINS;
%global rx_flds rx_from;
%let rx_flds = select distinct 
															rx.panther_id					
														, rx.drug_name           
														, rx.ndc                 
														, rx.rxdate as admin_date          
														, rx.quantity_of_dose    
														, rx.strength            
														, rx.generic_desc        
														, dx.mbr_admin_dx;			 
%let rx_from = from &nhi_view..clnpntr_prescriptions rx left outer join &nhi_sbox..t&vz._mbr_dx dx on rx.panther_id = dx.panther_id;

*EHR PATIENT OBS;
%global pt_obs_flds pt_obs_from;
%let pt_obs_flds 		= select distinct
															po.panther_id						 	
														,	encid                    
														,	obs_date                 
														,	obs_result              
														,	obs_unit                 
														,	nhi_cci_member_id;         
%let pt_obs_from 		= from &nhi_view..clnpntr_observations po;

*EHR PATIENT DEMOGRAPHICS;
%global pt_flds pt_from;
%let pt_flds 		= select distinct
															p.panther_id						 	
														,	year_of_birth        
														,	race        	       
														,	region              
														,	gender
														, update_date;				       
%let pt_from 		= from &nhi_view..clnpntr_patient p;

%mend;
%ehr_flds_define;