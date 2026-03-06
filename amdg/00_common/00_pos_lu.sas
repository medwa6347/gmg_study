 /*-----------------------------------------------------------------*\
 | PLACE-OF-SERVICE GROUPERS LU FILE									      				 |
 | AUTHOR: MICHAEL W EDWARDS 03-20-18 AMDG                           |
 \*-----------------------------------------------------------------*/
/**/

 /*-----------------------------------------------------------------*\
 | THIS PROGRAM CREATES PLACE-OF-SERVICE LOOKUP TABLE								 | 
 |	BASED ON THE DNHI PLACE_OF_SERVICE TABLE		 										 |	
 |	WITH CUSTOM PLACE-OF-SERVICE GROUPINGS													 |
 | DNHI QUERY:																											 |
 |	SELECT DISTINCT AMA_CODE																				 |
 | 								, AMA_CODE_DESC																	 	 | 
 |	FROM PLACE_OF_SERVICE									 									 	 			 |	
 \*-----------------------------------------------------------------*/	
/**/
		
data inp.r&vz._pos2desc_lu(drop=line); 
input line $char60.;
pos=put(scan(line,1,'|'),$4.); 
mx_index_pos_desc=trim(tranwrd(scan(line,2,'|'),"'",""));
cards;                                    
UNK|'UNKNOWN'																			 |
11|'OFFICE'                                        |   
12|'HOME HEALTH'                                   |   
13|'ASSISTED LIVING FACILITY'                      |   
19|'OFF CAMPUS-OUTPATIENT HOSPITAL'                |   
20|'URGENT CARE FACILITY'                          |   
21|'INPATIENT HOSPITAL'                            |   
22|'OUTPATIENT HOSPITAL'                           |   
23|'EMERGENCY ROOM'                                |   
24|'AMBULATORY SURGICAL CENTER'                    |   
31|'SKILLED NURSING FACILITY'                      |   
32|'NURSING FACILITY'                              |   
49|'INDEPENDENT CLINIC'                            |   
50|'FEDERALLY QUALIFIED HEALTH CENTER'             |   
51|'INPATIENT PSYCHIATRIC FACILITY'                |   
55|'RESIDENTIAL SUBSTANCE ABUSE TREATMENT FACILITY'|   
65|'END-STAGE RENAL DISEASE TREATMENT FACILITY'    |   
72|'RURAL HEALTH CLINIC'                           |   
81|'INDEPENDENT LABORATORY'                        |   
99|'OTHER UNLISTED FACILITY'                       |
;
run;

	