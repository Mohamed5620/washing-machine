`timescale 1ns / 1ps
// 	ASSUME CLK IS 16 MHZ
// stop,state,double & clk_used are 4 plus outputs just used in the testbench to explain the behaviour 
// so you dont have to use them and if you wan to use them follow the comments
module washing_machine(rst,clk,clk_freq,coin_in,double_wash,timer_pause,wash_done);//,stop,state,clk_used,double); // you can remove the comment lines to add the outputs  but dont forget to remove the pracket and semicolon
input rst,clk,double_wash,timer_pause,coin_in;
input [1:0] clk_freq;
output reg wash_done;reg stop; // stop the operation       // make the registers from here outputs if you want them 
 reg [2:0] state;
 reg [3:0]clk_used;  //clock generation
 reg double;
parameter idle=0,fill=1,wash=2,rinse=3,spin=4;
parameter one_mega=60000000,two_mega=120000000,four_mega=240000000,eight_mega=480000000; // number of cycles for 1 minute for each frequency
reg [31:0] counter;    // to count cycles 
reg [31:0] counter2;   // to count cycles for double wash only befor being activated
integer min,two_min,five_min;      // integer numbers to calculate the 2 mins , 5mins

initial clk_used=0;

always @(posedge clk)                    // frequency divider
clk_used[3]=~clk_used[3];
always @(posedge clk_used[3])
clk_used[2]<=~clk_used[2];
always @(posedge clk_used[2])
clk_used[1]<=~clk_used[1];
always @(posedge clk_used[1])
clk_used[0]<=~clk_used[0]; 

always @(posedge clk_used[clk_freq])begin            // the start of FSM
if (rst==0)begin                                     // calculating the number of cycles for each time period
case (clk_freq)
0:begin 
  min=one_mega; two_min=min+min; five_min=two_min+two_min+min;
  end
1:begin 
  min=two_mega; two_min=min+min; five_min=two_min+two_min+min;
  end
2:begin 
  min=four_mega; two_min=min+min; five_min=two_min+two_min+min;
  end
3:begin 
  min=eight_mega; two_min=min+min; five_min=two_min+two_min+min;
  end
endcase
state<=idle;                      // reset all the parameters
wash_done<=0;
counter<=1;
counter2<=1;
double<=0;
stop<=0;
end
else begin
case(state)
idle:begin
     if ((coin_in==0)&&(stop==0))             // counting number of cycles before coin=1
	  counter<=counter+1; 
	  if ((double_wash==0)&&(stop==0))         // counting number of cycles before double=1
	  counter2<=counter2+1;
     if((coin_in==1)&&(double_wash==0)&&(stop==0))begin        // normal operation
     state<=fill;
	  wash_done<=0;
	  counter<=1;
	  counter2<=1;
	  double<=0;
	  end
	  else if ((coin_in==1)&&(counter2<=counter)&&(double_wash==1)&&(stop==0))begin  // double wash
     state<=fill;
	  wash_done<=0;
	  counter<=1;
	  counter2<=1;
	  double<=1;
	  end
     else if((stop==1)&&(timer_pause==0)) begin     //go to finish spininng after pausing 
     state<=spin;
     wash_done<=0;
     end
	  end	  
fill:begin
     if(counter<two_min)begin       // spend 2 mins
	  state<=fill;
	  counter<=counter+1;
	  wash_done<=0;
	  end
	  else begin                // goes to wash state after finishing
	  state<=wash;
	  counter<=1;
	  end
	  end
wash:begin
     if(counter<five_min)begin           // spend 5 mins
	  state<=wash;
	  counter<=counter+1;
	  end
	  else begin                    // goes to the rinse state after finishing 
	  state<=rinse;
	  counter<=1;
	  end
	  end
rinse:begin
     if(counter<two_min)begin              // spend 2 mins
	  state<=rinse;
	  counter<=counter+1;
	  end
	  else if((double==1)&&(counter2<2))begin           // after finishing asks for if there is a double wash or not?
	  state<=wash;
	  counter<=1;
	  counter2<=counter2+1;
	  end
	  else begin              // no double wash or finish rinsing 
	  state<=spin;
	  counter<=1;
	  counter2<=1;
	  end
	  if(timer_pause==1)         // asks if the timer is paused before spinning
	  stop<=1;
	  end
spin:begin
     if(counter<min)begin             // spend 1 min
	  state<=spin;
	  counter<=counter+1;
     if((timer_pause==1)&&(stop==0))begin    // asks for timer pause
	  state<=idle;
	  wash_done<=0;
	  stop<=1;
	  end
	  end
	  else begin                 // finish spinning
	  state<=idle;
	  wash_done<=1;
	  stop<=0;
	  counter<=1;
	  double<=0;
	  end
	  end
default: state<=idle;
endcase	  
end          
end
	  
endmodule

// this testbench based on us not minutes so the full program will take 10 us instead of 10 minutes 

module testbench;
reg rst,clk,coin_in,double_wash,timer_pause;
reg [1:0] clk_freq;
wire wash_done;//,stop,double;         // remove the comment lines if you want to add the outputs
//wire [3:0]clk_used;
//wire [2:0] state;
washing_machine wm(.rst(rst),.clk(clk),.clk_freq(clk_freq),.coin_in(coin_in),.double_wash(double_wash)
,.timer_pause(timer_pause),.wash_done(wash_done));//,.stop(stop),.state(state),.clk_used(clk_used),.double(double)); // you can remove the comment lines to add the outputs  but dont forget to remove the pracket and semicolon
initial begin
clk_freq=2'b11;
clk=0;
rst=0;
end
always 
# 31.25 clk=~clk;

initial begin
# 50 rst=1;
# 50 coin_in=1;double_wash=0;timer_pause=0;
# 500 coin_in=0;
# 9000 double_wash=1;
# 800 coin_in=1;
# 2000 coin_in=0; double_wash=0;
# 15000 coin_in=1; # 200 double_wash=1; 
# 500 timer_pause=1;
# 9000 timer_pause=0;
# 500 coin_in=1;
# 16500 timer_pause=1;
# 1000 timer_pause=0; coin_in=0;
end
endmodule 