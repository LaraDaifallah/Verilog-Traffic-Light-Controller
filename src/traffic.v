// Lara Daifallah || 1230239 || Sec 3

//my code 

`timescale 1ns / 1ps
module traffic_ctrl(
    input clk, rst, VS, PB,
    output reg [2:0] light_main, light_side,
    output reg walk 
);
    //states encoding for the traffic controller fsm
    parameter S_M_GREEN  = 3'd0, S_M_YELLOW = 3'd1, S_ALL_RED1 = 3'd2;
    parameter S_S_GREEN  = 3'd3, S_S_YELLOW = 3'd4, S_ALL_RED2 = 3'd5;
    parameter S_WALK = 3'd6; 
    // timing parameters in clock cycles
    parameter T_M_MIN = 60, T_S_EXACT = 40, T_P_EXACT = 40;
    parameter T_YELLOW = 5, T_ALL_RED = 2;

    reg [2:0] curr_state, next_state;
    reg [7:0] timer; //counts time spent in curr state
    reg vs_latch, pb_latch;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            vs_latch <= 1'b0; pb_latch <= 1'b0;
        end 
	   else begin
            if (VS) vs_latch <= 1'b1;
            if (PB) pb_latch <= 1'b1;
	       // clear requests once they are served
            if (curr_state == S_S_GREEN) vs_latch <= 1'b0;
            if (curr_state == S_WALK) pb_latch <= 1'b0;
        end
    end
   //state register
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            curr_state <= S_M_GREEN; timer <= 8'd0; //start with main road green
        end 
	    else begin
            if (curr_state != next_state) begin
                curr_state <= next_state; timer <= 8'd0;//move to next state & reset timer on state change
            end 
	       else timer <= timer + 8'd1;
         end
    end
   // next state logic 
    always @(*) begin
        next_state = curr_state;
        case (curr_state)
            //subtracting 1 cause we start timer from 0
            S_M_GREEN: if (timer >= (T_M_MIN-1) && (vs_latch || pb_latch || VS || PB)) next_state = S_M_YELLOW; //main road stays grn at least T_M_MIN cycles but when theres a request it beacomes yellow
            S_M_YELLOW: if (timer >= (T_YELLOW-1)) next_state = S_ALL_RED1;	 
		  // all-red after main yellow decide next		
            S_ALL_RED1: if (timer >= (T_ALL_RED-1))next_state = (pb_latch || PB) ? S_WALK : S_S_GREEN; //cause when reaching ALL_RED-1 a request has came if its not a ob then its a vs
            S_S_GREEN: if (timer >= (T_S_EXACT-1)) next_state = S_S_YELLOW;
            S_S_YELLOW: if (timer >= (T_YELLOW-1)) next_state = S_ALL_RED2;
            S_WALK: if (timer >= (T_P_EXACT-1)) next_state = S_ALL_RED2;
           // all-red before going back to main green
            S_ALL_RED2: if (timer >= (T_ALL_RED-1)) next_state = S_M_GREEN;
            default: next_state = S_M_GREEN;
        endcase
    end
	// output logic is moore -> depend only on state
    always @(*) begin 
		 //default outputs :all red & no walk
        light_main = 3'b100; light_side = 3'b100; walk = 1'b0;
        case (curr_state)
            S_M_GREEN: light_main = 3'b001;
            S_M_YELLOW: light_main = 3'b010;
            S_S_GREEN: light_side = 3'b001;
            S_S_YELLOW: light_side = 3'b010;
            S_WALK: walk = 1'b1;
        endcase
    end
endmodule

// refernce model

`timescale 1ns / 1ps
module traffic_ctrl_ref(
    input clk, rst, VS, PB,
    output reg [2:0] light_main, light_side,
    output reg walk
);

    // state encoding (same as rtl for easy comparison)
    parameter S_M_GREEN  = 3'd0, S_M_YELLOW = 3'd1, S_ALL_RED1 = 3'd2;
    parameter S_S_GREEN  = 3'd3, S_S_YELLOW = 3'd4, S_ALL_RED2 = 3'd5;
    parameter S_WALK = 3'd6;

    // timing in clock cycles
    parameter T_M_MIN = 60, T_S_EXACT = 40, T_P_EXACT = 40;
    parameter T_YELLOW = 5, T_ALL_RED = 2;

    reg [2:0] curr_state, next_state;
    reg [7:0] timer;
    reg vs_req, pb_req;

    // latch requests to avoid missing pulses
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            vs_req <= 0;
            pb_req <= 0;
        end else begin
            if (VS) vs_req <= 1;
            if (PB) pb_req <= 1;

            // clear request once served
            if (curr_state == S_S_GREEN) vs_req <= 0;
            if (curr_state == S_WALK)pb_req <= 0;
        end
    end

    // next state logic (behavioral)
    always @(*) begin
        next_state = curr_state;

        case (curr_state)
            S_M_GREEN: if (timer >= T_M_MIN-1 && (vs_req || pb_req || VS || PB)) next_state = S_M_YELLOW;
            S_M_YELLOW: if (timer >= T_YELLOW-1) next_state = S_ALL_RED1;

            // choose walk if pb exists otherwise side green
           S_ALL_RED1: if (timer >= T_ALL_RED-1) next_state = (pb_req || PB) ? S_WALK : S_S_GREEN;
            S_S_GREEN:if (timer >= T_S_EXACT-1) next_state = S_S_YELLOW;
            S_S_YELLOW: if (timer >= T_YELLOW-1)next_state = S_ALL_RED2;
            S_WALK:if (timer >= T_P_EXACT-1)next_state = S_ALL_RED2;
            S_ALL_RED2:if (timer >= T_ALL_RED-1) next_state = S_M_GREEN;

            default: next_state = S_M_GREEN;
        endcase
    end

    // state register + timer
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            curr_state <= S_M_GREEN;
            timer <= 0;
        end else begin
            if (curr_state != next_state) begin
                curr_state <= next_state;
                timer <= 0;
            end else begin
                timer <= timer + 1;
            end
        end
    end

    // output logic
    always @(*) begin
        light_main = 3'b100;
        light_side = 3'b100;
        walk = 0;

        case (curr_state)
            S_M_GREEN:light_main = 3'b001;
            S_M_YELLOW: light_main = 3'b010;
            S_S_GREEN:light_side = 3'b001;
            S_S_YELLOW: light_side = 3'b010;
            S_WALK:walk = 1;
        endcase
    end

endmodule


// self checking Testbench 

`timescale 1ns / 1ps
module traffic_ctrl_tb;

    reg clk, rst, VS, PB;
    // rtl outputs
    wire [2:0] light_main, light_side;
    wire walk;
    // reference outputs
    wire [2:0] ref_main, ref_side;
    wire ref_walk;

    integer error_count = 0;
    integer start_cycle, duration_cycles;
    integer cycle_count = 0;

    // signal for waveform || shows which test case we're in
    reg [3:0] tc;

    // instant rtl 
    traffic_ctrl uut (.clk(clk), .rst(rst), .VS(VS), .PB(PB), .light_main(light_main), .light_side(light_side), .walk(walk) );

    // instant reference model
    traffic_ctrl_ref ref_model (.clk(clk), .rst(rst), .VS(VS), .PB(PB),.light_main(ref_main), .light_side(ref_side), .walk(ref_walk) );

    // extra  signals for waveform || internal states & timers
    wire [2:0] uut_state = uut.curr_state;
    wire [7:0] uut_timer = uut.timer;
    wire [2:0] ref_state= ref_model.curr_state;
    wire [7:0] ref_timer= ref_model.timer;

    initial clk = 0;
    always #5 clk = ~clk;

    always @(posedge clk) cycle_count <= cycle_count + 1;

    always @(negedge clk) begin
//comparison is done on the negedge clk cause both rtl and reference make updates on posedge so we may catch one updated and the other not 
        if (rst) begin
            if (light_main !== ref_main || light_side !== ref_side || walk !== ref_walk) begin
                $display("\nMISMATCH cycle=%0d  tc=%0d", cycle_count, tc);
                $display(" RTL : M:%b S:%b W:%b | state=%0d timer=%0d", light_main, light_side, walk, uut_state, uut_timer);
                $display(" REF : M:%b S:%b W:%b | state=%0d timer=%0d\n", ref_main, ref_side, ref_walk, ref_state, ref_timer);
                error_count = error_count + 1;
            end
        end
    end

    // small prints for console run_ tasks were used since we have multiple test cases 
    task start_case;
        input string name;
        begin
 
            $display("Test Case %0d %0s", tc, name);

        end
    endtask

    task pass_msg;
    input string msg;
    begin
        $display("PASS: %s", msg);
    end
      endtask

    task fail_msg;
    input string msg;
    begin
        $display("FAIL: %s", msg);
        error_count = error_count + 1;
    end
      endtask

    // stimulus
    initial begin
        tc = 0;
        $display(" traffic_ctrl verification (rtl matches reference model ? )");

        rst = 0; VS = 0; PB = 0;
        repeat(5) @(posedge clk);
        rst = 1;
        repeat(2) @(posedge clk);

        // case 1: reset
        tc = 1; start_case("reset behavior (default main green)");
        rst = 0; VS = 0; PB = 0;
        repeat(5) @(posedge clk);
        rst = 1;
        repeat(2) @(posedge clk);

        if (light_main == 3'b001 && light_side == 3'b100 && walk == 0)
            pass_msg("after reset: main=green, side=red, walk=0");
        else
            fail_msg("wrong outputs after reset");

        // case 2: main road must stay grn for at least 60 cycles
        tc = 2; start_case("main road minimum green time (>= 60 cycles)");
        repeat(5) @(posedge clk);
        VS = 1; @(posedge clk); VS = 0;

        // should still be main grn before reaching min time
        repeat(50) @(posedge clk);
        if (light_main == 3'b001)
            pass_msg("main stayed green before minimum time (60) completed");
        else
            fail_msg("main changed before minimum time completed");

        // case 3: side road grn duration exactly 40 cycles
        tc = 3; start_case("side road green duration (exactly 40 cycles)");
        while (light_side != 3'b001) @(posedge clk);
        start_cycle = cycle_count;

        while (light_side == 3'b001) @(posedge clk);
        duration_cycles = cycle_count - start_cycle;

        if (duration_cycles == 40)
            pass_msg("side green lasted exactly 40 cycles");
        else begin
            $display(" measured side green = %0d cycles", duration_cycles);
            fail_msg("side green duration is not 40 cycles");
        end

        //case 4 & 5: pedestrian priority and walk duration
        tc = 4; start_case("pedestrian priority (PB over VS)");
        while (light_main != 3'b001) @(posedge clk);
        repeat(65) @(posedge clk);
        VS = 1; PB = 1; @(posedge clk); VS = 0; PB = 0;

        while (walk != 1'b1) @(posedge clk);
        pass_msg("walk was served (priority) when PB and VS happened together");

        tc = 5; start_case("walk duration (exactly 40 cycles)");
        start_cycle = cycle_count;

        while (walk == 1'b1) @(posedge clk);
        duration_cycles = cycle_count - start_cycle;

        if (duration_cycles == 40)
            pass_msg("walk stayed exactly 40 cycles");
        else begin
            $display(" measured walk = %0d cycles", duration_cycles);
            fail_msg("walk duration is not 40 cycles");
        end

        // case 6: request queuing during side grn
        tc = 6; start_case("pb queuing during side green (served next cycle)");
        while (light_main != 3'b001) @(posedge clk);
        repeat(65) @(posedge clk);
        VS = 1; @(posedge clk); VS = 0;

        while (light_side != 3'b001) @(posedge clk);
        repeat(10) @(posedge clk);

        $display(" pressing PB while side green is active");
        PB = 1; @(posedge clk); PB = 0;

        while (light_main != 3'b001) @(posedge clk);
        repeat(2) @(posedge clk);

        if (walk == 0)
            pass_msg("safe return to main (no immediate walk)");
        else
            fail_msg("walk happened immediately (should be queued)");

        while (walk != 1'b1) @(posedge clk);
        pass_msg("queued PB was served later (walk became 1)");

        // case 7: idle behavior (no requests)
        tc = 7; start_case("idle behavior (no requests soo main stays green)");
        while (light_main != 3'b001) @(posedge clk);
        repeat(100) @(posedge clk);

        if (light_main == 3'b001)
            pass_msg("main stayed green during idle period");
        else
            fail_msg("main did not stay green during idle period");

        // at last
        if (error_count == 0)
            $display(" FINAL RESULT: rtl matches reference model (PASS)");
        else
            $display(" FINAL RESULT: %0d errors/mismatches found (FAIL)", error_count);

        $finish;
    end

endmodule
