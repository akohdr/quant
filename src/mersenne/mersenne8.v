// Filename:    mersenne.v
// 
// Author: Andrew Wild <akohdr@gmail.com>
//                 
// Version:    1.0
// Description:    Verilog synthesizable implementation of the Mersenne Twister
//                 Originally developed for hardware based Monte Carlo simulator
// 

`define MERSENNE_N             624             // dimensions
`define MERSENNE_M             397
`define MERSENNE_MATRIX_A      32'h9908b0df    // constant vector a
`define MERSENNE_UPPER_MASK    32'h80000000    // most significant w-r bits
`define MERSENNE_LOWER_MASK    32'h7fffffff    // least significant r bits

`define TEMPERING_MASK_B     32'h9d2c5680
`define TEMPERING_MASK_C     32'hefc60000
`define TEMPERING_SHIFT_U    11
`define TEMPERING_SHIFT_S    7
`define TEMPERING_SHIFT_T    15
`define TEMPERING_SHIFT_L    18     

`define INITIAL_SEED         32'd8891

module mersenne8(clk, rst, ce, rnd);

  input clk;
  output rnd; reg [31:0] rnd;
  reg [10:0] i, j, k;  // three divide by N counters
  
  input rst; wire rst;
  input ce; wire ce;
  reg isSeeded;            
  reg w1;

    reg [31:0] mt1    [`MERSENNE_N:0];    /* the array for the state vector  */
    reg [31:0] mt2    [`MERSENNE_N:0];    /* the array for the state vector  */
    
    reg bih;                  // High bit of word 'i'
    reg [31:0] sbihjl;        // right shift of bihjl
    reg [31:0] mbihjl;        // MATRIX_A result from bihjl
    reg [31:0] prj;           // Previous read of word 'j'
    reg [31:0] l1,l2;
    
    reg [31:0] rj;            // Memory read of word 'j'
    reg [31:0] rk;            // Memory read of work 'k' 
  
  //always@(posedge rst)
  initial
        begin
            i <= 1;   
      l2 <= `INITIAL_SEED-1;
      isSeeded <= 0;
        end
        
  always@(posedge clk)
    begin
    if (!isSeeded) begin
      // seed loop runs from clock for first MERSENNE_N ticks
      l1 <= l2 + 1;        
      #4 w1 <= l1;
      //#5 mt1[i] <= l1;
      //#5 mt2[i] <= l1;
      #5 l2 <= l1 * 69069;
      #5 i <= i+1;
      #5 isSeeded = (i >= `MERSENNE_N);
      #6 if(isSeeded) begin
        #7 i <= 0;
        #7 j <= 1;
        #7 k <= `MERSENNE_M;
        #8 prj <= `INITIAL_SEED;
      end
      
    end else begin
    
    bih <= prj[31];
    #1 rj <= mt1[j];
    #1 rk <= mt2[k];
      #2 prj <= rj;
        #3 mbihjl <= rj[0] ? `MERSENNE_MATRIX_A : 0;
        #3 sbihjl <= {bih, rj[30:0]}>>>1;
        #3 rnd <= rk ^ sbihjl ^ mbihjl;
            #4 w1 <= rnd;
            //#5 mt1[i] <= rnd;
            //#5 mt2[i] <= rnd;
              #6 i <= i+1;
              #6 j <= j+1;
              #6 k <= k+1;
            
              // conditioning
                  #6 rnd <= rnd ^ (rnd[31:`TEMPERING_SHIFT_U]); //(rnd >> `TEMPERING_SHIFT_U);
                    #7 rnd <= rnd ^ ((rnd << `TEMPERING_SHIFT_S) & `TEMPERING_MASK_B);
                      #8 rnd <= rnd ^ ((rnd << `TEMPERING_SHIFT_T) & `TEMPERING_MASK_C);
                        #9 rnd <= rnd ^ (rnd[31:`TEMPERING_SHIFT_L]); // (rnd >> `TEMPERING_SHIFT_L);

    if(i==`MERSENNE_N) i <= 0;
    if(j==`MERSENNE_N) j <= 0;
    if(k==`MERSENNE_N) k <= 0;                                          
      
    end //if !seeded     
    #5 mt1[i] <= w1;
    #5 mt2[i] <= w1;
    
  end
  
    
endmodule


