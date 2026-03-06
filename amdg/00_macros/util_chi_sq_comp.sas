%macro chi_sq_comp(






);

/*CHI-SQUARED*/	
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
title;
title "Chi-Squared Test: N-Way Examination of Age Group, Race Group, Region, Initial Weight Group and Gender of Soliris Patients with and without Initial Dose Data";			
title2 "January 1st, 2015 - December 31st, 2017, &admin_dx_type. Diagnosis";	
proc freq data=t&vz._aabbsums_all_with_wo; by test_number; tables test_group_nm*patient_category / chisq; weight patients; run;


%mend;
