cas;
caslib _all_ assign;

%macro calculate_measures4GL(target,prediction,inDS,outDS=some_measures,lib=casuser);
/* Calculation of Precision, Recall, F1, and Accuracy measure for a categorical target variable */
/* SAS 4GL version */
proc freq data=&lib..&inDS noprint;
  tables &target*&prediction/out=&lib.._ss OUTPCT;
run;

data &lib..&outDS;
  set casuser._ss end=koniec;
  a+count;
  if &target=&prediction and &target~="";
    t+count;
    precision=PCT_COL/100;
    recall=PCT_ROW/100;
    f1=2*(precision*recall)/(precision+recall);
    output;
    if koniec=1 then do;
      precision=.;recall=.;f1=.;&target="";
      accuracy=t/a; output;
    end;
  keep &target precision recall f1 accuracy;
run;
proc sql noprint;
  drop table &lib.._ss;
run;quit;
%mend;



%macro calculate_measures(target,prediction,inDS,outDS=some_measures,casLib=casuser);
/* Calculation of Precision, Recall, F1, and Accuracy measure for a categorical target variable */
/* SAS CASL version */
proc cas;
   action freqTab.freqTab r=rf/
      table={caslib="&casLib",name="&inDS"},
      tabulate={{vars={"&target", "&prediction"}}};
run;

*describe rf[3];
  t=0.0;
  a=0.0;

  columns={"&target", 'precision', 'recall','f1','accuracy'};   
  coltypes={'varchar' 'double','double','double','double'}; 
  some_measures=newtable('some_measures',columns, coltypes);

/* row[2] - value of target column       */
/* row[4] - value of prediction column   */
/* row[5] - value of frequency           */
/* row[7] - value of row percent         */
/* row[8] - value of column percent      */

  do row over rf[3]; /*CrossList table*/
	if row[2]~="" then a=a+row[5];
	if row[2]=row[4]  and row[2]~="" then do;
		t=t+row[5];
		d={row[2],row[8]/100,row[7]/100,2*(row[7]/100*row[8]/100)/(row[7]/100+row[8]/100),.};
		addrow(some_measures, d);
	end;
  end;
  d={row[2],row[8]/100,row[7]/100,2*(row[7]/100*row[8]/100)/(row[7]/100+row[8]/100),t/(a/2)};
  addrow(some_measures, d);

  saveresult some_measures replace casout="&outDS" caslib="&casLib";
run;
quit;
%mend;

data casuser.exampleDS;
length target prediction $10;
do i=1 to 870; target="category_a";prediction="category_a"; output;end;
do i=1 to 6; target="category_b";prediction="category_a"; output;end;
do i=1 to 5; target="category_c";prediction="category_a"; output;end;
do i=1 to 5; target="category_a";prediction="category_b"; output;end;
do i=1 to 60; target="category_b";prediction="category_b"; output;end;
do i=1 to 4; target="category_c";prediction="category_b"; output;end;
do i=1 to 5; target="category_a";prediction="category_c"; output;end;
do i=1 to 40; target="category_b";prediction="category_c"; output;end;
do i=1 to 5; target="category_c";prediction="category_c"; output;end;
run;

%calculate_measures4GL(target,prediction,exampleDS,outDS=some_measures,lib=casuser);

%calculate_measures(target,prediction,exampleDS,outDS=some_measures,casLib=casuser);

