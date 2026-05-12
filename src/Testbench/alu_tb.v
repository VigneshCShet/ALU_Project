module alu_tb;
  reg clk;
  reg rst, mode, ce, cin;
  
  reg [1:0] inp_valid;
  
  reg [3:0] cmd;
  
  reg [7:0] opa, opb;
  
  wire err, oflow, cout, g, l, e;
  wire err_r, oflow_r, cout_r, g_r, l_r, e_r;
  
  wire [15:0] res;
  wire [15:0] res_r;
  
  integer tst_cnt  = 0;
  integer pass_cnt = 0;
  integer fail_cnt = 0;

  integer pass_log;
  integer fail_log;
  
  reg signed [7:0] opa_s;
  reg signed [7:0] opb_s;
  
  //dut
  ALU dut( 
    .CLK(clk), .RST(rst), .MODE(mode), .CE(ce),
    .INP_VALID(inp_valid),
    .CMD(cmd), 
    .OPA(opa), .OPB(opb), 
    .CIN(cin), 
    .RES(res), 
    .OFLOW(oflow), .COUT(cout), .G(g), .L(l), .E(e), .ERR(err)
  );
  
  //Reference  
  alu_ref scr_brd(
    .RST(rst), .INP_VALID(inp_valid), 
    .MODE(mode), 
    .CMD(cmd), .CE(ce), 
    .OPA(opa), .OPB(opb), 
    .CIN(cin), .ERR(err_r), .RES(res_r), .OFLOW(oflow_r), .COUT(cout_r), .G(g_r), .L(l_r), .E(e_r)
  );
  
  initial clk = 0;
  always #5 clk = ~clk;

//To create pass_log and Fail_log
  task write_log;
    input         passed;
    input [80*8:1] test_name;
    begin
    
      if (passed) begin
        $fdisplay(pass_log,
          "[PASS] %-40s | OPA=%d(%b) OPB=%d(%b) CMD=%d CIN=%b | RES=%d(%b) COUT=%b OFLOW=%b G=%b E=%b L=%b ERR=%b",
          test_name, opa, opa, opb, opb, cmd, cin,
          res, res, cout, oflow, g, e, l, err);
          
      end else begin
      
        $fdisplay(fail_log,
          "[FAIL] %-40s | OPA=%d(%b) OPB=%d(%b) CMD=%d CIN=%b test no = %d",
          test_name, opa, opa, opb, opb, cmd, cin, tst_cnt);
          
        $fdisplay(fail_log,
          "       DUT -> RES=(%d(%b) COUT=%b OFLOW=%b G=%b E=%b L=%b ERR=%b test no= %d",
          res, res, cout, oflow, g, e, l, err, tst_cnt);
          
        $fdisplay(fail_log,
          "       REF -> RES=%d(%b) COUT=%b OFLOW=%b G=%b E=%b L=%b ERR=%b test no = %d",
          res_r, res_r, cout_r, oflow_r, g_r, e_r, l_r, err_r, tst_cnt);
          
        $fdisplay(fail_log, "");
      end
    end
  endtask

  //Tasks
  task apply_inp_arith(
    input ce_a,
    input [1:0] inp_valid_a, 
    input [3:0] cmd_a,
    input [7:0] opa_a, opb_a,
    input cin_a,
    input [80*8:1] test_name
  );
    begin
      @(negedge clk);
      mode = 1;
      ce = ce_a;
      inp_valid = inp_valid_a;
      cmd = cmd_a;
      opa = opa_a;
      opb = opb_a;
      cin = cin_a;
      if((cmd == 11 || cmd == 12) && mode) begin
        
        $display("i/p -> MODE = %b | CE = %b | INP_VALID = %b | CMD = %d | OPA = %0d | OPB = %0d | CIN = %b", mode, ce, inp_valid, cmd, opa_s, opb_s, cin);
      end
      else
        $display("i/p -> MODE = %b | CE = %b | INP_VALID = %b | CMD = %d | OPA = %d | OPB = %d | CIN = %b", mode, ce, inp_valid, cmd, opa, opb, cin);
      @(posedge clk);
      @(posedge clk);
      #1;
      tst_cnt = tst_cnt + 1;
      check_mess(test_name);
    end
  endtask
  
  task apply_inp_arith_mul(
    input ce_a,
    input [1:0] inp_valid_a, 
    input [3:0] cmd_a,
    input [7:0] opa_a, opb_a,
    input cin_a,
    input [80*8:1] test_name
  );
    begin
      @(negedge clk);
      mode = 1;
      ce = ce_a;
      inp_valid = inp_valid_a;
      cmd = cmd_a;
      opa = opa_a;
      opb = opb_a;
      cin = cin_a;
      $display("i/p -> MODE = %b | CE = %b | INP_VALID = %b | CMD = %d | OPA = %d | OPB = %d | CIN = %b", mode, ce, inp_valid, cmd, opa, opb, cin);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      #1;
      tst_cnt = tst_cnt + 1;
      if(cmp_res(res, res_r)) begin
        $display("[PASS] %0s: OPA = %d OPB = %d CMD = %d", test_name, opa, opb, cmd);
        write_log(1, test_name);
        pass_cnt = pass_cnt + 1;
      end 
      else begin
        $display("[FAIL] %0s: OPA = %d OPB = %d CMD = %d", test_name, opa, opb, cmd);
        display_mismatch_arith();
        write_log(0, test_name);
        fail_cnt = fail_cnt + 1;
      end
    end
  endtask
  
  task apply_inp_logic(
    input ce_a,
    input [1:0] inp_valid_a, 
    input [3:0] cmd_a,
    input [7:0] opa_a, opb_a,
    input cin_a,
    input [80*8:1] test_name
  );
    begin
      @(negedge clk);
      mode = 0;
      ce = ce_a;
      inp_valid = inp_valid_a;
      cmd = cmd_a;
      opa = opa_a;
      opb = opb_a;
      cin = cin_a;
      $display("i/p -> MODE = %b | CE = %b | INP_VALID = %b | CMD = %d | OPA = %b | OPB = %b | CIN = %b", mode, ce, inp_valid, cmd, opa, opb, cin);
      @(posedge clk);
      @(posedge clk);
      #1;
      tst_cnt = tst_cnt + 1;
      if(cmp_res(res, res_r)) begin
        $display("[PASS] %0s: OPA = %b OPB = %b CMD = %d test no = %d", test_name, opa, opb, cmd, tst_cnt);
        write_log(1, test_name);
        pass_cnt = pass_cnt + 1;
      end 
      else begin
        $display("[FAIL] %0s: OPA = %b OPB = %b CMD = %d Test = %d", test_name, opa, opb, cmd, tst_cnt);
        display_mismatch_logic();
        write_log(0, test_name);
        fail_cnt = fail_cnt + 1;
      end
    end
  endtask
  
  task apply_inp_gen(
    input mode_a, ce_a, 
    input [1:0] inp_valid_a, 
    input [3:0] cmd_a,
    input [7:0] opa_a, opb_a,
    input cin_a,
    input [80*8:1] test_name
  );
    begin
      @(negedge clk);
      mode = mode_a;
      ce = ce_a;
      inp_valid = inp_valid_a;
      cmd = cmd_a;
      opa = opa_a;
      opb = opb_a;
      cin = cin_a;
      $display("i/p -> MODE = %b | CE = %b | INP_VALID = %b | CMD = %d | OPA = %d | OPB = %d | CIN = %b", mode, ce, inp_valid, cmd, opa, opb, cin);
      
    end
  endtask
  
  task check_mess(input [80*8:1] test_name);
    begin
      if(cmp_res(res, res_r)) begin
        $display("[PASS] %0s: OPA = %d OPB = %d CMD = %d Test = %d", test_name, opa, opb, cmd, tst_cnt);
        write_log(1, test_name);
        pass_cnt = pass_cnt + 1;
      end 
      else begin
        if((cmd == 11 || cmd == 12) && mode)
          $display("[FAIL] %0s: OPA = %d OPB = %d CMD = %d Test = %d", test_name, opa_s, opb_s, cmd, tst_cnt);
        else
          $display("[FAIL] %0s: OPA = %d OPB = %d CMD = %d Test = %d", test_name, opa, opb, cmd, tst_cnt);
        display_mismatch_arith();
        write_log(0, test_name);
        fail_cnt = fail_cnt + 1;
      end
    end
  endtask
  
  task reset_n;
    begin
      rst = 1;
      mode = 0;
    	ce = 0;
    	cin = 0;
  
      inp_valid = 0;
  
      cmd = 0;
  
      opa = 0;
      opb = 0;
      @(posedge clk);
      @(posedge clk);
      rst = 0;
      @(posedge clk);
      #1;
    end
  endtask
  
  function cmp_bt(input dut, input refer);
    begin
      if (dut === refer)
        cmp_bt = 1;
      else
        cmp_bt = 0;
    end
  endfunction
    
  function cmp_res(input [15:0] res_dut, input [15:0] res_ref);
    begin
      cmp_res = 1;
      if(res_dut === res_ref)
        cmp_res = 1;
      else
        cmp_res = 0;
      if (!cmp_bt(cout,  cout_r))  cmp_res = 0;
      if (!cmp_bt(oflow, oflow_r)) cmp_res = 0;
      if (!cmp_bt(g,     g_r))     cmp_res = 0;
      if (!cmp_bt(e,     e_r))     cmp_res = 0;
      if (!cmp_bt(l,     l_r))     cmp_res = 0;
      if (!cmp_bt(err,   err_r))   cmp_res = 0;
    end
  endfunction
  
  task display_mismatch_arith();
    begin
      $display("DUT: RES = %d COUT = %b OFLOW = %b G = %b E = %b L = %b ERR = %b", res,   cout,   oflow,   g,   e,   l,   err);
      $display("REF: RES = %d COUT = %b OFLOW = %b G = %b E = %b L = %b ERR = %b", res_r, cout_r, oflow_r, g_r, e_r, l_r, err_r);
    end
  endtask
    
  task display_mismatch_logic();
    begin
      $display("DUT: RES = %b COUT = %b OFLOW = %b G = %b E = %b L = %b ERR = %b", res,   cout,   oflow,   g,   e,   l,   err);
      $display("REF: RES = %b COUT = %b OFLOW = %b G = %b E = %b L = %b ERR = %b", res_r, cout_r, oflow_r, g_r, e_r, l_r, err_r);
    end
  endtask
  
  task arithmetic_ip_add;
    begin
      repeat(20) begin
        apply_inp_arith(1, 3, 0, $urandom_range(30), $urandom_range(50, 20), 0, "ADD");
      end
    end
  endtask
  
  task arithmetic_mul_ip;
    begin
      repeat(20) begin
        apply_inp_arith_mul(1, 3, 9, $urandom_range(10), $urandom_range(10), 0, "MUL");
      end
    end
  endtask

 //Stimulus
  initial begin
  
    pass_log = $fopen("pass_log.txt", "w");
    fail_log = $fopen("fail_log.txt", "w");

    $fdisplay(pass_log, "ALU PASS LOG");
    $fdisplay(pass_log, "%-60s | %-40s | OUTPUTS", "TEST_NAME", "INPUTS");
    $fdisplay(pass_log, "%0s", {"--------------------------------------------------------------------------------------------------------------------------------"});

    $fdisplay(fail_log, "ALU FAIL LOG");
    $fdisplay(fail_log, "%-60s | %-40s | DUT vs REF", "TEST_NAME", "INPUTS");
    $fdisplay(fail_log, "%0s", {"--------------------------------------------------------------------------------------------------------------------------------"});

    // ---- Reset ----
    reset_n();
    opa_s = $signed(opa);
    opb_s = $signed(opb);
   

    // BASIC / RANDOM TESTS

    arithmetic_ip_add();
    arithmetic_mul_ip();


    // ARITHMETIC MODE (MODE=1)


   // --- ADD (CMD=0) ---
    apply_inp_arith(1, 2'b11, 4'd0, 8'h10, 8'h20, 0, "arith_add_no_cout");
    apply_inp_arith(1, 2'b11, 4'd0, 8'hFF, 8'h01, 0, "arith_add_cout_boundary");
    apply_inp_arith(1, 2'b11, 4'd0, 8'h00, 8'h00, 0, "arith_add_zero_operands");
    apply_inp_arith(1, 2'b10, 4'd0, 8'h10, 8'h20, 0, "arith_add_no_cout_invalid_inp_valid");

    // --- ADD_CIN (CMD=2) ---
    apply_inp_arith(1, 2'b11, 4'd2, 8'h0F, 8'h01, 0, "arith_add_cin_zero");
    apply_inp_arith(1, 2'b11, 4'd2, 8'hFF, 8'hFF, 1, "arith_add_cin_max_overflow");
    apply_inp_arith(1, 2'b11, 4'd2, 8'h05, 8'h03, 1, "arith_add_carry_no_oflow");
    apply_inp_arith(1, 2'b11, 4'd2, 8'hFE, 8'h01, 1, "arith_add_carry_cout");
    apply_inp_arith(1, 2'b10, 4'd2, 8'h05, 8'h03, 1, "arith_add_carry_no_oflow");

    // --- SUB (CMD=1) ---
    apply_inp_arith(1, 2'b11, 4'd1, 8'h50, 8'h20, 0, "arith_sub_normal");
    apply_inp_arith(1, 2'b11, 4'd1, 8'h00, 8'h01, 0, "arith_sub_oflow_opa_lt_opb");
    apply_inp_arith(1, 2'b11, 4'd1, 8'h55, 8'h55, 0, "arith_sub_equal_operands");
    apply_inp_arith(1, 2'b10, 4'd1, 8'h50, 8'h20, 0, "arith_sub_normal_inp_invalid");

    // --- SUB_CIN (CMD=3) ---
    apply_inp_arith(1, 2'b11, 4'd3, 8'h10, 8'h05, 0, "arith_sub_cin_normal");
    apply_inp_arith(1, 2'b11, 4'd3, 8'h00, 8'h00, 1, "arith_sub_cin_underflow");
    apply_inp_arith(1, 2'b11, 4'd3, 8'h05, 8'h06, 1, "arith_sub_cin_oflow");
    apply_inp_arith(1, 2'b10, 4'd3, 8'h10, 8'h05, 0, "arith_sub_cin_normal_inp_invalid");

    // --- INC_A (CMD=4) ---
    apply_inp_arith(1, 2'b01, 4'd4, 8'h0A, 8'h00, 0, "arith_inc_a_normal");
    apply_inp_arith(1, 2'b01, 4'd4, 8'hFF, 8'h00, 0, "arith_inc_a_wrap");

    // --- DEC_A (CMD=5) ---
    apply_inp_arith(1, 2'b01, 4'd5, 8'h0A, 8'h00, 0, "arith_dec_a_normal");
    apply_inp_arith(1, 2'b01, 4'd5, 8'h00, 8'h00, 0, "arith_dec_a_wrap");

    // --- INC_B (CMD=6) ---
    apply_inp_arith(1, 2'b10, 4'd6, 8'h00, 8'h0A, 0, "arith_inc_b_normal");
    apply_inp_arith(1, 2'b10, 4'd6, 8'h00, 8'hFF, 0, "arith_inc_b_wrap");

    // --- DEC_B (CMD=7) ---
    apply_inp_arith(1, 2'b10, 4'd7, 8'h00, 8'h0A, 0, "arith_dec_b_normal");
    apply_inp_arith(1, 2'b10, 4'd7, 8'h00, 8'h00, 0, "arith_dec_b_wrap");

    // --- CMP (CMD=8) ---
    apply_inp_arith(1, 2'b11, 4'd8, 8'h55, 8'h55, 0, "arith_cmp_equal");
    apply_inp_arith(1, 2'b11, 4'd8, 8'hFF, 8'h00, 0, "arith_cmp_opa_max_opb_zero");
    apply_inp_arith(1, 2'b11, 4'd8, 8'h01, 8'hFF, 0, "arith_cmp_opa_lt_opb");
    apply_inp_arith(1, 2'b11, 4'd8, 8'h00, 8'h00, 0, "arith_cmp_both_zero");
    apply_inp_arith(1, 2'b10, 4'd8, 8'h00, 8'h00, 0, "arith_cmp_both_zero_inp_invalid");

    // --- SIGNED_ADD (CMD=11) ---
    apply_inp_arith(1, 2'b11, 4'd11, 8'h7F, 8'h01, 0, "arith_signed_add_pos_overflow");
    apply_inp_arith(1, 2'b11, 4'd11, 8'h80, 8'h80, 0, "arith_signed_add_neg_overflow");
    apply_inp_arith(1, 2'b11, 4'd11, 8'h05, 8'h03, 0, "arith_signed_add_opa_gt_opb");
    apply_inp_arith(1, 2'b11, 4'd11, 8'hFE, 8'h02, 0, "arith_signed_add_opa_lt_opb");
    apply_inp_arith(1, 2'b11, 4'd11, 8'h05, 8'h05, 0, "arith_signed_add_equal");
    apply_inp_arith(1, 2'b11, 4'd11, 8'h7F, 8'h7F, 0, "arith_signed_add_pos_overflow");
    apply_inp_arith(1, 2'b11, 4'd11, 8'hFF, 8'hFF, 0, "arith_signed_add_pos_overflow");
    apply_inp_arith(1, 2'b01, 4'd11, 8'hFE, 8'h02, 0, "arith_signed_add_opa_lt_opb_inp_invalid");
    apply_inp_arith(1, 2'b11, 4'd11, 8'h7F, 8'h7F, 0, "signed_add_pos_oflow_7F_7F");
    apply_inp_arith(1, 2'b11, 4'd11, 8'h7F, 8'h01, 0, "signed_add_pos_oflow_7F_01");
    apply_inp_arith(1, 2'b11, 4'd11, 8'h40, 8'h40, 0, "signed_add_pos_oflow_40_40");
    apply_inp_arith(1, 2'b11, 4'd11, 8'h80, 8'h80, 0, "signed_add_neg_oflow_80_80");
		apply_inp_arith(1, 2'b11, 4'd11, 8'hFF, 8'hFF, 0, "signed_add_neg_oflow_FF_FF");
		apply_inp_arith(1, 2'b11, 4'd11, 8'hC0, 8'hC0, 0, "signed_add_neg_oflow_C0_C0");
    apply_inp_arith(1, 2'b11, 4'd11, 8'h88, 8'h87, 0, "signed_addcmp_check");
    apply_inp_arith(1, 2'b11, 4'd11, 8'h87, 8'h88, 0, "signed_addcmp_check");
    // --- SIGNED_SUB (CMD=12 arith) ---
    apply_inp_arith(1, 2'b11, 4'd12, 8'h7F, 8'hFF, 0, "arith_signed_sub_pos_overflow");
    apply_inp_arith(1, 2'b11, 4'd12, 8'h80, 8'h01, 0, "arith_signed_sub_neg_overflow");
    apply_inp_arith(1, 2'b11, 4'd12, 8'h55, 8'h55, 0, "arith_signed_sub_equal");
    apply_inp_arith(1, 2'b11, 4'd12, 8'hFE, 8'h02, 0, "arith_signed_sub_opa_lt_opb");
    apply_inp_arith(1, 2'b11, 4'd12, 8'h00, 8'hFF, 0, "arith_signed_sub_pos_overflow");
    apply_inp_arith(1, 2'b11, 4'd12, 8'h00, 8'h01, 0, "arith_signed_sub_pos_overflow");
    apply_inp_arith(1, 2'b10, 4'd12, 8'h00, 8'h01, 0, "arith_signed_sub_pos_inp_invalid");
    apply_inp_arith(1, 2'b11, 4'd12, 8'h7F, 8'h7F, 0, "signed_add_pos_oflow_7F_7F");
    apply_inp_arith(1, 2'b11, 4'd12, 8'h7F, 8'h01, 0, "signed_add_pos_oflow_7F_01");
    apply_inp_arith(1, 2'b11, 4'd12, 8'h40, 8'h40, 0, "signed_add_pos_oflow_40_40");
    apply_inp_arith(1, 2'b11, 4'd12, 8'h80, 8'h80, 0, "signed_add_neg_oflow_80_80");
		apply_inp_arith(1, 2'b11, 4'd12, 8'hFF, 8'hFF, 0, "signed_add_neg_oflow_FF_FF");
		apply_inp_arith(1, 2'b11, 4'd12, 8'hC0, 8'hC0, 0, "signed_add_neg_oflow_C0_C0");
		apply_inp_arith(1, 2'b11, 4'd11, 8'h88, 8'h87, 0, "signed_addcmp_check");
    apply_inp_arith(1, 2'b11, 4'd11, 8'h87, 8'h88, 0, "signed_addcmp_check");
		
    // --- MUL_INC (CMD=9) ---
    apply_inp_arith_mul(1, 2'b11, 4'd9, 8'h02, 8'h03, 0, "arith_mul_inc_2x3");
    apply_inp_arith_mul(1, 2'b11, 4'd9, 8'h00, 8'h0A, 0, "arith_mul_inc_zero_opa");
    apply_inp_arith_mul(1, 2'b11, 4'd9, 8'h0A, 8'h00, 0, "arith_mul_inc_zero_opb");
    apply_inp_arith_mul(1, 2'b11, 4'd9, 8'h0F, 8'h0F, 0, "arith_mul_inc_max_small");
    apply_inp_arith_mul(1, 2'b10, 4'd9, 8'h02, 8'h03, 0, "arith_mul_inc_2x3_inp_invalid");

    // --- MUL_SHIFT (CMD=10) ---
    apply_inp_arith_mul(1, 2'b11, 4'd10, 8'h05, 8'h04, 0, "arith_mul_shift_5x4");
    apply_inp_arith_mul(1, 2'b11, 4'd10, 8'h00, 8'h0A, 0, "arith_mul_shift_zero_opa");
    apply_inp_arith_mul(1, 2'b11, 4'd10, 8'h0F, 8'h0F, 0, "arith_mul_shift_max_small");
    apply_inp_arith_mul(1, 2'b10, 4'd10, 8'h00, 8'h0A, 0, "arith_mul_shift_zero_opa_inp_invalid");


    // INVALID CMD (Arithmetic) - ERR expected

    apply_inp_arith(1, 2'b11, 4'd13, 8'h55, 8'h55, 0, "arith_invalid_cmd_13");
    apply_inp_arith(1, 2'b11, 4'd14, 8'h55, 8'h55, 0, "arith_invalid_cmd_14");
    apply_inp_arith(1, 2'b11, 4'd15, 8'h55, 8'h55, 0, "arith_invalid_cmd_15");

    // INP_VALID checks (Arithmetic) - ERR expected
    apply_inp_arith(1, 2'b00, 4'd0,  8'hAA, 8'hBB, 0, "arith_add_inp_valid_00");
    apply_inp_arith(1, 2'b01, 4'd0,  8'hAA, 8'hBB, 0, "arith_add_inp_valid_01");
    apply_inp_arith(1, 2'b10, 4'd0,  8'hAA, 8'hBB, 0, "arith_add_inp_valid_10");
    apply_inp_arith(1, 2'b10, 4'd4,  8'hAA, 8'hBB, 0, "arith_inc_a_inp_valid_b0_zero");
    apply_inp_arith(1, 2'b00, 4'd5,  8'hAA, 8'hBB, 0, "arith_dec_a_inp_valid_00");
    apply_inp_arith(1, 2'b01, 4'd6,  8'hAA, 8'hBB, 0, "arith_inc_b_inp_valid_b1_zero");
    apply_inp_arith(1, 2'b00, 4'd7,  8'hAA, 8'hBB, 0, "arith_dec_b_inp_valid_00");
    apply_inp_arith(1, 2'b00, 4'd8,  8'hAA, 8'hBB, 0, "arith_cmp_inp_valid_invalid");
    apply_inp_arith(1, 2'b01, 4'd8,  8'hAA, 8'hBB, 0, "arith_cmp_inp_valid_01");
    apply_inp_arith(1, 2'b01, 4'd9,  8'h02, 8'h03, 0, "arith_mul_inc_inp_valid_invalid");
    apply_inp_arith(1, 2'b10, 4'd10, 8'h02, 8'h03, 0, "arith_mul_shift_inp_valid_invalid");
    apply_inp_arith(1, 2'b01, 4'd11, 8'hAA, 8'hBB, 0, "arith_signed_add_inp_valid_invalid");
    apply_inp_arith(1, 2'b00, 4'd12, 8'hAA, 8'hBB, 0, "arith_signed_sub_inp_valid_invalid");


    // LOGIC MODE (MODE=0)


    // --- AND (CMD=0) ---
    apply_inp_logic(1, 2'b11, 4'd0,  8'hFF, 8'hFF, 0, "logic_and_all_ones");
    apply_inp_logic(1, 2'b11, 4'd0,  8'hAA, 8'h55, 0, "logic_and_no_overlap");
    apply_inp_logic(1, 2'b00, 4'd0,  8'hAA, 8'h55, 0, "logic_and_inp_valid_00");

    // --- NAND (CMD=1) ---
    apply_inp_logic(1, 2'b11, 4'd1,  8'hFF, 8'hFF, 0, "logic_nand_all_ones");
    apply_inp_logic(1, 2'b01, 4'd1,  8'hFF, 8'hFF, 0, "logic_nand_inp_valid_invalid");

    // --- OR (CMD=2) ---
    apply_inp_logic(1, 2'b11, 4'd2,  8'hAA, 8'h55, 0, "logic_or_complementary");
    apply_inp_logic(1, 2'b11, 4'd2,  8'h00, 8'h00, 0, "logic_or_zeros");
    apply_inp_logic(1, 2'b11, 4'd2,  8'hAA, 8'h55, 0, "logic_or_inp_invalid");

    // --- NOR (CMD=3) ---
    apply_inp_logic(1, 2'b11, 4'd3,  8'h00, 8'h00, 0, "logic_nor_zeros");
    apply_inp_logic(1, 2'b00, 4'd3,  8'h00, 8'h00, 0, "logic_nor_inp_valid_invalid");

    // --- XOR (CMD=4) ---
    apply_inp_logic(1, 2'b11, 4'd4,  8'hAA, 8'h55, 0, "logic_xor_complementary");
    apply_inp_logic(1, 2'b11, 4'd4,  8'hFF, 8'hFF, 0, "logic_xor_same_inputs");
    apply_inp_logic(1, 2'b01, 4'd4,  8'hAA, 8'h55, 0, "logic_xor_inp_valid_invalid");

    // --- XNOR (CMD=5) ---
    apply_inp_logic(1, 2'b11, 4'd5,  8'hAA, 8'hAA, 0, "logic_xnor_same_inputs");
    apply_inp_logic(1, 2'b01, 4'd5,  8'hAA, 8'hAA, 0, "logic_xnor_inp_valid_invalid");

    // --- NOT_A (CMD=6) ---
    apply_inp_logic(1, 2'b01, 4'd6,  8'hAA, 8'h00, 0, "logic_not_a");
    apply_inp_logic(1, 2'b01, 4'd6,  8'hFF, 8'h00, 0, "logic_not_a_all_ones");
		apply_inp_logic(1, 2'b01, 4'd5,  8'hAA, 8'hAA, 0, "logic_not_inp_valid_invalid");
    // --- NOT_B (CMD=7) ---
    apply_inp_logic(1, 2'b10, 4'd7,  8'h00, 8'hAA, 0, "logic_not_b");
    apply_inp_logic(1, 2'b01, 4'd7,  8'h00, 8'hAA, 0, "logic_not_b_inp_valid_b1_zero");

    // --- SHR_A (CMD=8) ---
    apply_inp_logic(1, 2'b01, 4'd8,  8'hAA, 8'h00, 0, "logic_shr_a");
    apply_inp_logic(1, 2'b00, 4'd8,  8'hAA, 8'h00, 0, "logic_shr_a_inp_valid_00");

    // --- SHL_A (CMD=9) ---
    apply_inp_logic(1, 2'b01, 4'd9,  8'h80, 8'h00, 0, "logic_shl_a_msb_lost");
    apply_inp_logic(1, 2'b01, 4'd9,  8'h01, 8'h00, 0, "logic_shl_a_lsb");
    apply_inp_logic(1, 2'b10, 4'd9,  8'h01, 8'h00, 0, "logic_shl_a_inp_valid_invalid");
    apply_inp_logic(1, 2'b11, 4'd9,  8'h01, 8'h00, 0, "logic_shl_a_inp_valid_invalid");

    // --- SHR_B (CMD=10) ---
    apply_inp_logic(1, 2'b10, 4'd10, 8'h00, 8'hAA, 0, "logic_shr_b");
    apply_inp_logic(1, 2'b01, 4'd10, 8'h00, 8'hAA, 0, "logic_shr_b_inp_valid_b1_zero");

    // --- SHL_B (CMD=11) ---
    apply_inp_logic(1, 2'b10, 4'd11, 8'h00, 8'h01, 0, "logic_shl_b");
    apply_inp_logic(1, 2'b01, 4'd11, 8'h00, 8'h01, 0, "logic_shl_b_inp_valid_b1_zero");

    // --- ROL (CMD=12) ---
    apply_inp_logic(1, 2'b11, 4'd12, 8'hB4, 8'h01, 0, "logic_rol_by_1");
    apply_inp_logic(1, 2'b11, 4'd12, 8'hB4, 8'h02, 0, "logic_rol_by_2");
    apply_inp_logic(1, 2'b11, 4'd12, 8'hB4, 8'h03, 0, "logic_rol_by_3");
    apply_inp_logic(1, 2'b11, 4'd12, 8'hB4, 8'h04, 0, "logic_rol_by_4");
    apply_inp_logic(1, 2'b11, 4'd12, 8'hB4, 8'h05, 0, "logic_rol_by_5");
    apply_inp_logic(1, 2'b11, 4'd12, 8'hB4, 8'h06, 0, "logic_rol_by_6");
    apply_inp_logic(1, 2'b11, 4'd12, 8'hB4, 8'h07, 0, "logic_rol_by_7");
    apply_inp_logic(1, 2'b11, 4'd12, 8'hB4, 8'h00, 0, "logic_rol_opb_zero_no_rotation");
    apply_inp_logic(1, 2'b11, 4'd12, 8'hB4, 8'h80, 0, "logic_rol_opb_bit7_set");
    apply_inp_logic(1, 2'b11, 4'd12, 8'hB4, 8'h40, 0, "logic_rol_opb_bit6_set");
    apply_inp_logic(1, 2'b11, 4'd12, 8'hB4, 8'h20, 0, "logic_rol_opb_bit5_set");
    apply_inp_logic(1, 2'b11, 4'd12, 8'hB4, 8'h10, 0, "logic_rol_opb_bit4_set");
    apply_inp_logic(1, 2'b11, 4'd12, 8'hB4, 8'h08, 0, "logic_rol_opb_bit3_set_only");
    apply_inp_logic(1, 2'b01, 4'd12, 8'hB4, 8'h03, 0, "logic_rol_inp_valid_invalid");
    apply_inp_logic(1, 2'b11, 4'd12, 8'hB4, 8'b10001101, 0, "logic_ror_inp_valid_invalid");
    apply_inp_logic(1, 2'b11, 4'd12, 8'hB4, 8'b01001101, 0, "logic_ror_inp_valid_invalid");
    apply_inp_logic(1, 2'b11, 4'd12, 8'hB4, 8'b00101101, 0, "logic_ror_inp_valid_invalid");
    apply_inp_logic(1, 2'b11, 4'd12, 8'hB4, 8'b00011101, 0, "logic_ror_inp_valid_invalid");

    // --- ROR (CMD=13) ---
    apply_inp_logic(1, 2'b11, 4'd13, 8'hB4, 8'h01, 0, "logic_ror_by_1");
    apply_inp_logic(1, 2'b11, 4'd13, 8'hB4, 8'h02, 0, "logic_ror_by_2");
    apply_inp_logic(1, 2'b11, 4'd13, 8'hB4, 8'h03, 0, "logic_ror_by_3");
    apply_inp_logic(1, 2'b11, 4'd13, 8'hB4, 8'h04, 0, "logic_ror_by_4");
    apply_inp_logic(1, 2'b11, 4'd13, 8'hB4, 8'h05, 0, "logic_ror_by_5");
    apply_inp_logic(1, 2'b11, 4'd13, 8'hB4, 8'h06, 0, "logic_ror_by_6");
    apply_inp_logic(1, 2'b11, 4'd13, 8'hB4, 8'h07, 0, "logic_ror_by_7");
    apply_inp_logic(1, 2'b11, 4'd13, 8'hB4, 8'h00, 0, "logic_ror_opb_zero_no_rotation");
    apply_inp_logic(1, 2'b11, 4'd13, 8'hB4, 8'h80, 0, "logic_ror_opb_upper_nibble_set");
    apply_inp_logic(1, 2'b10, 4'd13, 8'hB4, 8'h03, 0, "logic_ror_inp_valid_invalid");
    apply_inp_logic(1, 2'b11, 4'd13, 8'hB4, 8'hF3, 0, "logic_ror_inp_valid_invalid");
    apply_inp_logic(1, 2'b11, 4'd13, 8'hB4, 8'b10001101, 0, "logic_ror_inp_valid_invalid");
    apply_inp_logic(1, 2'b11, 4'd13, 8'hB4, 8'b01001101, 0, "logic_ror_inp_valid_invalid");
    apply_inp_logic(1, 2'b11, 4'd13, 8'hB4, 8'b00101101, 0, "logic_ror_inp_valid_invalid");
    apply_inp_logic(1, 2'b11, 4'd13, 8'hB4, 8'b00011101, 0, "logic_ror_inp_valid_invalid");

    // --- Invalid CMD (Logic mode) ---
    apply_inp_logic(1, 2'b11, 4'd14, 8'hAA, 8'h55, 0, "logic_invalid_cmd_14");
    apply_inp_logic(1, 2'b11, 4'd15, 8'hAA, 8'h55, 0, "logic_invalid_cmd_15");

    // --- INP_VALID corner cases (Logic) ---
    apply_inp_logic(1, 2'b00, 4'd4,  8'hAA, 8'h55, 0, "logic_xor_inp_valid_00");
    apply_inp_logic(1, 2'b10, 4'd6,  8'hFF, 8'h00, 0, "logic_not_a_inp_valid_b0_zero");
    apply_inp_logic(1, 2'b01, 4'd7,  8'h00, 8'hFF, 0, "logic_not_b_inp_valid_b1_zero2");
    apply_inp_logic(1, 2'b00, 4'd8,  8'hAA, 8'h00, 0, "logic_shr_a_inp_valid_b0_zero");
    apply_inp_logic(1, 2'b01, 4'd10, 8'h00, 8'hAA, 0, "logic_shr_b_inp_valid_b1_zero2");
    apply_inp_logic(1, 2'b01, 4'd11, 8'h00, 8'h01, 0, "logic_shl_b_inp_valid_b1_zero2");


    // CE CORNER CASES

    apply_inp_arith(1, 2'b11, 4'd0, 8'h10, 8'h10, 0, "ce_pre_add");
    apply_inp_gen(1, 0, 2'b11, 4'd0, 8'hFF, 8'hFF, 0, "ce_disable_hold_outputs");
    @(posedge clk); @(posedge clk); @(posedge clk);
    apply_inp_gen(1, 0, 2'b11, 4'd0, 8'h33, 8'h44, 0, "ce_zero_before_reenable");
    @(posedge clk); @(posedge clk);
    apply_inp_arith(1, 2'b11, 4'd0, 8'h33, 8'h44, 0, "ce_reenable_resumes_operation");

    reset_n();
    repeat(5) begin
      apply_inp_gen(1, 0, 2'b11, 4'd0, 8'h0A, 8'h0A, 0, "ce_zero_before_first_enable");
    end
    apply_inp_arith(1, 2'b11, 4'd0, 8'h0A, 8'h0A, 0, "ce_first_enable_add");


    // RST CORNER CASES
    apply_inp_gen(1, 1, 2'b11, 4'd0, 8'h20, 8'h30, 0, "pre_rst_during_op");
    #2;
    rst = 1;
     @(posedge clk);
     
     tst_cnt = tst_cnt + 1;
    check_mess("reset_during_operation"); 
     rst = 0; 
     @(posedge clk);

    reset_n();
    
    tst_cnt = tst_cnt + 1;
    check_mess("reset_deassert_all_outputs_zero");

    // CMD/MODE CHANGE CORNER CASES

    @(posedge clk);
    apply_inp_gen(1,1,2'b11,4'd9, 8'h20, 8'h30, 0, "cmd_change_during_multiplication");
    @(negedge clk);
    cmd = 10;
    @(posedge clk);
    @(posedge clk);
    #1;
    tst_cnt = tst_cnt + 1;
    check_mess("cmd_change_during_multiplication");
    
    @(posedge clk);
    apply_inp_gen(1,1,2'b11,4'd9, 8'h20, 8'h30, 0, "mode_change_during_multiplication");
    @(negedge clk);
    mode = 0;
    @(posedge clk);
    @(posedge clk);
    #1;
    tst_cnt = tst_cnt + 1;
    check_mess("mode_change_during_multiplication");
   

    // --- Single operand on 2-operand CMDs ---
    apply_inp_arith(1, 2'b01, 4'd2,  8'h0F, 8'h01, 1, "invalid_input_drive_add_cin");
    apply_inp_logic(1, 2'b01, 4'd2,  8'hAA, 8'h55, 0, "invalid_input_drive_or");


  
    #10;
    $display("===== TEST SUMMARY: TOTAL=%0d PASS=%0d FAIL=%0d =====", tst_cnt, pass_cnt, fail_cnt);
    $fdisplay(pass_log, "--------------------------------------------------------------------------------------------------------------------------------");
    $fdisplay(pass_log, "TOTAL = %0d  |  PASS = %0d  |  FAIL = %0d", tst_cnt, pass_cnt, fail_cnt);
    $fdisplay(fail_log, "--------------------------------------------------------------------------------------------------------------------------------");
    $fdisplay(fail_log, "TOTAL = %0d  |  PASS = %0d  |  FAIL = %0d", tst_cnt, pass_cnt, fail_cnt);
    $fclose(pass_log);
    $fclose(fail_log);
    $finish;
  end
  
endmodule
