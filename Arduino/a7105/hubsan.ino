/*
 This project is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 Deviation is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with Deviation.  If not, see <http://www.gnu.org/licenses/>.
 */

//#include "interface.h"
//#include "mixer.h"
//#include "config/model.h"
//#include <string.h>
//#include <stdlib.h>
#include <Arduino.h>
//#include "config.h"
#include "a7105.h"

volatile s16 Channels[NUM_OUT_CHANNELS];

u8 packet[16];
u8 channel;
const u8 allowed_ch[] = {0x14, 0x1e, 0x28, 0x32, 0x3c, 0x46, 0x50, 0x5a, 0x64, 0x6e, 0x78, 0x82};
unsigned long sessionid;
const unsigned long txid = 0xdb042679;
u8 state;

enum {
    BIND_1,
    BIND_2,
    BIND_3,
    BIND_4,
    BIND_5,
    BIND_6,
    BIND_7,
    BIND_8,
    DATA_1,
    DATA_2,
    DATA_3,
    DATA_4,
    DATA_5,
};
#define WAIT_WRITE 0x80

int hubsan_init()
{
    u8 if_calibration1;
    u8 vco_calibration0;
    u8 vco_calibration1;
    //u8 vco_current;

    A7105_WriteID(0x55201041);
    A7105_WriteReg(A7105_01_MODE_CONTROL, 0x63);
    A7105_WriteReg(A7105_03_FIFOI, 0x0f);
    A7105_WriteReg(A7105_0D_CLOCK, 0x05);
    A7105_WriteReg(A7105_0E_DATA_RATE, 0x04);
    A7105_WriteReg(A7105_15_TX_II, 0x2b);
    A7105_WriteReg(A7105_18_RX, 0x62);
    A7105_WriteReg(A7105_19_RX_GAIN_I, 0x80);
    A7105_WriteReg(A7105_1C_RX_GAIN_IV, 0x0A);
    A7105_WriteReg(A7105_1F_CODE_I, 0x07);
    A7105_WriteReg(A7105_20_CODE_II, 0x17);
    A7105_WriteReg(A7105_29_RX_DEM_TEST_I, 0x47);

    A7105_Strobe(A7105_STANDBY);

    //IF Filter Bank Calibration
    A7105_WriteReg(0x02, 1);
    //vco_current =
    A7105_ReadReg(0x02);
    unsigned long ms = millis();

    while(millis()  - ms < 500) {
        if(! A7105_ReadReg(0x02))
            break;
    }
    if (millis() - ms >= 500)
        return 0;
    if_calibration1 = A7105_ReadReg(A7105_22_IF_CALIB_I);
    A7105_ReadReg(A7105_24_VCO_CURCAL);
    if(if_calibration1 & A7105_MASK_FBCF) {
        //Calibration failed...what do we do?
        return 0;
    }

    //VCO Current Calibration
    //A7105_WriteReg(0x24, 0x13); //Recomended calibration from A7105 Datasheet

    //VCO Bank Calibration
    //A7105_WriteReg(0x26, 0x3b); //Recomended limits from A7105 Datasheet

    //VCO Bank Calibrate channel 0?
    //Set Channel
    A7105_WriteReg(A7105_0F_CHANNEL, 0);
    //VCO Calibration
    A7105_WriteReg(0x02, 2);
    ms = millis();
    while(millis()  - ms < 500) {
        if(! A7105_ReadReg(0x02))
            break;
    }
    if (millis() - ms >= 500)
        return 0;
    vco_calibration0 = A7105_ReadReg(A7105_25_VCO_SBCAL_I);
    if (vco_calibration0 & A7105_MASK_VBCF) {
        //Calibration failed...what do we do?
        return 0;
    }

    //Calibrate channel 0xa0?
    //Set Channel
    A7105_WriteReg(A7105_0F_CHANNEL, 0xa0);
    //VCO Calibration
    A7105_WriteReg(A7105_02_CALC, 2);
    ms = millis();
    while(millis()  - ms < 500) {
        if(! A7105_ReadReg(A7105_02_CALC))
            break;
    }
    if (millis() - ms >= 500)
        return 0;
    vco_calibration1 = A7105_ReadReg(A7105_25_VCO_SBCAL_I);
    if (vco_calibration1 & A7105_MASK_VBCF) {
        //Calibration failed...what do we do?
    }

    //Reset VCO Band calibration
    //A7105_WriteReg(0x25, 0x08);

    A7105_SetPower(TXPOWER_150mW);

    A7105_Strobe(A7105_STANDBY);
    return 1;
}

static void update_crc()
{
    int sum = 0;
    for(int i = 0; i < 15; i++)
        sum += packet[i];
    packet[15] = (256 - (sum % 256)) & 0xff;
}
static void hubsan_build_bind_packet(u8 state)
{
    packet[0] = state;
    packet[1] = channel;
    packet[2] = (sessionid >> 24) & 0xff;
    packet[3] = (sessionid >> 16) & 0xff;
    packet[4] = (sessionid >>  8) & 0xff;
    packet[5] = (sessionid >>  0) & 0xff;
    packet[6] = 0x08;
    packet[7] = 0xe4; //???
    packet[8] = 0xea;
    packet[9] = 0x9e;
    packet[10] = 0x50;
    packet[11] = (txid >> 24) & 0xff;
    packet[12] = (txid >> 16) & 0xff;
    packet[13] = (txid >>  8) & 0xff;
    packet[14] = (txid >>  0) & 0xff;
    update_crc();
}

s16 get_channel(u8 ch, s32 scale, s32 center, s32 range)
{
  static int a=0;
  if (a++<2550) return 0;
  
//  return 254;
  return 128;
  s32 value = (s32)Channels[ch] * scale / CHAN_MAX_VALUE + center;
    if (value < center - range)
        value = center - range;
    if (value >= center + range)
        value = center + range -1;
    return value;
}


volatile uint8_t throttle=0, rudder=0, aileron = 0, elevator = 0;

static void hubsan_build_packet()
{
    memset(packet, 0, 16);
    //20 00 00 00 80 00 7d 00 84 02 64 db 04 26 79 7b
    packet[0] = 0x20;
    packet[2] = throttle;//get_channel(2, 0x80, 0x80, 0x80);
    packet[4] = 0xff - rudder; // get_channel(3, 0x80, 0x80, 0x80); //Rudder is reversed
    packet[6] = 0xff - elevator; // get_channel(1, 0x80, 0x80, 0x80); //Elevator is reversed
    packet[8] = aileron; // get_channel(0, 0x80, 0x80, 0x80);
    packet[9] = 0x02;
    packet[10] = 0x64;
    packet[11] = (txid >> 24) & 0xff;
    packet[12] = (txid >> 16) & 0xff;
    packet[13] = (txid >>  8) & 0xff;
    packet[14] = (txid >>  0) & 0xff;
    update_crc();
}

static u16 hubsan_cb()
{
    int i;
    switch(state) {
    case BIND_1:
    case BIND_3:
    case BIND_5:
    case BIND_7:
        hubsan_build_bind_packet(state == BIND_7 ? 9 : (state == BIND_5 ? 1 : state + 1 - BIND_1));
        A7105_Strobe(A7105_STANDBY);
        A7105_WriteData(packet, 16, channel);
        state |= WAIT_WRITE;
        return 3000;
    case BIND_1 | WAIT_WRITE:
    case BIND_3 | WAIT_WRITE:
    case BIND_5 | WAIT_WRITE:
    case BIND_7 | WAIT_WRITE:
        //wait for completion
        for(i = 0; i< 20; i++) {
          if(! (A7105_ReadReg(A7105_00_MODE) & 0x01))
            break;
        }
        if (i == 20)
            Serial.println("Failed to complete write\n");
       // else 
       //     Serial.println("Completed write\n");
        A7105_Strobe(A7105_RX);
        state &= ~WAIT_WRITE;
        state++;
        return 4500; //7.5msec elapsed since last write
    case BIND_2:
    case BIND_4:
    case BIND_6:
        if(A7105_ReadReg(A7105_00_MODE) & 0x01) {
            state = BIND_1; //Serial.println("Restart");
            return 4500; //No signal, restart binding procedure.  12msec elapsed since last write
        } 

       A7105_ReadData(packet, 16);
        state++;
        if (state == BIND_5)
            A7105_WriteID((packet[2] << 24) | (packet[3] << 16) | (packet[4] << 8) | packet[5]);
        
        return 500;  //8msec elapsed time since last write;
    case BIND_8:
        if(A7105_ReadReg(A7105_00_MODE) & 0x01) {
            state = BIND_7;
            return 15000; //22.5msec elapsed since last write
        }
        A7105_ReadData(packet, 16);
        if(packet[1] == 9) {
            state = DATA_1;
            A7105_WriteReg(A7105_1F_CODE_I, 0x0F);
            PROTOCOL_SetBindState(0);
            return 28000; //35.5msec elapsed since last write
        } else {
            state = BIND_7;
            return 15000; //22.5 msec elapsed since last write
        }
    case DATA_1:
        //Keep transmit power in sync
        A7105_SetPower(TXPOWER_150mW);
    case DATA_2:
    case DATA_3:
    case DATA_4:
    case DATA_5:
        hubsan_build_packet();
        A7105_WriteData(packet, 16, state == DATA_5 ? channel + 0x23 : channel);
        if (state == DATA_5)
            state = DATA_1;
        else
            state++;
        return 10000;
    }
    return 0;
}

static void initialize() {
    while(1) {
        A7105_Reset();
        if (hubsan_init())
            break;
    }
    sessionid = rand();
    channel = allowed_ch[rand() % sizeof(allowed_ch)];
    state = BIND_1;
}


void setup() { }


