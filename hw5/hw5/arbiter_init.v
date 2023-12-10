/////////////////////////////////////////////////////////////
// Created by: Synopsys DC Ultra(TM) in wire load mode
// Version   : S-2021.06-SP3
// Date      : Tue Oct 10 13:14:17 2023
/////////////////////////////////////////////////////////////


module arbiter ( clock, reset, R0, R1, G0, G1 );
  input clock, reset, R0, R1;
  output G0, G1;
  wire   n16, n17, n18, n19, n20, n21, n22, n23, n24, n25, n26, n27, n28, n29,
         n30, n31, n32, n33;
  wire   [4:0] current_state;
  wire   [4:0] next_state;

  DFFR_X1 \current_state_reg[4]  ( .D(next_state[4]), .CK(clock), .RN(reset), 
        .Q(current_state[4]) );
  DFFR_X1 \current_state_reg[2]  ( .D(next_state[2]), .CK(clock), .RN(reset), 
        .Q(current_state[2]) );
  DFFR_X1 \current_state_reg[1]  ( .D(next_state[1]), .CK(clock), .RN(n17), 
        .Q(current_state[1]), .QN(n33) );
  DFFR_X1 \current_state_reg[3]  ( .D(next_state[3]), .CK(clock), .RN(n17), 
        .Q(current_state[3]), .QN(n31) );
  DFFS_X1 \current_state_reg[0]  ( .D(next_state[0]), .CK(clock), .SN(n17), 
        .Q(current_state[0]), .QN(n32) );
  INV_X1 U25 ( .A(reset), .ZN(n16) );
  INV_X1 U26 ( .A(n16), .ZN(n17) );
  AOI211_X2 U27 ( .C1(current_state[2]), .C2(current_state[4]), .A(
        current_state[0]), .B(n19), .ZN(G1) );
  AOI221_X2 U28 ( .B1(current_state[1]), .B2(current_state[3]), .C1(n33), .C2(
        n31), .A(n26), .ZN(G0) );
  NOR2_X1 U29 ( .A1(current_state[2]), .A2(current_state[4]), .ZN(n18) );
  NAND2_X1 U30 ( .A1(n18), .A2(n32), .ZN(n26) );
  NOR2_X1 U31 ( .A1(current_state[3]), .A2(current_state[1]), .ZN(n21) );
  OAI21_X1 U32 ( .B1(current_state[2]), .B2(current_state[4]), .A(n21), .ZN(
        n19) );
  NOR3_X1 U33 ( .A1(current_state[2]), .A2(current_state[4]), .A3(n32), .ZN(
        n20) );
  AOI21_X1 U34 ( .B1(n21), .B2(n20), .A(G1), .ZN(n24) );
  OR3_X1 U35 ( .A1(n33), .A2(n26), .A3(current_state[3]), .ZN(n22) );
  NAND2_X1 U36 ( .A1(n24), .A2(n22), .ZN(n27) );
  INV_X1 U37 ( .A(R0), .ZN(n23) );
  NAND2_X1 U38 ( .A1(n27), .A2(n23), .ZN(n28) );
  INV_X1 U39 ( .A(n24), .ZN(n25) );
  OAI22_X1 U40 ( .A1(R1), .A2(n28), .B1(G0), .B2(n25), .ZN(next_state[0]) );
  NOR3_X1 U41 ( .A1(current_state[1]), .A2(n31), .A3(n26), .ZN(next_state[4])
         );
  NAND2_X1 U42 ( .A1(R0), .A2(n27), .ZN(n29) );
  NOR2_X1 U43 ( .A1(R1), .A2(n29), .ZN(next_state[1]) );
  INV_X1 U44 ( .A(R1), .ZN(n30) );
  NOR2_X1 U45 ( .A1(n30), .A2(n28), .ZN(next_state[2]) );
  NOR2_X1 U46 ( .A1(n30), .A2(n29), .ZN(next_state[3]) );
endmodule

