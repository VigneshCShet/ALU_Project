`default_nettype none
module ALU #(parameter in_a = 8, in_b = 8, out_width = 2*in_a)(CLK, RST, INP_VALID, MODE, CMD, CE, OPA, OPB, CIN, ERR, RES, OFLOW, COUT, G, L, E);

  //Input declaration
  input wire CLK, RST, CE, MODE, CIN;
  input wire [3:0] CMD;
  input wire [1:0] INP_VALID;
  input wire [in_a - 1 : 0] OPA;
  input wire [in_a - 1 : 0] OPB;
  
  //Output declaration
  output reg [out_width - 1 : 0] RES;
  output reg OFLOW, COUT, G, L, E, ERR;

  //Registers declaration
  reg busy;
  reg cin, mode, ce;
  reg [1:0] inp_valid;
  reg [3:0] cmd;
  reg [in_a - 1 : 0] opa;
  reg [in_b - 1 : 0] opb;
  reg [in_a - 1 : 0] opa_d;
  reg [in_b - 1 : 0] opb_d;
  
  //To block inputs when Mutiplying
  always @(negedge CLK or posedge RST) begin
    if(!RST && ce && mode) begin
      if(cmd == 4'd9 || cmd == 4'd10)
            busy <= ~busy;
          else
            busy <= 0;
    end
  end
  //ALU Logic
  always @(posedge CLK or posedge RST) begin
  
  // Active high reset condition
    if(RST) begin
      RES <= 0;
      OFLOW <= 1'b0;
      COUT <= 1'b0;
      G <= 1'b0;
      L <= 1'b0;
      E <= 1'b0;
      ERR <= 1'b0;  
      opa_d <= 0;
      opb_d <= 0;  
      opa <= 0;
      opb <= 0; 
      busy <= 0;
      cin <= 0;
      cmd <= 0;
    end
  //reset = 0
    else begin
      cmd <= CMD;
      inp_valid <= INP_VALID;
      mode <= MODE;
      ce <= CE;
      
  //To avoid any inputs during multiplication
      if(busy && (cmd == 4'd9 || cmd == 4'd10) && mode) begin
        opa <= opa;
        opb <= opb;
        cin <= cin;
      end
      
  //when it is not busy and cmd is multiplication
      else if(!busy && (cmd == 4'd9 || cmd == 4'd10) && mode)begin
        opa <= OPA;
        opb <= OPB;
        cin <= CIN;
      end
      
  //For other operations besides multiplication
      else begin
        opa <= OPA;
        opb <= OPB;
        cin <= CIN;
      end
      
  //If clock enable is 0 
      if(!ce) begin
        RES <= RES;
        OFLOW <= OFLOW;
        COUT <= COUT;
        G <= G;
        L <= L;
        E <= E;
        ERR <= ERR;
      end
   
  //If clock enable is 1
      else begin
        
       
  //Mode = 1 is arithmetic operations
        if(mode) begin
          RES <= 0;
          OFLOW <= 1'b0;
          COUT <= 1'b0;
          G <= 1'b0;
          L <= 1'b0;
          E <= 1'b0;
          ERR <= 1'b0;
          case(cmd)
          
  //add
            4'd0: begin
              if(inp_valid == 2'b11) begin
                {COUT, RES[in_a - 1 : 0]} <= opa + opb;
              end
              else
                ERR <= 1;
            end
            
  //sub
            4'd1: begin
              if(inp_valid == 2'b11) begin
               {OFLOW, RES[in_a - 1 : 0]} <= opa - opb;
                
              end
              else
                ERR <= 1;
            end
            
  //add with cin
            4'd2: begin
              if(inp_valid == 2'b11) begin
                {COUT, RES[in_a - 1 : 0]} <= opa + opb + cin;
              end
              else
                ERR <= 1;
            end
            
  //sub with cin
            4'd3: begin
              if(inp_valid == 2'b11) begin
                {OFLOW, RES[in_a - 1 : 0]} <= opa - opb - cin;
                
              end
              else
                ERR <= 1;
            end
            
  //increment A
            4'd4: begin
              if(inp_valid[0]) begin
                {COUT,RES[in_a - 1 : 0]} <= opa + 1;
              end
              else
                ERR <= 1;
            end
            
  //decrement A
            4'd5: begin
              if(inp_valid[0])
                {OFLOW, RES[in_a - 1 : 0]} <= opa - 1;
              else
                ERR <= 1;
            end
            
  //Increment A
            4'd6: begin
              if(inp_valid[1])
                {COUT, RES[in_b - 1 : 0]} <= opb + 1;
              else
                ERR <= 1;
            end
            
  //Decrement B
            4'd7: begin
              if(inp_valid[1])
                {OFLOW, RES[in_b - 1 : 0]} <= opb - 1;
              else
                ERR <= 1;
            end
            
            
  //Compare
            4'd8: begin
            
              if(inp_valid == 2'b11) begin
              
                if(opa < opb) begin
                  L <= 1;
                  G <= 1'b0;
                  E <= 1'b0;
                end
                
                else if(opa > opb) begin
                  G <= 1;
                  L <= 1'b0;
                  E <= 1'b0;
                end
                
                else if(opa == opb) begin
                  G <= 1'b0;
                  L <= 1'b0;
                  E <= 1'b1;
                end
                
                else begin
                  G <= 1'b0;
                  L <= 1'b0;
                  E <= 1'b0;
                end
                
              end
              
            end
            
            
  //Increment a and b, and multiply
            4'd9: begin
           
              if(inp_valid == 2'b11) begin
                
                  opa_d <= opa + 1;
                  opb_d <= opb + 1;
                  RES <= opa_d * opb_d;
              end
              else
                ERR <= 1;
            end
            
  //Left shift a by once and multiply with b            
            4'd10: begin
              if(inp_valid == 2'b11) begin
                
                opa_d <= (opa << 1);
                RES <= opa_d * opb;   
                   
              end        
              else
                ERR <= 1;
            end
            
  //Signed Addition and compare
            4'd11: begin
              if(inp_valid == 2'b11) begin
                RES[in_a - 1 : 0] <= $signed(opa) + $signed(opb);
                if((opa[in_a - 1] && opb[in_b - 1] && ~RES[in_a -1]) || (RES[in_a -1] && ~opa[in_a - 1] && ~opb[in_b - 1]))
                  OFLOW <= 1;
                else
                  OFLOW <= 0;
                  
                if($signed(opa) > $signed(opb)) begin
                  G <= 1;
                  L <= 1'b0;
                  E <= 1'b0;
                end
                else if($signed(opa) < $signed(opb)) begin
                  G <= 1;
                  L <= 1'b0;
                  E <= 1'b0;
                end
                else if($signed(opa) == $signed(opb)) begin
                  G <= 1'b0;
                  L <= 1'b0;
                  E <= 1;
                end
                
                else begin
                  G <= 1'b0;
                  L <= 1'b0;
                  E <= 1'b0;
                end
              end
              else
                ERR <= 1;
            end
            
            
  //Signed Subtraction and compare
            4'd12: begin
              if(inp_valid == 2'b11) begin
                RES[in_a - 1 : 0] <= $signed(opa) - $signed(opb);
                if((opa[in_a - 1] && opb[in_b - 1] && ~RES[in_a -1]) || (RES[in_a -1] && ~opa[in_a - 1] && ~opb[in_b - 1])) begin
                  OFLOW <= 1;
                  
                end
                else
                  OFLOW <= 0;
                  
                if($signed(opa) > $signed(opb)) begin
                  G <= 1;
                  L <= 1'b0;
                  E <= 1'b0;
                end
                else if($signed(opa) < $signed(opb)) begin
                  G <= 1;
                  L <= 1'b0;
                  E <= 1'b0;
                end
                else if($signed(opa) == $signed(opb)) begin
                  G <= 1'b0;
                  L <= 1'b0;
                  E <= 1;
                end
                
                else begin
                  G <= 1'b0;
                  L <= 1'b0;
                  E <= 1'b0;
                end
              end
              else
                ERR <= 1;
            end
            default: begin
              RES <= 0;
              OFLOW <= 1'b0;
              COUT <= 1'b0;
              G <= 1'b0;
              L <= 1'b0;
              E <= 1'b0;
              ERR <= 1'b1;
            end
          endcase
        end
        
  //mode = 0 Logical Operations
        else begin
          RES <= 0;
          OFLOW <= 1'b0;
          COUT <= 1'b0;
          G <= 1'b0;
          L <= 1'b0;
          E <= 1'b0;
          ERR <= 1'b0;
          
          
          
          case(cmd)
          
  //AND
            4'd0: begin
              if(inp_valid == 2'b11)
                RES <= opa & opb;
              else
                ERR <= 1;
            end
            
  //NAND
            4'd1: begin
              if(inp_valid == 2'b11)
                RES <= ~(opa & opb);
              else
                ERR <= 1;
            end
            
  //OR
            4'd2: begin
              if(inp_valid == 2'b11)
                RES <= opa | opb;
              else
                ERR <= 1;
            end
            
  //NOR
            4'd3: begin
              if(inp_valid == 2'b11)
                RES <= ~(opa | opb);
              else
                ERR <= 1;
            end
            
  //XOR
            4'd4: begin
              if(inp_valid == 2'b11)
                RES <= opa ^ opb;
              else
                ERR <= 1;
            end
            
  //XNOR
            4'd5: begin
              if(inp_valid == 2'b11)
                RES <= opa ~^ opb;
              else
                ERR <= 1;
            end
            
  //Complement A
            4'd6: begin
              if(inp_valid[0])
                RES <= !opa;
              else
                ERR <= 1;
            end
            
  //Complement B
            4'd7: begin
              if(inp_valid[1])
                RES <= !opb;
              else
                ERR <= 1;
            end
            
  //SHIFT_Right_1_A
            4'd8: begin
              if(inp_valid[0])
                RES <= (opa >> 1) & {in_a{1'b1}};
              else
                ERR <= 1;
            end
            
  //SHIFT_Left_1_A
            4'd9: begin
              if(inp_valid[0])
                RES <= (opa << 1) & ({in_a{1'b1}});
              else
                ERR <= 1;
            end
            
  //SHIFT_Right_1_B
            4'd10: begin
              if(inp_valid[1])
                RES <= (opb >> 1) & ({in_b{1'b1}});
              else
                ERR <= 1;
            end
            
  //SHIFT_Left_1_B
            4'd11: begin
              if(inp_valid[1])
                RES <= {opb << 1} & ({in_b{1'b1}});
              else
                ERR <= 1;
            end
                      
  //ROL
            4'd12: begin
              if(inp_valid == 2'b11) begin
                if(opb[7] || opb[6] || opb[5] || opb[4])
                  ERR <= 1;
                else begin
                  casex(opb)
                    4'b?000: RES <= opa;
                    4'b?001: RES <= {opa[6:0], opa[7]};
                    4'b?010: RES <= {opa[5:0], opa[7:6]};
                    4'b?011: RES <= {opa[4:0], opa[7:5]};
                    4'b?100: RES <= {opa[3:0], opa[7:4]};
                    4'b?101: RES <= {opa[2:0], opa[7:3]};
                    4'b?110: RES <= {opa[1:0], opa[7:2]};
                    4'b?111: RES <= {opa[0], opa[7:1]};
                    default: ERR <= 1;
                  endcase
                end
              end
              else
                ERR <= 1;
            end
            
  //ROR
            4'd13: begin
              if(inp_valid == 2'b11) begin
                if(opb[7] || opb[6] || opb[5] || opb[4])
                  ERR <= 1;
                else begin
                  casex(opb)
                    4'b?000: RES <= opa;
                    4'b?001: RES <= {opa[0], opa[7:1]};
                    4'b?010: RES <= {opa[1:0], opa[7:2]};
                    4'b?011: RES <= {opa[2:0], opa[7:3]};
                    4'b?100: RES <= {opa[3:0], opa[7:4]};
                    4'b?101: RES <= {opa[4:0], opa[7:5]};
                    4'b?110: RES <= {opa[5:0], opa[7:6]};
                    4'b?111: RES <= {opa[6:0], opa[7]};
                  
                    default: ERR <= 1;
                  endcase
                end
              end
              else
                ERR <= 1;
            end
            
  //Default if commands exceed 13
            default: begin
              RES <= 0;
              OFLOW <= 1'b0;
              COUT <= 1'b0;
              G <= 1'b0;
              L <= 1'b0;
              E <= 1'b0;
              ERR <= 1'b1;
            end
          endcase
        end
      end
    end
  end
endmodule
