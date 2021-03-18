module submission  (output reg [31:0] sum, input [31:0] a,b);

reg signa,signb; //sign bit
reg[7:0] expa,expb; //exponent bits
reg [22:0] fraca,fracb;//fraction bits
reg [22:0] fracashift,fracbshift;//fraction bits after shifting
reg [23:0] tempshift; //temporary reg for fraction shifting
reg [7:0] diff;//for calculating exponent difference between registers
reg eq; //set when both exponents are equal
reg [7:0] greater_exp;//greater exponent
reg [23:0] sum_big_alu; //addition output of big_alu
reg [23:0] temp_fraction_sum;//temp reg for storing sum of fraction while re-normalising
reg [23:0] diff_big_alu;//subtraction output of big_alu
reg [23:0] high_f; //value of (term before the floating point (0/1)+.fractional part) of operand having higher magnitude 
reg [23:0] low_f; //value of (term before the floating point (0/1)+.fractional part) of operand having lower magnitude 
reg [8:0] control; //control signals used
reg [22:0] a1,a1shift,b1; //define intermediate variables for storing fraction values and their shifted value

always @(*)
begin
//if either operand is 0
if(a[30:0]==0)
sum=b;
else if(b[30:0]==0)
sum=a;
//other cases:
else
begin
//assigning variables
signa=a[31]; //msb assigned as sign bits
signb=b[31];
expa[7:0]=a[30:23]; //31st to 24th bit assigned to exponent
expb[7:0]=b[30:23];
fraca[22:0]=a[22:0]; //23rd to 1st bit assigned to fraction
fracb[22:0]=b[22:0];

//determing the sign of final sum, if sign of the value with higher exponent is taken to be the final sign, if both are equal then ,mantissa is compared
if(a[30:0]>=b[30:0])
sum[31]=a[31];
else
sum[31]=b[31];

//comparing the exponents
if(expa==expb)
	begin
	eq=1;
	high_f[23]=1; //if both exponents are same, no shifting will take place and the term before floating point will be 1 for both
	low_f[23]=1;  
	end
else
	begin
	eq=0;
	high_f[23]=1; //if exponents are different, shifting will take place and the term before floating point will be 0 for lower operand due to shifting
	low_f[23]=0;
	end
if(expa>expb) //if control[1] is 1, a is the term with greater exponent
control[1]=1;
else
control[1]=0;

//shifting the exponents
tempshift[23]=1;
if(control[1]) //if a is greater
	begin
	greater_exp=expa;
	fracashift=fraca; //fraction part of a remains unchanged
	diff=expa-expb;
	tempshift[22:0]=fracb;
	tempshift=tempshift>>diff; 
	fracbshift=tempshift[22:0]; //fraction part of b is shifted
	high_f[22:0]=fracashift;
	low_f[22:0]=fracbshift;
	end
else   		//if b is greater
	begin
	greater_exp=expb;
	fracbshift=fracb; //fraction part of b remains unchanged
	diff=expb-expa;
	tempshift[22:0]=fraca;
	tempshift=tempshift>>diff; 
	fracashift=tempshift[22:0]; //fraction part of a is shifted accordingly
	high_f[22:0]=fracbshift;
	low_f[22:0]=fracashift;
	end

// big alu operation
if((signa^signb)==0) //if signs of both the numbers are same, normal addition takes place
	begin
	sum_big_alu=fracashift+fracbshift;
	end

else
	begin
	diff_big_alu=high_f-low_f; //gives difference between higher fractional part and lower fractional part when the msb values of both operands are different
	end

//re-normalise
if(eq==1)  //case when both the exponents are equal
	begin
	if((signa^signb)==0)   //when both signs are same
		begin
		sum[30:23]=greater_exp+1;
		sum[22]=sum_big_alu[23];     //if carry is generated in sum of fraction and both exponents are same, the msb of shifted fraction sum is 1, else 0
		sum[21:0]=sum_big_alu[22:1]; //sum_big_alu is shifed by right and taken
		end
	else			//when signs are different
		begin
		if(fraca!=fracb) 	//when fractional parts are unequal
			begin
			while(diff_big_alu[23]!=1)	//till the difference is not normalised, it is shifted towards left and exponent is decreased accordingly
				begin
				diff_big_alu=diff_big_alu<<1;
				greater_exp=greater_exp-1;
				end
			sum[22:0]=diff_big_alu[22:0];
			sum[30:23]=greater_exp;
			end
		else  //if sign is different and magnitude is same, then sum=0
		sum=0;
	end
	end
else		//when exponents are unequal
	begin
	if((signa^signb)==0)
		begin
		if(sum_big_alu[23]==1) //if carry out is generated while adding the fractions in big alu
			begin
			sum[30:23]=greater_exp+1;
			sum[22]=0;     
			sum[21:0]=sum_big_alu[22:1]; //sum_big_alu is shifed by right and taken
			end
		else      		//if no carry out is generated while adding the fractions in big alu
			begin
			sum[30:23]=greater_exp;
			sum[22:0]=sum_big_alu[22:0]; //sum of fractional part is the final fractional part		
			end
		end
	else
		begin          //same subtraction procedure as the previous case where exponents were equal
		while(diff_big_alu[23]!=1)	
			begin
			diff_big_alu=diff_big_alu<<1;
			greater_exp=greater_exp-1;
			end
		sum[22:0]=diff_big_alu[22:0];
		sum[30:23]=greater_exp;
		end
		
	end
end
end
endmodule

module submission_tb;
  wire [31:0] sum;
 reg [31:0] a,b;
	
  submission  INST1(
    .sum(sum),
    .a(a),
    .b(b));

	initial 
		begin
		#400 $finish;
		end

	initial
		begin
		 a=32'b00111111111000000000000000000000; 
		 b=32'b01000010101000100010000000000000; 
		#100
		 a=32'b11000001001001000000000000000000; 
		 b=32'b11000001011010100110011001100110; 
		#100
		 a=32'b11000001000000000000000000000000; 
		 b=32'b01000000111000000000000000000000; 
		#100
		 a=32'b01000001000000000000000000000000; 
		 b=32'b11000000111000000000000000000000; 
		end
        
endmodule
