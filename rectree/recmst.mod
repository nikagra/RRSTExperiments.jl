

param n, integer, >= 2;
/* liczba wierzcholkow */

param L, integer, >= 0, <=n-1;
/* Licznosc czesci wspolnej  L=|V|-1-k */

set V:={1..n};
/* zbior wierzcholkow */

set E  within V cross V;
/* zbior  krawedzi */

set A :=E union setof{(i,j) in E} (j,i);


param cx{(i,j) in E}, >= 0;
/* cx[i,j]  waga krawedzi (i,j) */




var fx{(i,j) in A, k in V diff {1}} >=0;
/* zmienne przeplywowe */

var wx{(i,j) in A} >=0;

var x{(i,j) in E} >=0;


param cy{(i,j) in E}, >= 0;
/* cy[i,j]  waga krawedzi (i,j) */

var fy{(i,j) in A, k in V diff {1}} >=0;
/* zmienne przeplywowe */

var wy{(i,j) in A} >=0;

var y{(i,j) in E} >=0;


var z{(i,j) in E} >=0;

minimize koszt: sum{(i,j) in E} (cx[i,j]*x[i,j]+cy[i,j]*y[i,j]);




s.t. zrodlaX{k in V diff {1}}:
     sum{(j,1) in A} fx[j,1,k]-sum{(1,j) in A} fx[1,j,k]= -1;

s.t. bilans2X{k in V diff {1},i in V diff {1} : k <> i}:
     sum{(j,i) in A} fx[j,i,k]-sum{(i,j) in A} fx[i,j,k]= 0;

s.t. ujsciaX{k in V diff {1}}:
     sum{(j,k) in A} fx[j,k,k]-sum{(k,j) in A} fx[k,j,k]= 1;

s.t. pojemnosciX{k in V diff {1}, (i,j) in A}:
     fx[i,j,k] <= wx[i,j];

s.t. drzewoX1: sum{(i,j) in A} wx[i,j]=n-1; 

s.t. drzewoX2{(i,j) in E}:  x[i,j]=wx[i,j]+wx[j,i];


#---------

s.t. zrodlaY{k in V diff {1}}:
     sum{(j,1) in A} fy[j,1,k]-sum{(1,j) in A} fy[1,j,k]= -1;

s.t. bilans2Y{k in V diff {1},i in V diff {1} : k <> i}:
     sum{(j,i) in A} fy[j,i,k]-sum{(i,j) in A} fy[i,j,k]= 0;

s.t. ujsciaY{k in V diff {1}}:
     sum{(j,k) in A} fy[j,k,k]-sum{(k,j) in A} fy[k,j,k]= 1;

s.t. pojemnosciY{k in V diff {1}, (i,j) in A}:
     fy[i,j,k] <= wy[i,j];

s.t. drzewoY1: sum{(i,j) in A} wy[i,j]=n-1; 

s.t. drzewoY2{(i,j) in E}:  y[i,j]=wy[i,j]+wy[j,i];

#--czesc wspolna

s.t.  zx{(i,j) in E}: x[i,j]>=z[i,j];
s.t.  zy{(i,j) in E}: y[i,j]>=z[i,j];
s.t.   wspolz: sum{(i,j) in E} z[i,j]>=L;

solve;


/* drukowanie wynikow na standardowe wyjscie */

display 'drzewo rozpinajace X';
display {(i,j) in E}: x[i,j];


display 'drzewo rozpinajace Y';
display {(i,j) in E}: y[i,j];


display 'czesc wspolna Z';
display {(i,j) in E}: z[i,j];


display 'calkowity koszt =',  sum{(i,j) in E} (cx[i,j]*x[i,j]+cy[i,j]*y[i,j]);



data;

#L=|V|-1-k


#E = [(2,1),(1,3),(3,2),(4,2)]
#C = [5,8,1,3]
#c = [7,2,10,9]

param n := 4;
param L := 3;
param : E :   cx  cy:=
        2 1  5  7   
			  1 3  8  2  
				3 2  1  10
				4 2  3  9;


/*

#E: [(4,1),(5,1),(1,6),(6,4),(4,3),(3,6),(6,5),(5,4),(1,2)]
#C: [5,8,1,10,6,9,1,9,8]
#c: [7,2,10,6,5,2,3,9,8]


param n := 6;
param L := 3;
param : E :   cx  cy:=
        4 1  5  7   
			  5 1  8  2  
				1 6  1  10
				6 4  10  6
				4 3  6   5
				3 6  9   2 
				6 5  1   3
				5 4  9   9
				1 2  8   8;
				

	
#E: [(4,2),(4,1),(3,4),(3,2),(2,5)]
#C: [10,3,5,5,5]
#c: [10,4,8,10,3]	
				
param n := 5;
param L := 4;
param : E :   cx  cy:=
        4 2  10  10   
			  4 1  3  4  
				3 4  5  8
				3 2  5  10
				2 5  5   3;				
				



param n := 6;
param L := 4;
param : E :   cx  cy:=
        4 1  5  7   
			  5 1  8  2  
				1 6  1  10
				6 4  10  6
				4 3  6   5
				3 6  9   2 
				6 5  1   3
				5 4  9   9
				1 2  8   8;
				
*/
end;
