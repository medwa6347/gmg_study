/*-----------------------------------------------------------------*/
/*---> MX, RX CLAIM LENGTH STMTS <---------------------------------*/
/**/

%let mx_var_length = 						
	individual_id					 			8				
	claim_id							 			$10
	service_from_date			 			4
	service_thru_date 		 			4
  dx1										 			$7
  dx2                    			$7
  dx3                    			$7
  dx4                    			$7
  dx5                    			$7
  dx6                    			$7
  dx7                    			$7
  dx8                    			$7
  dx9                    			$7       
  service_procedure_code 			$5
	service_procedure_code_desc	$50
  quantity_units				 			8
	srvc_unit_cnt					 			8
	ndc_unit_of_msr_cd		 			$2
	nat_drg_cd_qty				 			8
	copay_mx               			8
  nodup_chg_amt_mx       			8
  prov_sp_cat_cd				 			$2
  pos_cd								 			$2
  ndc										 			$11
  mbr_admin_dx					 			$4;
  		 
%let rx_var_length = 						  
	individual_id    		8		
	claim_nbr           $10   	
	fill_date           4   
	ndc                 $11   
	days_supply         3   
	rx_prov_sp_code     $2   
	copay_rx            8   
	tot_allowed_rx      8   
	specialty_ind       $2   
	rx_location         $1   
	generic_ind         $1   
	generic_desc        $1   
	ahfs_class_desc     $50   
	brand_name          $50   
	generic_name        $50;  

/*-----------------------------------------------------------------*/
/*---> MX, RX CLAIMS SQL GENERATION <------------------------------*/
/**/

%macro mx_claims_flds_define;
%global mx_claims_flds mx_claims_from;
%let mx_claims_flds = 
         select distinct 
						mx.nhi_individual_id				 											as individual_id					 				
				  , mx.nhi_claim_nbr 								 									as claim_id								 
				  , mx.service_from_date   					 									as service_from_date			 
					, mx.service_thru_date 						 									as service_thru_date 			 
          , mx.header_diagnosis_1_code       									as dx1
          , mx.header_diagnosis_2_code       									as dx2
          , mx.header_diagnosis_3_code       									as dx3
          , mx.header_diagnosis_4_code       									as dx4
          , mx.header_diagnosis_5_code       									as dx5
          , mx.header_diagnosis_6_code       									as dx6
          , mx.header_diagnosis_7_code       									as dx7
          , mx.header_diagnosis_8_code       									as dx8
          , mx.header_diagnosis_9_code       									as dx9
          , prc.code                         									as service_procedure_code	 
          , prc.code_desc																			as service_procedure_code_desc
          , quantity_units																		as quantity_units
					, srvc_unit_cnt																			as srvc_unit_cnt
		  		, mx.amt_copay+mx.amt_deductible+mx.amt_coinsurance	as copay_mx                
          , mx.amt_non_duplicate_charge    	 									as nodup_chg_amt_mx        
          , p.specialty_category_code        									as prov_sp_cat_cd					 
  		  	, pos.ama_code 			 																as pos_cd					
  		  	, mx.ndc_code																				as ndc;			 
%let mx_claims_from = 
				 from &nhi_view..&mx_tbl.																					mx					 
				 inner join procedure_code 																				prc 
				 	on mx.bill_procedure_key = prc.procedure_key 			
				 inner join provider 																							p 
				 	on mx.provider_key = p.provider_key					
				 inner join provider_category 																		pc 
				 	on p.provider_category_code = pc.provider_category_code	 
				 inner join place_of_service 																			pos
				 	on mx.d_place_of_service_key	= pos.place_of_service_key;
%mend;
%mx_claims_flds_define;