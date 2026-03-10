 /*-----------------------------------------------------------------*\
 | PROCEDURE CODE GROUPERS LU FILE								     |
 | AUTHOR: MICHAEL W EDWARDS 07-11-18 AMDG                           |
 \*-----------------------------------------------------------------*/
/**/

 /*-----------------------------------------------------------------*\
 | THIS PROGRAM CREATES A PROCEDURE CODE LOOKUP TABLE				 | 
 |	BASED ON A CUSTOM CLINICAL REVIEW OF THE PROCEDURE CODES		 |	
 |	ASSOCIATED WITH THIS ANALYSIS									 |
 \*-----------------------------------------------------------------*/	
/**/
		
data inp.r&vz._proc2cat_lu(drop=line); 
input line $char60.;
proc_cd=trim(tranwrd(scan(line,1,'|'),"'",""));
proc_cd_cat=trim(tranwrd(scan(line,2,'|'),"'",""));
cards;                                    
'00740'|'Anesthesia'|
'00810'|'Anesthesia'|  
'01112'|'Anesthesia'|  
'99144'|'Anesthesia'|  
'99152'|'Anesthesia'|  
'P9016'|'BloodProduct'|  
'P9035'|'BloodProduct'|  
'P9040'|'BloodProduct'|  
'36430'|'BloodTransfusion'|  
'94640'|'Drug Administration'|  
'95117'|'Drug Administration'|  
'95165'|'Drug Administration'|  
'96365'|'Drug Administration'|  
'96366'|'Drug Administration'|  
'96367'|'Drug Administration'|  
'96372'|'Drug Administration'|  
'96374'|'Drug Administration'|  
'96375'|'Drug Administration'|  
'96402'|'Drug Administration'|  
'96409'|'Drug Administration'|
'96413'|'Drug Administration'|
'96415'|'Drug Administration'|	
'96417'|'Drug Administration'|
'99601'|'Drug Administration'|
'99602'|'Drug Administration'|
'J0171'|'Drug Administration'|
'J0485'|'Drug Administration'|
'J0696'|'Drug Administration'|
'J0881'|'Drug Administration'|
'J0885'|'Drug Administration'|
'J0895'|'Drug Administration'|
'J1100'|'Drug Administration'|
'J1170'|'Drug Administration'|
'J1200'|'Drug Administration'|
'J1300'|'Soliris Cost				'|
'J1335'|'Drug Administration'|
'J1442'|'Drug Administration'|
'J1453'|'Drug Administration'|
'J1459'|'Drug Administration'|
'J1561'|'Drug Administration'|
'J1626'|'Drug Administration'|
'J1642'|'Drug Administration'|
'J1644'|'Drug Administration'|
'J1720'|'Drug Administration'|
'J1745'|'Drug Administration'|
'J1750'|'Drug Administration'|
'J1756'|'Drug Administration'|
'J2060'|'Drug Administration'|
'J2175'|'Drug Administration'|
'J2248'|'Drug Administration'|
'J2405'|'Drug Administration'|
'J2469'|'Drug Administration'|
'J2780'|'Drug Administration'|
'J2920'|'Drug Administration'|
'J2930'|'Drug Administration'|
'J2997'|'Drug Administration'|
'J3370'|'Drug Administration'|
'J3420'|'Drug Administration'|
'J3465'|'Drug Administration'|
'J3490'|'Drug Administration'|
'J7613'|'Drug Administration'|
'J9171'|'Drug Administration'|
'J9217'|'Drug Administration'|
'S9330'|'Drug Administration'|
'S9338'|'Drug Administration'|
'S9347'|'Drug Administration'|
'S9355'|'Drug Administration'|
'S9359'|'Drug Administration'|
'S9370'|'Drug Administration'|
'S9379'|'Drug Administration'|
'S9500'|'Drug Administration'|
'S9501'|'Drug Administration'|
'S9502'|'Drug Administration'|
'S9537'|'Drug Administration'|
'S9542'|'Drug Administration'|
'92012'|'Evaluation&Management'|
'92014'|'Evaluation&Management'|
'99202'|'Evaluation&Management'|
'99203'|'Evaluation&Management'|
'99204'|'Evaluation&Management'|
'99211'|'Evaluation&Management'|
'99212'|'Evaluation&Management'|
'99213'|'Evaluation&Management'|
'99214'|'Evaluation&Management'|
'99215'|'Evaluation&Management'|
'99222'|'Evaluation&Management'|
'99223'|'Evaluation&Management'|
'99231'|'Evaluation&Management'|
'99232'|'Evaluation&Management'|
'99233'|'Evaluation&Management'|
'99236'|'Evaluation&Management'|
'99239'|'Evaluation&Management'|
'99244'|'Evaluation&Management'|
'99245'|'Evaluation&Management'|
'99282'|'Evaluation&Management'|
'99283'|'Evaluation&Management'|
'99284'|'Evaluation&Management'|
'99285'|'Evaluation&Management'|
'99291'|'Evaluation&Management'|
'99306'|'Evaluation&Management'|
'99309'|'Evaluation&Management'|
'99350'|'Evaluation&Management'|
'99395'|'Evaluation&Management'|
'99396'|'Evaluation&Management'|
'99406'|'Evaluation&Management'|
'99495'|'Evaluation&Management'|
'G0463'|'Evaluation&Management'|
'96361'|'Hydration'|
'J7030'|'Hydration'|
'J7040'|'Hydration'|
'J7042'|'Hydration'|
'J7050'|'Hydration'|
'J7060'|'Hydration'|
'S9374'|'Hydration'|
'71010'|'Imaging'|
'71020'|'Imaging'|
'71045'|'Imaging'|
'71046'|'Imaging'|
'71250'|'Imaging'|
'72040'|'Imaging'|
'72197'|'Imaging'|
'73130'|'Imaging'|
'73502'|'Imaging'|
'74176'|'Imaging'|
'74177'|'Imaging'|
'74178'|'Imaging'|
'74183'|'Imaging'|
'74185'|'Imaging'|
'76817'|'Imaging'|
'76830'|'Imaging'|
'76856'|'Imaging'|
'77052'|'Imaging'|
'77063'|'Imaging'|
'77067'|'Imaging'|
'77072'|'Imaging'|
'77077'|'Imaging'|
'78582'|'Imaging'|
'92250'|'Imaging'|
'A9579'|'Imaging'|
'G0202'|'Imaging'|
'Q9967'|'Imaging'|
'76937'|'ImagingGuidance'|
'77001'|'ImagingGuidance'|
'77012'|'ImagingGuidance'|
'90460'|'Immunization'|
'90471'|'Immunization'|
'90620'|'Immunization'|
'90621'|'Immunization'|
'90670'|'Immunization'|
'90674'|'Immunization'|
'90686'|'Immunization'|
'90688'|'Immunization'|
'90732'|'Immunization'|
'90733'|'Immunization'|
'90734'|'Immunization'|
'Q2039'|'Immunization'|
'1034F'|'Informational'|
'1036F'|'Informational'|
'1111F'|'Informational'|
'1159F'|'Informational'|
'1160F'|'Informational'|
'3008F'|'Informational'|
'3060F'|'Informational'|
'3074F'|'Informational'|
'3078F'|'Informational'|
'3079F'|'Informational'|
'3341F'|'Informational'|
'3725F'|'Informational'|
'7025F'|'Informational'|
'G0364'|'Informational'|
'G8417'|'Informational'|
'G8420'|'Informational'|
'G8427'|'Informational'|
'G8432'|'Informational'|
'G8510'|'Informational'|
'G8950'|'Informational'|
'80047'|'Lab'|
'80048'|'Lab'|
'80051'|'Lab'|
'80053'|'Lab'|
'80061'|'Lab'|
'80069'|'Lab'|
'80074'|'Lab'|
'80076'|'Lab'|
'80162'|'Lab'|
'80195'|'Lab'|
'80197'|'Lab'|
'80299'|'Lab'|
'80307'|'Lab'|
'81000'|'Lab'|
'81001'|'Lab'|
'81002'|'Lab'|
'81003'|'Lab'|
'81025'|'Lab'|
'81050'|'Lab'|
'81241'|'Lab'|
'81479'|'Lab'|
'82009'|'Lab'|
'82040'|'Lab'|
'82043'|'Lab'|
'82150'|'Lab'|
'82248'|'Lab'|
'82306'|'Lab'|
'82310'|'Lab'|
'82330'|'Lab'|
'82374'|'Lab'|
'82435'|'Lab'|
'82533'|'Lab'|
'82550'|'Lab'|
'82553'|'Lab'|
'82565'|'Lab'|
'82570'|'Lab'|
'82607'|'Lab'|
'82610'|'Lab'|
'82652'|'Lab'|
'82668'|'Lab'|
'82728'|'Lab'|
'82746'|'Lab'|
'82747'|'Lab'|
'82784'|'Lab'|
'82947'|'Lab'|
'82977'|'Lab'|
'83010'|'Lab'|
'83036'|'Lab'|
'83051'|'Lab'|
'83090'|'Lab'|
'83519'|'Lab'|
'83520'|'Lab'|
'83540'|'Lab'|
'83550'|'Lab'|
'83605'|'Lab'|
'83615'|'Lab'|
'83690'|'Lab'|
'83721'|'Lab'|
'83735'|'Lab'|
'83880'|'Lab'|
'83921'|'Lab'|
'83970'|'Lab'|
'84100'|'Lab'|
'84132'|'Lab'|
'84144'|'Lab'|
'84146'|'Lab'|
'84153'|'Lab'|
'84154'|'Lab'|
'84155'|'Lab'|
'84156|'Lab'|
'84165|'Lab'|
'84295|'Lab'|
'84436|'Lab'|
'84439|'Lab'|
'84443|'Lab'|
'84450|'Lab'|
'84460|'Lab'|
'84466|'Lab'|
'84480|'Lab'|
'84481|'Lab'|
'84484|'Lab'|
'84520|'Lab'|
'84550|'Lab'|
'84560|'Lab'|
'84702|'Lab'|
'84703|'Lab'|
'85007|'Lab'|
'85025|'Lab'|
'85027|'Lab'|
'85044|'Lab'|
'85045|'Lab'|
'85046|'Lab'|
'85049|'Lab'|
'85055|'Lab'|
'85060|'Lab'|
'85097|'Lab'|
'85300|'Lab'|
'85302|'Lab'|
'85303|'Lab'|
'85305|'Lab'|
'85379|'Lab'|
'85597|'Lab'|
'85598|'Lab'|
'85610|'Lab'|
'85613|'Lab'|
'85670|'Lab'|
'85705|'Lab'|
'85730|'Lab'|
'85732|'Lab'|
'86038|'Lab'|
'86077|'Lab'|
'86140|'Lab'|
'86146|'Lab'|
'86147|'Lab'|
'86156|'Lab'|
'86160|'Lab'|
'86162|'Lab'|
'86200|'Lab'|
'86225|'Lab'|
'86235|'Lab'|
'86317|'Lab'|
'86356|'Lab'|
'86376|'Lab'|
'86431|'Lab'|
'86618|'Lab'|
'86704|'Lab'|
'86705|'Lab'|
'86706|'Lab'|
'86707|'Lab'|
'86708|'Lab'|
'86709|'Lab'|
'86803|'Lab'|
'86850|'Lab'|
'86870|'Lab'|
'86880|'Lab'|
'86900|'Lab'|
'86901|'Lab'|
'86920|'Lab'|
'87040|'Lab'|
'87070|'Lab'|
'87075|'Lab'|
'87077|'Lab'|
'87086|'Lab'|
'87186|'Lab'|
'87205|'Lab'|
'87340|'Lab'|
'87350|'Lab'|
'87430|'Lab'|
'87491|'Lab'|
'87497|'Lab'|
'87591|'Lab'|
'87624|'Lab'|
'87661|'Lab'|
'87799|'Lab'|
'87804|'Lab'|
'87999|'Lab'|
'88141|'Lab'|
'88184|'Lab'|
'88185|'Lab'|
'88187|'Lab'|
'88189|'Lab'|
'88237|'Lab'|
'88264|'Lab'|
'88271|'Lab'|
'88275|'Lab'|
'88305|'Lab'|
'88311|'Lab'|
'88312|'Lab'|
'88313|'Lab'|
'88341|'Lab'|
'88342|'Lab'|
'88346|'Lab'|
'88348|'Lab'|
'88350|'Lab'|
'94729|'Lab'|
'94760|'Lab'|
'Q0091|'Lab'|
'B4150|'Nutrition'|
'S9343|'Nutrition'|
'S9367|'Nutrition'|
'36415|'Other'|
'36416|'Other'|
'36591|'Other'|
'36592|'Other'|
'36593|'Other'|
'90945|'Other'|
'90947|'Other'|
'90960|'Other'|
'90961|'Other'|
'90962|'Other'|
'90999|'Other'|
'92015|'Other'|
'92507|'Other'|
'92610|'Other'|
'93005|'Other'|
'93010|'Other'|
'93306|'Other'|
'94010|'Other'|
'94060|'Other'|
'96523|'Other'|
'99000|'Other'|
'99053|'Other'|
'A0425|'Other'|
'A0427|'Other'|
'A0429|'Other'|
'A4216|'Other'|
'A4221|'Other'|
'A4222|'Other'|
'A4657|'Other'|
'A4913|'Other'|
'A6216|'Other'|
'A9276|'Other'|
'B4035|'Other'|
'C1751|'Other'|
'E0483|'Other'|
'E0781|'Other'|
'E1390|'Other'|
'E2208|'Other'|
'G0283|'Other'|
'G0299|'Other'|
'K0001|'Other'|
'K0738|'Other'|
'L3984|'Other'|
'L3995|'Other'|
'S5502|'Other'|
'S9123|'Other'|
'T4521|'Other'|
'97110|'PhysicalTherapy'|
'97112|'PhysicalTherapy'|
'97116|'PhysicalTherapy'|
'97140|'PhysicalTherapy'|
'97530|'PhysicalTherapy'|
'S9131|'PhysicalTherapy'|
'10120|'Surgical'|
'11100|'Surgical'|
'17110|'Surgical'|
'36561|'Surgical'|
'38221|'Surgical'|
'43239|'Surgical'|
'44388|'Surgical'|
'50200|'Surgical'|
'66840|'Surgical'|
'99199|'Unknown'|
'99999|'Unknown'|
'S9378|'Unknown'|
;      
run;