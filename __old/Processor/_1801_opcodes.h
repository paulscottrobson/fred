case 0x00: // *** idl ***
    ;;break;
case 0x10: // *** inc r0 ***
    R[0]++;break;
case 0x11: // *** inc r1 ***
    R[1]++;break;
case 0x12: // *** inc r2 ***
    R[2]++;break;
case 0x13: // *** inc r3 ***
    R[3]++;break;
case 0x14: // *** inc r4 ***
    R[4]++;break;
case 0x15: // *** inc r5 ***
    R[5]++;break;
case 0x16: // *** inc r6 ***
    R[6]++;break;
case 0x17: // *** inc r7 ***
    R[7]++;break;
case 0x18: // *** inc r8 ***
    R[8]++;break;
case 0x19: // *** inc r9 ***
    R[9]++;break;
case 0x1a: // *** inc ra ***
    R[10]++;break;
case 0x1b: // *** inc rb ***
    R[11]++;break;
case 0x1c: // *** inc rc ***
    R[12]++;break;
case 0x1d: // *** inc rd ***
    R[13]++;break;
case 0x1e: // *** inc re ***
    R[14]++;break;
case 0x1f: // *** inc rf ***
    R[15]++;break;
case 0x20: // *** dec r0 ***
    R[0]--;break;
case 0x21: // *** dec r1 ***
    R[1]--;break;
case 0x22: // *** dec r2 ***
    R[2]--;break;
case 0x23: // *** dec r3 ***
    R[3]--;break;
case 0x24: // *** dec r4 ***
    R[4]--;break;
case 0x25: // *** dec r5 ***
    R[5]--;break;
case 0x26: // *** dec r6 ***
    R[6]--;break;
case 0x27: // *** dec r7 ***
    R[7]--;break;
case 0x28: // *** dec r8 ***
    R[8]--;break;
case 0x29: // *** dec r9 ***
    R[9]--;break;
case 0x2a: // *** dec ra ***
    R[10]--;break;
case 0x2b: // *** dec rb ***
    R[11]--;break;
case 0x2c: // *** dec rc ***
    R[12]--;break;
case 0x2d: // *** dec rd ***
    R[13]--;break;
case 0x2e: // *** dec re ***
    R[14]--;break;
case 0x2f: // *** dec rf ***
    R[15]--;break;
case 0x30: // *** br .1 ***
    temp8 = FETCH();R[P] = (R[P] & 0xFF00) | temp8;break;
case 0x32: // *** bz .1 ***
    temp8 = FETCH();BRANCH(D == 0);break;
case 0x33: // *** bdf .1 ***
    temp8 = FETCH();BRANCH(DF != 0);break;
case 0x34: // *** b1 .1 ***
    temp8 = FETCH();BRANCH(EFLAG1() != 0);break;
case 0x35: // *** b2 .1 ***
    temp8 = FETCH();BRANCH(EFLAG2() != 0);break;
case 0x36: // *** b3 .1 ***
    temp8 = FETCH();BRANCH(EFLAG3() != 0);break;
case 0x37: // *** b4 .1 ***
    temp8 = FETCH();BRANCH(EFLAG4() != 0);break;
case 0x38: // *** skp ***
    R[P]++;break;
case 0x3a: // *** bnz .1 ***
    temp8 = FETCH();BRANCH(D != 0);break;
case 0x3b: // *** bnf .1 ***
    temp8 = FETCH();BRANCH(DF == 0);break;
case 0x3c: // *** bn1 .1 ***
    temp8 = FETCH();BRANCH(EFLAG1() == 0);break;
case 0x3d: // *** bn2 .1 ***
    temp8 = FETCH();BRANCH(EFLAG2() == 0);break;
case 0x3e: // *** bn3 .1 ***
    temp8 = FETCH();BRANCH(EFLAG3() == 0);break;
case 0x3f: // *** bn4 .1 ***
    temp8 = FETCH();BRANCH(EFLAG4() == 0);break;
case 0x40: // *** lda r0 ***
    D = READ(R[0]);R[0]++;break;
case 0x41: // *** lda r1 ***
    D = READ(R[1]);R[1]++;break;
case 0x42: // *** lda r2 ***
    D = READ(R[2]);R[2]++;break;
case 0x43: // *** lda r3 ***
    D = READ(R[3]);R[3]++;break;
case 0x44: // *** lda r4 ***
    D = READ(R[4]);R[4]++;break;
case 0x45: // *** lda r5 ***
    D = READ(R[5]);R[5]++;break;
case 0x46: // *** lda r6 ***
    D = READ(R[6]);R[6]++;break;
case 0x47: // *** lda r7 ***
    D = READ(R[7]);R[7]++;break;
case 0x48: // *** lda r8 ***
    D = READ(R[8]);R[8]++;break;
case 0x49: // *** lda r9 ***
    D = READ(R[9]);R[9]++;break;
case 0x4a: // *** lda ra ***
    D = READ(R[10]);R[10]++;break;
case 0x4b: // *** lda rb ***
    D = READ(R[11]);R[11]++;break;
case 0x4c: // *** lda rc ***
    D = READ(R[12]);R[12]++;break;
case 0x4d: // *** lda rd ***
    D = READ(R[13]);R[13]++;break;
case 0x4e: // *** lda re ***
    D = READ(R[14]);R[14]++;break;
case 0x4f: // *** lda rf ***
    D = READ(R[15]);R[15]++;break;
case 0x50: // *** str r0 ***
    WRITE(R[0],D);break;
case 0x51: // *** str r1 ***
    WRITE(R[1],D);break;
case 0x52: // *** str r2 ***
    WRITE(R[2],D);break;
case 0x53: // *** str r3 ***
    WRITE(R[3],D);break;
case 0x54: // *** str r4 ***
    WRITE(R[4],D);break;
case 0x55: // *** str r5 ***
    WRITE(R[5],D);break;
case 0x56: // *** str r6 ***
    WRITE(R[6],D);break;
case 0x57: // *** str r7 ***
    WRITE(R[7],D);break;
case 0x58: // *** str r8 ***
    WRITE(R[8],D);break;
case 0x59: // *** str r9 ***
    WRITE(R[9],D);break;
case 0x5a: // *** str ra ***
    WRITE(R[10],D);break;
case 0x5b: // *** str rb ***
    WRITE(R[11],D);break;
case 0x5c: // *** str rc ***
    WRITE(R[12],D);break;
case 0x5d: // *** str rd ***
    WRITE(R[13],D);break;
case 0x5e: // *** str re ***
    WRITE(R[14],D);break;
case 0x5f: // *** str rf ***
    WRITE(R[15],D);break;
case 0x60: // *** out 0 ***
    OUTPORT0(READ(R[X]));R[X]++;break;
case 0x61: // *** out 1 ***
    OUTPORT1(READ(R[X]));R[X]++;break;
case 0x62: // *** out 2 ***
    OUTPORT2(READ(R[X]));R[X]++;break;
case 0x63: // *** out 3 ***
    OUTPORT3(READ(R[X]));R[X]++;break;
case 0x64: // *** out 4 ***
    OUTPORT4(READ(R[X]));R[X]++;break;
case 0x65: // *** out 5 ***
    OUTPORT5(READ(R[X]));R[X]++;break;
case 0x66: // *** out 6 ***
    OUTPORT6(READ(R[X]));R[X]++;break;
case 0x67: // *** out 7 ***
    OUTPORT7(READ(R[X]));R[X]++;break;
case 0x68: // *** inp 0 ***
    WRITE(R[X],INPORT0());break;
case 0x69: // *** inp 1 ***
    WRITE(R[X],INPORT1());break;
case 0x6a: // *** inp 2 ***
    WRITE(R[X],INPORT2());break;
case 0x6b: // *** inp 3 ***
    WRITE(R[X],INPORT3());break;
case 0x6c: // *** inp 4 ***
    WRITE(R[X],INPORT4());break;
case 0x6d: // *** inp 5 ***
    WRITE(R[X],INPORT5());break;
case 0x6e: // *** inp 6 ***
    WRITE(R[X],INPORT6());break;
case 0x6f: // *** inp 7 ***
    WRITE(R[X],INPORT7());break;
case 0x70: // *** ret ***
    RETURN();IE = 1;break;
case 0x71: // *** dis ***
    RETURN();IE = 0;break;
case 0x78: // *** sav ***
    WRITE(R[X],T);break;
case 0x80: // *** glo r0 ***
    D = R[0] & 0xFF;break;
case 0x81: // *** glo r1 ***
    D = R[1] & 0xFF;break;
case 0x82: // *** glo r2 ***
    D = R[2] & 0xFF;break;
case 0x83: // *** glo r3 ***
    D = R[3] & 0xFF;break;
case 0x84: // *** glo r4 ***
    D = R[4] & 0xFF;break;
case 0x85: // *** glo r5 ***
    D = R[5] & 0xFF;break;
case 0x86: // *** glo r6 ***
    D = R[6] & 0xFF;break;
case 0x87: // *** glo r7 ***
    D = R[7] & 0xFF;break;
case 0x88: // *** glo r8 ***
    D = R[8] & 0xFF;break;
case 0x89: // *** glo r9 ***
    D = R[9] & 0xFF;break;
case 0x8a: // *** glo ra ***
    D = R[10] & 0xFF;break;
case 0x8b: // *** glo rb ***
    D = R[11] & 0xFF;break;
case 0x8c: // *** glo rc ***
    D = R[12] & 0xFF;break;
case 0x8d: // *** glo rd ***
    D = R[13] & 0xFF;break;
case 0x8e: // *** glo re ***
    D = R[14] & 0xFF;break;
case 0x8f: // *** glo rf ***
    D = R[15] & 0xFF;break;
case 0x90: // *** ghi r0 ***
    D = (R[0] >> 8) & 0xFF;break;
case 0x91: // *** ghi r1 ***
    D = (R[1] >> 8) & 0xFF;break;
case 0x92: // *** ghi r2 ***
    D = (R[2] >> 8) & 0xFF;break;
case 0x93: // *** ghi r3 ***
    D = (R[3] >> 8) & 0xFF;break;
case 0x94: // *** ghi r4 ***
    D = (R[4] >> 8) & 0xFF;break;
case 0x95: // *** ghi r5 ***
    D = (R[5] >> 8) & 0xFF;break;
case 0x96: // *** ghi r6 ***
    D = (R[6] >> 8) & 0xFF;break;
case 0x97: // *** ghi r7 ***
    D = (R[7] >> 8) & 0xFF;break;
case 0x98: // *** ghi r8 ***
    D = (R[8] >> 8) & 0xFF;break;
case 0x99: // *** ghi r9 ***
    D = (R[9] >> 8) & 0xFF;break;
case 0x9a: // *** ghi ra ***
    D = (R[10] >> 8) & 0xFF;break;
case 0x9b: // *** ghi rb ***
    D = (R[11] >> 8) & 0xFF;break;
case 0x9c: // *** ghi rc ***
    D = (R[12] >> 8) & 0xFF;break;
case 0x9d: // *** ghi rd ***
    D = (R[13] >> 8) & 0xFF;break;
case 0x9e: // *** ghi re ***
    D = (R[14] >> 8) & 0xFF;break;
case 0x9f: // *** ghi rf ***
    D = (R[15] >> 8) & 0xFF;break;
case 0xa0: // *** plo r0 ***
    R[0] = (R[0] & 0xFF00) | D;break;
case 0xa1: // *** plo r1 ***
    R[1] = (R[1] & 0xFF00) | D;break;
case 0xa2: // *** plo r2 ***
    R[2] = (R[2] & 0xFF00) | D;break;
case 0xa3: // *** plo r3 ***
    R[3] = (R[3] & 0xFF00) | D;break;
case 0xa4: // *** plo r4 ***
    R[4] = (R[4] & 0xFF00) | D;break;
case 0xa5: // *** plo r5 ***
    R[5] = (R[5] & 0xFF00) | D;break;
case 0xa6: // *** plo r6 ***
    R[6] = (R[6] & 0xFF00) | D;break;
case 0xa7: // *** plo r7 ***
    R[7] = (R[7] & 0xFF00) | D;break;
case 0xa8: // *** plo r8 ***
    R[8] = (R[8] & 0xFF00) | D;break;
case 0xa9: // *** plo r9 ***
    R[9] = (R[9] & 0xFF00) | D;break;
case 0xaa: // *** plo ra ***
    R[10] = (R[10] & 0xFF00) | D;break;
case 0xab: // *** plo rb ***
    R[11] = (R[11] & 0xFF00) | D;break;
case 0xac: // *** plo rc ***
    R[12] = (R[12] & 0xFF00) | D;break;
case 0xad: // *** plo rd ***
    R[13] = (R[13] & 0xFF00) | D;break;
case 0xae: // *** plo re ***
    R[14] = (R[14] & 0xFF00) | D;break;
case 0xaf: // *** plo rf ***
    R[15] = (R[15] & 0xFF00) | D;break;
case 0xb0: // *** phi r0 ***
    R[0] = (R[0] & 0x00FF) | (((WORD16)D) << 8);break;
case 0xb1: // *** phi r1 ***
    R[1] = (R[1] & 0x00FF) | (((WORD16)D) << 8);break;
case 0xb2: // *** phi r2 ***
    R[2] = (R[2] & 0x00FF) | (((WORD16)D) << 8);break;
case 0xb3: // *** phi r3 ***
    R[3] = (R[3] & 0x00FF) | (((WORD16)D) << 8);break;
case 0xb4: // *** phi r4 ***
    R[4] = (R[4] & 0x00FF) | (((WORD16)D) << 8);break;
case 0xb5: // *** phi r5 ***
    R[5] = (R[5] & 0x00FF) | (((WORD16)D) << 8);break;
case 0xb6: // *** phi r6 ***
    R[6] = (R[6] & 0x00FF) | (((WORD16)D) << 8);break;
case 0xb7: // *** phi r7 ***
    R[7] = (R[7] & 0x00FF) | (((WORD16)D) << 8);break;
case 0xb8: // *** phi r8 ***
    R[8] = (R[8] & 0x00FF) | (((WORD16)D) << 8);break;
case 0xb9: // *** phi r9 ***
    R[9] = (R[9] & 0x00FF) | (((WORD16)D) << 8);break;
case 0xba: // *** phi ra ***
    R[10] = (R[10] & 0x00FF) | (((WORD16)D) << 8);break;
case 0xbb: // *** phi rb ***
    R[11] = (R[11] & 0x00FF) | (((WORD16)D) << 8);break;
case 0xbc: // *** phi rc ***
    R[12] = (R[12] & 0x00FF) | (((WORD16)D) << 8);break;
case 0xbd: // *** phi rd ***
    R[13] = (R[13] & 0x00FF) | (((WORD16)D) << 8);break;
case 0xbe: // *** phi re ***
    R[14] = (R[14] & 0x00FF) | (((WORD16)D) << 8);break;
case 0xbf: // *** phi rf ***
    R[15] = (R[15] & 0x00FF) | (((WORD16)D) << 8);break;
case 0xd0: // *** sep r0 ***
    P = 0;break;
case 0xd1: // *** sep r1 ***
    P = 1;break;
case 0xd2: // *** sep r2 ***
    P = 2;break;
case 0xd3: // *** sep r3 ***
    P = 3;break;
case 0xd4: // *** sep r4 ***
    P = 4;break;
case 0xd5: // *** sep r5 ***
    P = 5;break;
case 0xd6: // *** sep r6 ***
    P = 6;break;
case 0xd7: // *** sep r7 ***
    P = 7;break;
case 0xd8: // *** sep r8 ***
    P = 8;break;
case 0xd9: // *** sep r9 ***
    P = 9;break;
case 0xda: // *** sep ra ***
    P = 10;break;
case 0xdb: // *** sep rb ***
    P = 11;break;
case 0xdc: // *** sep rc ***
    P = 12;break;
case 0xdd: // *** sep rd ***
    P = 13;break;
case 0xde: // *** sep re ***
    P = 14;break;
case 0xdf: // *** sep rf ***
    P = 15;break;
case 0xe0: // *** sex r0 ***
    X = 0;break;
case 0xe1: // *** sex r1 ***
    X = 1;break;
case 0xe2: // *** sex r2 ***
    X = 2;break;
case 0xe3: // *** sex r3 ***
    X = 3;break;
case 0xe4: // *** sex r4 ***
    X = 4;break;
case 0xe5: // *** sex r5 ***
    X = 5;break;
case 0xe6: // *** sex r6 ***
    X = 6;break;
case 0xe7: // *** sex r7 ***
    X = 7;break;
case 0xe8: // *** sex r8 ***
    X = 8;break;
case 0xe9: // *** sex r9 ***
    X = 9;break;
case 0xea: // *** sex ra ***
    X = 10;break;
case 0xeb: // *** sex rb ***
    X = 11;break;
case 0xec: // *** sex rc ***
    X = 12;break;
case 0xed: // *** sex rd ***
    X = 13;break;
case 0xee: // *** sex re ***
    X = 14;break;
case 0xef: // *** sex rf ***
    X = 15;break;
case 0xf0: // *** ldx ***
    D = READ(R[X]);break;
case 0xf1: // *** or ***
    D |= READ(R[X]);break;
case 0xf2: // *** and ***
    D &= READ(R[X]);break;
case 0xf3: // *** xor ***
    D ^= READ(R[X]);break;
case 0xf4: // *** add ***
    ADD(READ(R[X]));break;
case 0xf5: // *** sd ***
    SUB(READ(R[X]),D);break;
case 0xf6: // *** shr ***
    DF = D & 1;D = (D >> 1) & 0x7F;break;
case 0xf7: // *** sm ***
    SUB(D,READ(R[X]));break;
case 0xf8: // *** ldi .1 ***
    D = FETCH();break;
case 0xf9: // *** ori .1 ***
    D |= FETCH();break;
case 0xfa: // *** ani .1 ***
    D &= FETCH();break;
case 0xfb: // *** xri .1 ***
    D ^= FETCH();break;
case 0xfc: // *** adi .1 ***
    ADD(FETCH());break;
case 0xfd: // *** sdi .1 ***
    SUB(FETCH(),D);break;
case 0xff: // *** smi .1 ***
    SUB(D,FETCH());break;
