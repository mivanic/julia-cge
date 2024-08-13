set
         reg /usa,canada,australia/
         com /rice, wheat, corn/
         fac /labor, capital/
;

*set smallreg(reg)/usa,canada/;
alias (smallreg,reg);

alias(com,com2);

positive variables
         p(com)
         qp(com,reg)
         qs(com,reg)
         pe(fac,reg)
         qe(fac,com,reg)
         y(reg)
         qet(fac,reg)
         pet
         c(com,reg)
;

variable dum;

table gamma(reg,com)
          rice wheat corn
usa       0.4  0.2   0.1
canada    0.3  0.2   0.1
australia 0.1  0.2   0.3
;

table alpha(reg,com)
          rice wheat corn
usa       0.2  0.5   0.3
canada    0.4  0.5   0.1
australia 0.4  0.5   0.1
;

table alpha2(reg,fac)
          labor capital
usa       0.4   0.6
canada    0.5   0.5
australia 0.7   0.3
;

parameters
         gamma2 /1/
         sigma /3/
;


equations
         eq_demand(com,reg)
         eq_market_clear(com)
         eq_factor_demand(com,reg,fac)
         eq_income(reg)
         eq_factor_clear(fac,reg)
         eq_zero_profits(com,reg)
         eq_index
         eq_c(com,reg)
         eq_dum
;

eq_c(com,reg)$(not(ord(com) eq 1 and ord(reg) eq 1))..
         c(com,reg) =e=  1/gamma2 * sum(fac,alpha2(reg,fac) ** (sigma) * (pe(fac,reg) ** (1-sigma))) ** (1/(1-sigma));

eq_demand(com,reg)..
         qp(com,reg) =e= gamma(reg,com) + (y(reg) - sum(com2, gamma(reg,com2)*p(com2))) * alpha(reg,com)/p(com);

eq_market_clear(com)..
         sum(reg, qp(com,reg)) =e= sum(reg, qs(com,reg));

eq_factor_demand(com,reg,fac)..
         qe(fac,com,reg) =e= qs(com,reg) / gamma2 * (alpha2(reg,fac)*gamma2 * c(com,reg)/pe(fac,reg)) ** sigma;

eq_income(smallreg)..
         sum(fac, qet(fac,smallreg) * pe(fac,smallreg)) =e= y(smallreg);

eq_factor_clear(fac,reg)..
         sum(com, qe(fac,com,reg))=e=qet(fac,reg);

eq_zero_profits(com,reg)..
         sum(fac, qe(fac,com,reg)*pe(fac,reg)) =e= qs(com,reg)* p(com);

eq_index..
         sum(fac,sum(reg, qet[fac,reg] * pe[fac,reg])) =e= pet;

eq_dum..
         dum =g= 0;

         p.lo(com)=0.01;
         qp.lo(com,reg)=0.01;
         qs.lo(com,reg)=0.01;
         pe.lo(fac,reg)=0.01;
         qe.lo(fac,com,reg)=0.01;
         y.lo(reg)=0.01;
         qet.lo(fac,reg)=0.01;
         pet.lo=0.01;
         c.lo(com,reg)=0.01;


qet.fx["labor","usa"] =  4;
qet.fx["capital","usa"] = 2;
qet.fx["labor","canada"] = 1;
qet.fx["capital","canada"]=3;
qet.fx["labor","australia"]=1;
qet.fx["capital","australia"] = 1;
pet.fx = 1;


model m/
         eq_demand
         eq_market_clear
         eq_factor_demand
         eq_income
         eq_factor_clear
         eq_zero_profits
*         eq_index
         eq_c
         eq_dum
/;

option CNS = path;

$ontext
qs.fx["rice","usa"]       = 0.949710797;
qs.fx["wheat","usa"]       = 1.468796831;
qs.fx["corn","usa"]        =0.843581837  ;
qs.fx["rice","canada"]      =  0.788210071;
qs.fx["wheat","canada"]      =  0.870992865;
qs.fx["corn","canada"]       = 0.206822467  ;
qs.fx["rice","australia"]     =   1.076895486;
qs.fx["wheat","australia"]=        1.44746222;
qs.fx["corn","australia"]=        0.579950684 ;

pe.fx["labor","usa"]        =7.226933536;
pe.fx["capital","usa"]        =6.81361828;
pe.fx["labor","canada"]        =15.12600106;
pe.fx["capital","canada"]        =8.733000785;
pe.fx["labor","australia"]        =10.84200776 ;
pe.fx["capital","australia"]        =25.29801812;
$offtext

p.l(com)=2;
pe.l(fac,reg)=21;
qe.l(fac,com,reg)=2;
c.l(com,reg)=2;
y.l(reg)=2;
qs.l(com,reg)=21;
qp.l(com,reg)=22;

p.fx("wheat")=10;


solve m using NLP minimizing dum;

model m2/
         eq_c
         eq_demand
         eq_market_clear
         eq_factor_demand
         eq_income
         eq_factor_clear
         eq_zero_profits
*         eq_index
*         eq_dum
/;

solve m2 using CNS;
qet.fx["capital","australia"] =  2;
solve m using NLP minimizing dum;
solve m2 using CNS;
*qet.fx["labor","usa"] =  4;
*solve m2 using CNS;

  parameter c2(com,reg);
c2(com,reg) = 1/gamma2 * sum(fac,alpha2(reg,fac) ** (sigma) * (pe.l(fac,reg) ** (1-sigma))) ** (1/(1-sigma));
display qe.l, y.l, qp.l, c.l, c2, pe.l, alpha2, gamma2,p.l, qs.l, qet.l;


