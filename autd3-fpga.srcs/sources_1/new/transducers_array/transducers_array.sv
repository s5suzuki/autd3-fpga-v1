/*
 * File: transducers_array.sv
 * Project: transducers_array
 * Created Date: 15/12/2020
 * Author: Shun Suzuki
 * -----
 * Last Modified: 15/12/2020
 * Modified By: Shun Suzuki (suzuki@hapis.k.u-tokyo.ac.jp)
 * -----
 * Copyright (c) 2020 Hapis Lab. All rights reserved.
 * 
 */

`timescale 1ns / 1ps
`include "../consts.vh"

module transducers_array(
           input var [9:0] TIME,
           input var [7:0] AMP[0:`TRANS_NUM-1],
           input var [7:0] PHASE[0:`TRANS_NUM-1],
           input var [7:0] MOD,
           input var SILENT,
           output var [252:1] XDCR_OUT
       );

generate begin:TRANSDUCERS_GEN
        genvar ii;
        for(ii = 0; ii < `TRANS_NUM; ii++) begin
            logic [7:0] amp_modulated = modulate_amp(AMP[ii], MOD);
            transducer tr(
                           .TIME(TIME),
                           .D(amp_modulated),
                           .PHASE(PHASE[ii]),
                           .SILENT(SILENT),
                           .PWM_OUT(XDCR_OUT[cvt_uid(ii) + 1])
                       );
        end
    end
endgenerate

function automatic [7:0] modulate_amp;
    input [7:0] amp;
    input [7:0] mod;
    modulate_amp = ((amp + 17'd1) * (mod + 17'd1) - 17'd1) >> 8;
endfunction

function automatic [7:0] cvt_uid (input [7:0] idx);
    case (idx)
        8'd0:
            cvt_uid = 8'd0;
        8'd1:
            cvt_uid = 8'd1;
        8'd2:
            cvt_uid = 8'd2;
        8'd3:
            cvt_uid = 8'd3;
        8'd4:
            cvt_uid = 8'd4;
        8'd5:
            cvt_uid = 8'd5;
        8'd6:
            cvt_uid = 8'd6;
        8'd7:
            cvt_uid = 8'd7;
        8'd8:
            cvt_uid = 8'd8;
        8'd9:
            cvt_uid = 8'd9;
        8'd10:
            cvt_uid = 8'd10;
        8'd11:
            cvt_uid = 8'd11;
        8'd12:
            cvt_uid = 8'd12;
        8'd13:
            cvt_uid = 8'd13;
        8'd14:
            cvt_uid = 8'd14;
        8'd15:
            cvt_uid = 8'd15;
        8'd16:
            cvt_uid = 8'd16;
        8'd17:
            cvt_uid = 8'd17;
        8'd18:
            cvt_uid = 8'd18;
        8'd19:
            cvt_uid = 8'd21;
        8'd20:
            cvt_uid = 8'd22;
        8'd21:
            cvt_uid = 8'd23;
        8'd22:
            cvt_uid = 8'd24;
        8'd23:
            cvt_uid = 8'd25;
        8'd24:
            cvt_uid = 8'd26;
        8'd25:
            cvt_uid = 8'd27;
        8'd26:
            cvt_uid = 8'd28;
        8'd27:
            cvt_uid = 8'd29;
        8'd28:
            cvt_uid = 8'd30;
        8'd29:
            cvt_uid = 8'd31;
        8'd30:
            cvt_uid = 8'd32;
        8'd31:
            cvt_uid = 8'd33;
        8'd32:
            cvt_uid = 8'd35;
        8'd33:
            cvt_uid = 8'd36;
        8'd34:
            cvt_uid = 8'd37;
        8'd35:
            cvt_uid = 8'd38;
        8'd36:
            cvt_uid = 8'd39;
        8'd37:
            cvt_uid = 8'd40;
        8'd38:
            cvt_uid = 8'd41;
        8'd39:
            cvt_uid = 8'd42;
        8'd40:
            cvt_uid = 8'd43;
        8'd41:
            cvt_uid = 8'd44;
        8'd42:
            cvt_uid = 8'd45;
        8'd43:
            cvt_uid = 8'd46;
        8'd44:
            cvt_uid = 8'd47;
        8'd45:
            cvt_uid = 8'd48;
        8'd46:
            cvt_uid = 8'd49;
        8'd47:
            cvt_uid = 8'd50;
        8'd48:
            cvt_uid = 8'd51;
        8'd49:
            cvt_uid = 8'd52;
        8'd50:
            cvt_uid = 8'd53;
        8'd51:
            cvt_uid = 8'd54;
        8'd52:
            cvt_uid = 8'd55;
        8'd53:
            cvt_uid = 8'd56;
        8'd54:
            cvt_uid = 8'd57;
        8'd55:
            cvt_uid = 8'd58;
        8'd56:
            cvt_uid = 8'd59;
        8'd57:
            cvt_uid = 8'd60;
        8'd58:
            cvt_uid = 8'd61;
        8'd59:
            cvt_uid = 8'd62;
        8'd60:
            cvt_uid = 8'd63;
        8'd61:
            cvt_uid = 8'd64;
        8'd62:
            cvt_uid = 8'd65;
        8'd63:
            cvt_uid = 8'd66;
        8'd64:
            cvt_uid = 8'd67;
        8'd65:
            cvt_uid = 8'd68;
        8'd66:
            cvt_uid = 8'd69;
        8'd67:
            cvt_uid = 8'd70;
        8'd68:
            cvt_uid = 8'd71;
        8'd69:
            cvt_uid = 8'd72;
        8'd70:
            cvt_uid = 8'd73;
        8'd71:
            cvt_uid = 8'd74;
        8'd72:
            cvt_uid = 8'd75;
        8'd73:
            cvt_uid = 8'd76;
        8'd74:
            cvt_uid = 8'd77;
        8'd75:
            cvt_uid = 8'd78;
        8'd76:
            cvt_uid = 8'd79;
        8'd77:
            cvt_uid = 8'd80;
        8'd78:
            cvt_uid = 8'd81;
        8'd79:
            cvt_uid = 8'd82;
        8'd80:
            cvt_uid = 8'd83;
        8'd81:
            cvt_uid = 8'd84;
        8'd82:
            cvt_uid = 8'd85;
        8'd83:
            cvt_uid = 8'd86;
        8'd84:
            cvt_uid = 8'd87;
        8'd85:
            cvt_uid = 8'd88;
        8'd86:
            cvt_uid = 8'd89;
        8'd87:
            cvt_uid = 8'd90;
        8'd88:
            cvt_uid = 8'd91;
        8'd89:
            cvt_uid = 8'd92;
        8'd90:
            cvt_uid = 8'd93;
        8'd91:
            cvt_uid = 8'd94;
        8'd92:
            cvt_uid = 8'd95;
        8'd93:
            cvt_uid = 8'd96;
        8'd94:
            cvt_uid = 8'd97;
        8'd95:
            cvt_uid = 8'd98;
        8'd96:
            cvt_uid = 8'd99;
        8'd97:
            cvt_uid = 8'd100;
        8'd98:
            cvt_uid = 8'd101;
        8'd99:
            cvt_uid = 8'd102;
        8'd100:
            cvt_uid = 8'd103;
        8'd101:
            cvt_uid = 8'd104;
        8'd102:
            cvt_uid = 8'd105;
        8'd103:
            cvt_uid = 8'd106;
        8'd104:
            cvt_uid = 8'd107;
        8'd105:
            cvt_uid = 8'd108;
        8'd106:
            cvt_uid = 8'd109;
        8'd107:
            cvt_uid = 8'd110;
        8'd108:
            cvt_uid = 8'd111;
        8'd109:
            cvt_uid = 8'd112;
        8'd110:
            cvt_uid = 8'd113;
        8'd111:
            cvt_uid = 8'd114;
        8'd112:
            cvt_uid = 8'd115;
        8'd113:
            cvt_uid = 8'd116;
        8'd114:
            cvt_uid = 8'd117;
        8'd115:
            cvt_uid = 8'd118;
        8'd116:
            cvt_uid = 8'd119;
        8'd117:
            cvt_uid = 8'd120;
        8'd118:
            cvt_uid = 8'd121;
        8'd119:
            cvt_uid = 8'd122;
        8'd120:
            cvt_uid = 8'd123;
        8'd121:
            cvt_uid = 8'd124;
        8'd122:
            cvt_uid = 8'd125;
        8'd123:
            cvt_uid = 8'd126;
        8'd124:
            cvt_uid = 8'd127;
        8'd125:
            cvt_uid = 8'd128;
        8'd126:
            cvt_uid = 8'd129;
        8'd127:
            cvt_uid = 8'd130;
        8'd128:
            cvt_uid = 8'd131;
        8'd129:
            cvt_uid = 8'd132;
        8'd130:
            cvt_uid = 8'd133;
        8'd131:
            cvt_uid = 8'd134;
        8'd132:
            cvt_uid = 8'd135;
        8'd133:
            cvt_uid = 8'd136;
        8'd134:
            cvt_uid = 8'd137;
        8'd135:
            cvt_uid = 8'd138;
        8'd136:
            cvt_uid = 8'd139;
        8'd137:
            cvt_uid = 8'd140;
        8'd138:
            cvt_uid = 8'd141;
        8'd139:
            cvt_uid = 8'd142;
        8'd140:
            cvt_uid = 8'd143;
        8'd141:
            cvt_uid = 8'd144;
        8'd142:
            cvt_uid = 8'd145;
        8'd143:
            cvt_uid = 8'd146;
        8'd144:
            cvt_uid = 8'd147;
        8'd145:
            cvt_uid = 8'd148;
        8'd146:
            cvt_uid = 8'd149;
        8'd147:
            cvt_uid = 8'd150;
        8'd148:
            cvt_uid = 8'd151;
        8'd149:
            cvt_uid = 8'd152;
        8'd150:
            cvt_uid = 8'd153;
        8'd151:
            cvt_uid = 8'd154;
        8'd152:
            cvt_uid = 8'd155;
        8'd153:
            cvt_uid = 8'd156;
        8'd154:
            cvt_uid = 8'd157;
        8'd155:
            cvt_uid = 8'd158;
        8'd156:
            cvt_uid = 8'd159;
        8'd157:
            cvt_uid = 8'd160;
        8'd158:
            cvt_uid = 8'd161;
        8'd159:
            cvt_uid = 8'd162;
        8'd160:
            cvt_uid = 8'd163;
        8'd161:
            cvt_uid = 8'd164;
        8'd162:
            cvt_uid = 8'd165;
        8'd163:
            cvt_uid = 8'd166;
        8'd164:
            cvt_uid = 8'd167;
        8'd165:
            cvt_uid = 8'd168;
        8'd166:
            cvt_uid = 8'd169;
        8'd167:
            cvt_uid = 8'd170;
        8'd168:
            cvt_uid = 8'd171;
        8'd169:
            cvt_uid = 8'd172;
        8'd170:
            cvt_uid = 8'd173;
        8'd171:
            cvt_uid = 8'd174;
        8'd172:
            cvt_uid = 8'd175;
        8'd173:
            cvt_uid = 8'd176;
        8'd174:
            cvt_uid = 8'd177;
        8'd175:
            cvt_uid = 8'd178;
        8'd176:
            cvt_uid = 8'd179;
        8'd177:
            cvt_uid = 8'd180;
        8'd178:
            cvt_uid = 8'd181;
        8'd179:
            cvt_uid = 8'd182;
        8'd180:
            cvt_uid = 8'd183;
        8'd181:
            cvt_uid = 8'd184;
        8'd182:
            cvt_uid = 8'd185;
        8'd183:
            cvt_uid = 8'd186;
        8'd184:
            cvt_uid = 8'd187;
        8'd185:
            cvt_uid = 8'd188;
        8'd186:
            cvt_uid = 8'd189;
        8'd187:
            cvt_uid = 8'd190;
        8'd188:
            cvt_uid = 8'd191;
        8'd189:
            cvt_uid = 8'd192;
        8'd190:
            cvt_uid = 8'd193;
        8'd191:
            cvt_uid = 8'd194;
        8'd192:
            cvt_uid = 8'd195;
        8'd193:
            cvt_uid = 8'd196;
        8'd194:
            cvt_uid = 8'd197;
        8'd195:
            cvt_uid = 8'd198;
        8'd196:
            cvt_uid = 8'd199;
        8'd197:
            cvt_uid = 8'd200;
        8'd198:
            cvt_uid = 8'd201;
        8'd199:
            cvt_uid = 8'd202;
        8'd200:
            cvt_uid = 8'd203;
        8'd201:
            cvt_uid = 8'd204;
        8'd202:
            cvt_uid = 8'd205;
        8'd203:
            cvt_uid = 8'd206;
        8'd204:
            cvt_uid = 8'd207;
        8'd205:
            cvt_uid = 8'd208;
        8'd206:
            cvt_uid = 8'd209;
        8'd207:
            cvt_uid = 8'd210;
        8'd208:
            cvt_uid = 8'd211;
        8'd209:
            cvt_uid = 8'd212;
        8'd210:
            cvt_uid = 8'd213;
        8'd211:
            cvt_uid = 8'd214;
        8'd212:
            cvt_uid = 8'd215;
        8'd213:
            cvt_uid = 8'd216;
        8'd214:
            cvt_uid = 8'd217;
        8'd215:
            cvt_uid = 8'd218;
        8'd216:
            cvt_uid = 8'd219;
        8'd217:
            cvt_uid = 8'd220;
        8'd218:
            cvt_uid = 8'd221;
        8'd219:
            cvt_uid = 8'd222;
        8'd220:
            cvt_uid = 8'd223;
        8'd221:
            cvt_uid = 8'd224;
        8'd222:
            cvt_uid = 8'd225;
        8'd223:
            cvt_uid = 8'd226;
        8'd224:
            cvt_uid = 8'd227;
        8'd225:
            cvt_uid = 8'd228;
        8'd226:
            cvt_uid = 8'd229;
        8'd227:
            cvt_uid = 8'd230;
        8'd228:
            cvt_uid = 8'd231;
        8'd229:
            cvt_uid = 8'd232;
        8'd230:
            cvt_uid = 8'd233;
        8'd231:
            cvt_uid = 8'd234;
        8'd232:
            cvt_uid = 8'd235;
        8'd233:
            cvt_uid = 8'd236;
        8'd234:
            cvt_uid = 8'd237;
        8'd235:
            cvt_uid = 8'd238;
        8'd236:
            cvt_uid = 8'd239;
        8'd237:
            cvt_uid = 8'd240;
        8'd238:
            cvt_uid = 8'd241;
        8'd239:
            cvt_uid = 8'd242;
        8'd240:
            cvt_uid = 8'd243;
        8'd241:
            cvt_uid = 8'd244;
        8'd242:
            cvt_uid = 8'd245;
        8'd243:
            cvt_uid = 8'd246;
        8'd244:
            cvt_uid = 8'd247;
        8'd245:
            cvt_uid = 8'd248;
        8'd246:
            cvt_uid = 8'd249;
        8'd247:
            cvt_uid = 8'd250;
        8'd248:
            cvt_uid = 8'd251;
        default:
            cvt_uid = 8'd0;
    endcase
endfunction

endmodule
